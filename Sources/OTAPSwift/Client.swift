
import Foundation
import Network

public class OTAPClient {
    
    public static let version: String = "0.1"
    
    public enum State {
        case disconnected, connecting, connected, authenticated
    }

    public let name: String
    public let endpoint: NWEndpoint
    public private(set) var state: State = .disconnected
    
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
        await connection!.start()
        state = .connecting
        
        for try await state in await connection!.state {
            if case .ready = state {
                self.state = .connected
                break
            }
        }
        
        authenticationTimer = Task.delayed(for: .seconds(OTAPConnection.authenticationTimeout), priority: .utility) {
            OTAPClient.logger.warn("Authentication timeout, disconnecting...")
            await self.disconnect()
        }
        
        OTAPClient.logger.info("Client '\(name)' connected.")
    }
    
    func disconnect() async {
        authenticationTimer?.cancel()
        await connection?.close()
        state = .disconnected
        connection = nil
        
        OTAPClient.logger.info("Client '\(name)' disconnected.")
    }
    
}

//MARK: -

public extension OTAPClient {
    
    @discardableResult
    func join(password: String) async throws -> Server {
        authenticationTimer?.cancel()
        guard let connection, state == .connected else {
            throw OTAPError.notConnected
        }
        
        let packet = try PacketType.Request.join.builder(try Join(name: self.name, password: password, version: OTAPClient.version))
        try await connection.send(packet)
        
        for try await packet in await connection.packets {
            if case .response(.protocolVersion) = packet.header.packetType {
                guard let payload = packet.payload as? ProtocolVersion, payload.version <= OTAP.version else {
                    await disconnect()
                    throw OTAPError.unsupportedProtocolVersion
                }
                continue
            }
            
            if case .response(.welcome) = packet.header.packetType {
                guard let payload = packet.payload as? Welcome else {
                    fatalError("Packet payload does not match its type. This should not happen.")
                }
                OTAPClient.logger.info("Client '\(name)' authenticated.")
                state = .authenticated
                return payload.server
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
