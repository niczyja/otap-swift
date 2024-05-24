
import Foundation

public extension OTAPClient {
    
    func join(password: String) throws {
        let packet = try PacketType.Request.join.builder(try Join(name: self.name, password: password, version: OTAPClient.version))
        self.send(packet)
    }
    
    
}
