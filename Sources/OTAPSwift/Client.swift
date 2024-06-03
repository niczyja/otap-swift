
import Foundation
import Network

public class OTAPClient {
    
    public static let version: String = "0.1"
    public static let serverVersion: UInt8 = 3

    public let name: String
    
    private let connection: OTAPConnection

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
        self.connection = OTAPConnection(endpoint: endpoint)
    }

}

public extension OTAPClient {
    
    func join(password: String) async throws {
        let packet = try PacketType.Request.join.builder(try Join(name: self.name, password: password, version: OTAPClient.version))
        try await self.connection.send(packet)
    }
}
