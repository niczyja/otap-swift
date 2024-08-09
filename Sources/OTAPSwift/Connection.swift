
import Foundation
import Network

public actor OTAPConnection {
    
    public static let defaultPort: UInt16 = 3977
    public static let authenticationTimeout: UInt8 = 10
    public static let retryTimeout: Duration = .seconds(3)

    public typealias StateStream = AsyncThrowingStream<NWConnection.State, Error>
    public typealias PacketStream = AsyncThrowingStream<Packet, Error>

    public let stateSequence: AsyncSharedSequence<StateStream>
    public let packetSequence: AsyncSharedSequence<PacketStream>
    
    private let endpoint: NWEndpoint
    private let connection: NWConnection
    private let stateStream: (stream: StateStream, continuation: StateStream.Continuation)
    private let packetStream: (stream: PacketStream, continuation: PacketStream.Continuation)
    
    public init(endpoint: NWEndpoint) {
        self.endpoint = endpoint
        self.connection = NWConnection(to: self.endpoint, using: .otap)
        self.stateStream = StateStream.makeStream()
        self.packetStream = PacketStream.makeStream()
        self.stateSequence = AsyncSharedSequence(self.stateStream.stream)
        self.packetSequence = AsyncSharedSequence(self.packetStream.stream)
        
        OTAPConnection.logger.info("Created connection to '\(endpoint)'.")
    }
    
    public func start() {
        setupStateListener()
        receiveNextMessage()
        connection.start(queue: .main)
        
        OTAPConnection.logger.info("Connecting...")
    }
    
    public func close() {
        connection.cancel()
        connection.stateUpdateHandler = nil
        stateStream.continuation.finish()
        packetStream.continuation.finish()
        
        OTAPConnection.logger.info("Connection closed.")
    }
    
    public func send(_ packet: Packet) async throws {
        let message = NWProtocolFramer.Message(packetHeader: packet.header)
        let context = NWConnection.ContentContext(identifier: String(describing: packet), metadata: [message])
        
        return try await withCheckedThrowingContinuation { continuation in
            self.connection.send(content: packet.payload.data, contentContext: context, isComplete: true, completion: .contentProcessed({ error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }))
        }
    }
}

//MARK: -

extension OTAPConnection {

    private func setupStateListener() {
        self.connection.stateUpdateHandler = { newState in
            OTAPConnection.logger.info("Connection state changed to: \(newState)")
            
            switch newState {
            case .cancelled:
                self.stateStream.continuation.finish()
            case .failed(let error):
                self.stateStream.continuation.finish(throwing: error)
            case .waiting(let reason):
                OTAPConnection.logger.warn("Connection is waiting with reason: \(reason.localizedDescription). Restarting...")
                self.stateStream.continuation.yield(newState)
                Task {
                    try? await Task.sleep(for: Self.retryTimeout)
                    if case .waiting(_) = self.connection.state {
                        self.connection.restart()
                    }
                }
            default:
                self.stateStream.continuation.yield(newState)
            }
        }
        
        OTAPConnection.logger.info("Begin listening for state changes.")
    }
    
    private func receiveNextMessage() {
        self.connection.receiveMessage { content, context, isComplete, error in
            OTAPConnection.logger.info("Received message with: \(String(describing: content)), \(String(describing: context)), \(isComplete), \(String(describing: error))")
            
            if let error {
                self.packetStream.continuation.finish(throwing: error)
                return
            }
            guard let context else {
                self.packetStream.continuation.finish(throwing: OTAPConnectionError.missingMessageContext)
                return
            }
            guard isComplete else {
                self.packetStream.continuation.finish(throwing: OTAPConnectionError.messageNotComplete)
                return
            }
            guard !context.isFinal else {
                self.packetStream.continuation.finish()
                return
            }
            guard let message = context.protocolMetadata(definition: OTAP.definition) as? NWProtocolFramer.Message else {
                self.packetStream.continuation.finish(throwing: OTAPConnectionError.cannotCreateMessage)
                return
            }
            guard let response = message.packetHeader?.packetType else {
                self.packetStream.continuation.finish(throwing: OTAPConnectionError.missingPacketHeader)
                return
            }
            
            do {
                let packet = try response.packet(with: content)
                self.packetStream.continuation.yield(packet)
                Task {
                    await self.receiveNextMessage()
                }
            } catch {
                self.packetStream.continuation.finish(throwing: error)
            }
        }

        OTAPConnection.logger.info("Ready to receive next message.")
    }
}

//MARK: -

internal extension OTAPConnection {
    
    static let logger: Logger = Logger(subsystem: "OTAP", category: "connection")
}
