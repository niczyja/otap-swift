
import Foundation
import Network

public class OTAPConnection {
    
    public typealias StateEmitter = AsyncThrowingStream<NWConnection.State, Error>
    public typealias PacketEmitter = AsyncThrowingStream<Packet, Error>
    
    public static let defaultPort: UInt16 = 3977
    public static let loginTimeout: UInt8 = 10

    public lazy var state: StateEmitter = {
        AsyncThrowingStream { continuation in
            self.receiveState(with: continuation)
        }
    }()
    public lazy var packets: PacketEmitter = {
        AsyncThrowingStream { continuation in
            self.receiveMessage(with: continuation)
        }
    }()
    
    private let endpoint: NWEndpoint
    private let connection: NWConnection
    
    public init(endpoint: NWEndpoint) {
        self.endpoint = endpoint
        self.connection = NWConnection(to: self.endpoint, using: .otap)
        
        OTAPConnection.logger.info("Created connection to '\(endpoint)'.")
    }
    
    deinit {
        self.close()
    }
    
    public func start() {
        OTAPConnection.logger.info("Connecting...")
        connection.start(queue: .main)
    }
    
    public func close() {
        connection.cancel()
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

    private func receiveState(with continuation: StateEmitter.Continuation) {
        self.connection.stateUpdateHandler = { newState in
            OTAPConnection.logger.info("Connection state changed to: \(newState)")
            
            switch newState {
            case .cancelled:
                continuation.finish()
            case .failed(let error):
                continuation.finish(throwing: error)
            default:
                continuation.yield(newState)
            }
        }
    }
    
    private func receiveMessage(with continuation: PacketEmitter.Continuation) {
        self.connection.receiveMessage { content, contentContext, isComplete, error in
            OTAPConnection.logger.info("Received message with: \(String(describing: content)), \(String(describing: contentContext)), \(isComplete), \(String(describing: error))")
            
            if let error {
                OTAPConnection.logger.error("Received message with error: \(error.localizedDescription).")
                continuation.finish(throwing: error)
                return
            }
            guard let contentContext else {
                continuation.finish(throwing: OTAPError.missingMessageContext)
                return
            }
            guard isComplete else {
                continuation.finish(throwing: OTAPError.messageNotComplete)
                return
            }
            guard !contentContext.isFinal else {
                continuation.finish()
                return
            }
            guard let message = contentContext.protocolMetadata(definition: OTAP.definition) as? NWProtocolFramer.Message else {
                continuation.finish(throwing: OTAPError.cannotCreateMessage)
                return
            }
            guard let response = message.packetHeader?.packetType.asResponse else {
                continuation.finish(throwing: OTAPError.invalidPacketType)
                return
            }
            
            do {
                let packet = try response.builder(content ?? Data())
                continuation.yield(packet)
            } catch {
                continuation.finish(throwing: error)
            }
            
            self.receiveMessage(with: continuation)
        }
    }
}

//MARK: -

internal extension OTAPConnection {
    
    static let logger: Logger = Logger(subsystem: "OTAP", category: "connection")
}
