
import Foundation
import Network

public actor OTAPConnection {
    
    public static let defaultPort: UInt16 = 3977
    public static let authenticationTimeout: UInt8 = 10

    public var state: AsyncThrowingStream<NWConnection.State, Error> {
        stateEmitter.stream
    }
    
    public var packets: AsyncThrowingStream<Packet, Error> {
        packetsEmitter.stream
    }
    
    private let endpoint: NWEndpoint
    private let connection: NWConnection
    private let stateEmitter = ThrowingEmitter<NWConnection.State, Error>()
    private let packetsEmitter = ThrowingEmitter<Packet, Error>()
    
    public init(endpoint: NWEndpoint) {
        self.endpoint = endpoint
        self.connection = NWConnection(to: self.endpoint, using: .otap)

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
                self.stateEmitter.finish()
            case .failed(let error):
                self.stateEmitter.finish(throwing: error)
            case .waiting(let reason):
                OTAPConnection.logger.warn("Connection is waiting with reason: \(reason.localizedDescription). Restarting...")
                self.stateEmitter.emit(newState)
                self.connection.restart()
            default:
                self.stateEmitter.emit(newState)
            }
        }
        
        OTAPConnection.logger.info("Begin listening for state changes.")
    }
    
    private func receiveNextMessage() {
        self.connection.receiveMessage { content, context, isComplete, error in
            OTAPConnection.logger.info("Received message with: \(String(describing: content)), \(String(describing: context)), \(isComplete), \(String(describing: error))")
            
            if let error {
                OTAPConnection.logger.error("Received message with error: \(error.localizedDescription).")
                self.packetsEmitter.finish(throwing: error)
                return
            }
            guard let context else {
                self.packetsEmitter.finish(throwing: OTAPError.missingMessageContext)
                return
            }
            guard isComplete else {
                self.packetsEmitter.finish(throwing: OTAPError.messageNotComplete)
                return
            }
            guard !context.isFinal else {
                self.packetsEmitter.finish()
                return
            }
            guard let message = context.protocolMetadata(definition: OTAP.definition) as? NWProtocolFramer.Message else {
                self.packetsEmitter.finish(throwing: OTAPError.cannotCreateMessage)
                return
            }
            guard let response = message.packetHeader?.packetType.asResponse else {
                self.packetsEmitter.finish(throwing: OTAPError.invalidPacketType)
                return
            }
            
            do {
                let packet = try response.builder(content ?? Data())
                self.packetsEmitter.emit(packet)
                Task {
                    await self.receiveNextMessage()
                }
            } catch {
                self.packetsEmitter.finish(throwing: error)
            }
        }

        OTAPConnection.logger.info("Ready to receive next message.")
    }
}

//MARK: -

internal extension OTAPConnection {
    
    static let logger: Logger = Logger(subsystem: "OTAP", category: "connection")
}
