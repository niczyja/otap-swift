
import Foundation
import Network

public class OTAPClient {
    
    public static let version: String = "0.1"
    
    public enum State {
        case disconnected, connecting, connected, authenticated
    }

    public let name: String
    public let endpoint: NWEndpoint
    
    @Published public private(set) var state: State = .disconnected
    @Published public private(set) var gameServer: GameServer?
    
    private var connection: OTAPConnection?

    public convenience init?(name: String, IPv4: String, port: UInt16 = OTAPConnection.defaultPort) {
        guard let address = IPv4Address(IPv4) else { return nil }
        self.init(name: name, endpoint: .hostPort(host: .ipv4(address), port: .init(integerLiteral: port)))
    }
    
    public convenience init?(name: String, IPv6: String, port: UInt16 = OTAPConnection.defaultPort) {
        guard let address = IPv6Address(IPv6) else { return nil }
        self.init(name: name, endpoint: .hostPort(host: .ipv6(address), port: .init(integerLiteral: port)))
    }
    
    public convenience init(name: String, host: String, port: UInt16 = OTAPConnection.defaultPort) {
        self.init(name: name, endpoint: .hostPort(host: .init(host), port: .init(integerLiteral: port)))
    }
    
    public convenience init(name: String, host: NWEndpoint.Host, port: NWEndpoint.Port = .init(integerLiteral: OTAPConnection.defaultPort)) {
        self.init(name: name, endpoint: .hostPort(host: host, port: port))
    }
    
    public init(name: String, endpoint: NWEndpoint) {
        self.name = name
        self.endpoint = endpoint
        
        OTAPClient.logger.info("New client with name: '\(name)'.")
    }
}

//MARK: -

extension OTAPClient {
    
    func connect() async throws {
        guard connection == nil, state == .disconnected else { return }
        
        connection = OTAPConnection(endpoint: endpoint)
        let connectionState = connection!.stateSequence.shared()
        state = .connecting
        await connection!.start()

        //TODO: refactor. this is asking for hang with no way to cancel
        guard try await connectionState.contains(.ready) else { throw OTAPClientError.notConnected }
        
        self.state = .connected
        
        OTAPClient.logger.info("Client '\(name)' connected.")
    }
    
    func disconnect() async {
        state = .disconnected
        await connection?.close()
        connection = nil
        
        OTAPClient.logger.info("Client '\(name)' disconnected.")
    }
}

//MARK: -

public extension OTAPClient {
    
    func join(password: String) async throws {
        guard state != .authenticated else { return }
        
        try await connect()
        guard let connection, state == .connected else { throw OTAPClientError.notConnected }
        
        let packet = try PacketType.request(.join).packet(with: Join(name: name, password: password, version: Self.version))
        let expected = connection.packetSequence.shared().filter { [.response(.protocolVersion), .response(.welcome)].contains($0.header.packetType) }
        try await connection.send(packet)
        
        var protocolVersion: UInt8?
        var serverUpdates: GameServer.Updates?
        
        for try await response in expected {
            if case .response(.protocolVersion) = response.header.packetType {
                guard let payload = response.payload as? ProtocolVersion, payload.version <= OTAP.version else {
                    await disconnect()
                    throw OTAPClientError.unsupportedProtocolVersion
                }
                
                protocolVersion = payload.version
                serverUpdates = payload.updates
                continue
            }
            if case .response(.welcome) = response.header.packetType {
                guard let payload = response.payload as? Welcome, let protocolVersion, let serverUpdates else {
                    await disconnect()
                    throw OTAPClientError.unexpectedServerResponse
                }
                
                state = .authenticated
                OTAPClient.logger.info("Client '\(name)' authenticated.")
                
                self.gameServer = GameServer(protocolVersion: protocolVersion,
                                             info: payload.serverInfo,
                                             map: payload.serverMap,
                                             updates: serverUpdates)
                return
            }
            break
        }
        
        OTAPClient.logger.error("Wrong password.")
        await disconnect()
        throw OTAPClientError.serverError(.wrongPassword)
    }
    
    func quit() async throws {
        guard let connection, state != .disconnected else { return }

        try await connection.send(try PacketType.request(.quit).packet())
        await disconnect()

        OTAPClient.logger.info("Client '\(name)' disconnected.")
    }
}

// MARK: -

public extension OTAPClient {
    
    func ping() async throws -> Bool {
        guard let connection, state == .authenticated else { throw OTAPClientError.notAuthenticated }
        
        let identifier = UInt32.random(in: 0...UInt32.max)
        let packet = try PacketType.request(.ping).packet(with: Ping(id: identifier))
        let expected = connection.packetSequence.shared().filter { $0.header.packetType == .response(.pong) }
        try await connection.send(packet)

        for try await response in expected {
            if case .response(.pong) = response.header.packetType {
                return (response.payload as! Pong).id == identifier
            }
            break
        }
        return false
        
    }
}

//MARK: -

internal extension OTAPClient {
    
    static let logger: Logger = Logger(subsystem: "OTAP", category: "client")
}
