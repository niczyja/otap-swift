
import Foundation
import Network
import Combine

public class OTAPClient {
    
    public static let defaultPort: UInt16 = 3977
    public static let serverVersion: UInt8 = 3

    public let name: String
    
    @Published public private(set) var state: NWConnection.State
    
    private let endpoint: NWEndpoint
    private let connection: NWConnection
    private var subscription: AnyCancellable?
    
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
        self.state = self.connection.state
        
        self.subscription = self.$state.sink { state in
            switch state {
            case .ready:
                print("\(self.connection) established 🎉")
                self.receiveMessage()
            case .failed(let error):
                print("\(self.connection) failed 💥 with error: \(error.localizedDescription)")
                self.connection.cancel()
            default:
                print("\(self.connection) state changed to: \(state)")
            }
        }
    }
    
    deinit {
        connection.forceCancel()
        subscription?.cancel()
    }
    
    public func start() {
        connection.stateUpdateHandler = { [weak self] newState in
            self?.state = newState
        }
        connection.start(queue: .main)
    }
    
    public func close() {
        connection.cancel()
    }
    
    private func receiveMessage() {
        connection.receiveMessage { content, contentContext, isComplete, error in
            guard error == nil else {
                print("receiving message failed with error: \(error!.localizedDescription)")
                return
            }
            
            print("received a message with: \(String(describing: content)), \(String(describing: contentContext)), \(isComplete)")
            
            guard let message = contentContext?.protocolMetadata(definition: OTAP.definition) as? NWProtocolFramer.Message,
                  let response = message.packetHeader?.packetType.asResponse else {
                print("cannot parse received message")
                return
            }

            do {
                let packet = try response.builder(content ?? Data())
                print("sucesfully received a packet: \(packet)")
            } catch (let error) {
                print("failed to parse response packet with error: \(error.localizedDescription)")
            }
            
            self.receiveMessage()
        }
    }
}

//MARK: -

internal extension OTAPClient {
    
    static let logger: Logger = Logger(subsystem: "OTAP", category: "client")
}
