
import Foundation
import Network

public class OTAPClient {
    
    public static let version: String = "0.1"
    public static let defaultPort: UInt16 = 3977
    public static let serverVersion: UInt8 = 3

    public typealias State = Result<NWConnection.State, Error>
    public typealias PacketStream = AsyncThrowingStream<Packet, Error>
    
    public let name: String
    @Published public private(set) var state: State
    
    //TODO: probably hide this stream and use it internally to read and republish specific responses
    public var packets: PacketStream {
        PacketStream { continuation in
            self.receive(with: continuation)
        }
    }
    
    private let endpoint: NWEndpoint
    private let connection: NWConnection
    
    public convenience init?(name: String, IPv4: String, port: UInt16 = OTAPClient.defaultPort) {
        guard let address = IPv4Address(IPv4) else { return nil }
        self.init(name: name, endpoint: .hostPort(host: .ipv4(address), port: .init(integerLiteral: port)))
    }
    
    public convenience init?(name: String, IPv6: String, port: UInt16 = OTAPClient.defaultPort) {
        guard let address = IPv6Address(IPv6) else { return nil }
        self.init(name: name, endpoint: .hostPort(host: .ipv6(address), port: .init(integerLiteral: port)))
    }
    
    public convenience init(name: String, hostName: String, port: UInt16 = OTAPClient.defaultPort) {
        self.init(name: name, endpoint: .hostPort(host: .init(hostName), port: .init(integerLiteral: port)))
    }
    
    public convenience init(name: String, host: NWEndpoint.Host, port: NWEndpoint.Port = .init(integerLiteral: OTAPClient.defaultPort)) {
        self.init(name: name, endpoint: .hostPort(host: host, port: port))
    }
    
    public init(name: String, endpoint: NWEndpoint) {
        self.name = name
        self.endpoint = endpoint
        self.connection = NWConnection(to: self.endpoint, using: .otap)
        self.state = .success(self.connection.state)
        
        OTAPClient.logger.info("Created '\(name)' client with '\(endpoint)'.")
    }
    
    deinit {
        connection.forceCancel()
        OTAPClient.logger.info("Goodbye '\(name)' client.")
    }
    
    public func start() {
        connection.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .failed(let error):
                self?.state = .failure(error)
                OTAPClient.logger.error("Client failed with error: \(error.localizedDescription)")
                self?.close()
            case .waiting(let error): //TODO: handle this somehow
                OTAPClient.logger.info("Connection is waiting due to: \(error.localizedDescription)")
            default:
                self?.state = .success(newState)
                OTAPClient.logger.info("Client state changed to: \(newState)")
            }
        }

        OTAPClient.logger.info("Connecting...")
        connection.start(queue: .main)
    }
    
    public func close() {
        connection.cancel()
        OTAPClient.logger.info("Connection closed.")
    }
}

//MARK: -

internal extension OTAPClient {
    
    func send(_ packet: Packet) {
        let message = NWProtocolFramer.Message(packetHeader: packet.header)
        let context = NWConnection.ContentContext(identifier: String(describing: packet), metadata: [message])
        
        self.connection.send(content: packet.payload.data, contentContext: context, isComplete: true, completion: .contentProcessed({ error in
            OTAPClient.logger.info("Packet content processed, error: \(String(describing: error))")
        }))
    }
    
    private func receive(with continuation: PacketStream.Continuation) {
        self.connection.receiveMessage { content, contentContext, isComplete, error in
            OTAPClient.logger.info("Received message with: \(String(describing: content)), \(String(describing: contentContext)), \(isComplete), \(String(describing: error))")
            
            if let error {
                OTAPClient.logger.error("Received message with error: \(error.localizedDescription).")
                continuation.yield(with: .failure(error))
                //TODO: not sure if should set state manually or connection will emit .failed(:) state
                return
            }
            guard let contentContext else {
                continuation.yield(with: .failure(OTAPError.missingMessageContext))
                return
            }
            guard isComplete else {
                continuation.yield(with: .failure(OTAPError.messageNotComplete))
                return
            }
            guard !contentContext.isFinal else {
                continuation.finish()
                self.close() //TODO: not sure if have to close manually?
                return
            }
            guard let message = contentContext.protocolMetadata(definition: OTAP.definition) as? NWProtocolFramer.Message else {
                continuation.yield(with: .failure(OTAPError.cannotCreateMessage)) //TODO: probably should just ignore and listen for another one?
                return
            }
            guard let response = message.packetHeader?.packetType.asResponse else {
                continuation.yield(with: .failure(OTAPError.invalidPacketType))
                return
            }
            
            do {
                let packet = try response.builder(content ?? Data())
                continuation.yield(packet)
            } catch {
                continuation.yield(with: .failure(error))
            }
            
            self.receive(with: continuation)
        }
    }
}

//MARK: -

internal extension OTAPClient {
    
    static let logger: Logger = Logger(subsystem: "OTAP", category: "client")
}
