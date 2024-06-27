
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
    private var authenticationTimer: Task<Void, Error>?

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

public extension OTAPClient {
    
    func connect() async throws {
        guard connection == nil else {
            throw OTAPError.alreadyConnected
        }
        
        connection = OTAPConnection(endpoint: endpoint)
        state = .connecting
        await connection!.start()
        
        for try await state in await connection!.state {
            if case .ready = state {
                self.state = .connected
                break
            }
        }
        
        authenticationTimer = Task.delayed(for: .seconds(OTAPConnection.authenticationTimeout), priority: .utility) {
            OTAPClient.logger.error("Authentication timeout, disconnecting...")
            await self.disconnect()
        }
        
        OTAPClient.logger.info("Client '\(name)' connected.")
    }
    
    func disconnect() async {
        state = .disconnected
        await connection?.close()
        connection = nil
        authenticationTimer = nil
        
        OTAPClient.logger.info("Client '\(name)' disconnected.")
    }
    
    func join(password: String) async throws {
        OTAPClient.logger.info("Authenticating...")
        
        authenticationTimer?.cancel()
        guard let connection, state == .connected else {
            throw OTAPError.notConnected
        }
        
        let packet = try PacketType.request(.join).packet(with: Join(name: name, password: password, version: Self.version))
        try await connection.send(packet)
        
        var protocolVersion: UInt8?
        var serverUpdates: GameServer.Updates?
        
        for try await packet in await connection.packets {
            if case .response(.protocolVersion) = packet.header.packetType {
                guard let payload = packet.payload as? ProtocolVersion, payload.version <= OTAP.version else {
                    await disconnect()
                    throw OTAPError.unsupportedProtocolVersion
                }
                
                protocolVersion = payload.version
                serverUpdates = payload.updates
                
                continue
            }
            
            if case .response(.welcome) = packet.header.packetType {
                guard let payload = packet.payload as? Welcome, let protocolVersion, let serverUpdates else {
                    await disconnect()
                    throw OTAPError.invalidPacketType
                }
                
                state = .authenticated
                OTAPClient.logger.info("Client '\(name)' authenticated.")
                
                self.gameServer = GameServer(protocolVersion: protocolVersion,
                                             info: payload.serverInfo,
                                             map: payload.serverMap,
                                             updates: serverUpdates)
                
                return
            }
            
            // I didn't observe this to happen. Theoretically server sends error packet, but also closes connection immediately.
            if case .response(.error) = packet.header.packetType {
                let error = OTAPError.serverError((packet.payload as! ServerError).error)
                OTAPClient.logger.error("Server returned an error: \(error)")
                await disconnect()
                throw error
            }
            
            break
        }
        
        // Because we don't get exact error type from server I think it's useful to assume here that it was an authentication error
        OTAPClient.logger.error("Wrong password.")
        await disconnect()
        throw OTAPError.serverError(.wrongPassword)
    }
    
    func quit() async throws {
        OTAPClient.logger.info("About to quit")
        
        guard let connection else {
            throw OTAPError.notConnected
        }
        guard state == .authenticated else {
            throw OTAPError.notAuthenticated
        }

        try await connection.send(try PacketType.request(.quit).packet())
        await disconnect()
    }
    
    func ping() async throws -> Bool {
        OTAPClient.logger.info("Ping")
        
        guard let connection else {
            throw OTAPError.notConnected
        }
        guard state == .authenticated else {
            throw OTAPError.notAuthenticated
        }
        
        let identifier = UInt32.random(in: 0...UInt32.max)
        let packet = try PacketType.request(.ping).packet(with: Ping(id: identifier))
        try await connection.send(packet)
        
        for try await packet in await connection.packets {
            if case .response(.pong) = packet.header.packetType {
                return (packet.payload as! Pong).id == identifier
            }
            
            if case .response(.error) = packet.header.packetType {
                let error = OTAPError.serverError((packet.payload as! ServerError).error)
                OTAPClient.logger.error("Server returned an error: \(error)")
                throw error
            }
            
            break
        }
        
        throw OTAPError.invalidPacketType
    }
}

//MARK: -

internal extension OTAPClient {
    
    static let logger: Logger = Logger(subsystem: "OTAP", category: "client")
}
