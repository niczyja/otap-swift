import XCTest
@testable import OTAPSwift

final class OTAPSwiftTests: XCTestCase {
    
    func testConnection() async throws {
        let clientName = "Panel Prezesa"
        let IPAddress = "0.0.0.0"
        let secret = "test"
        
        let client = OTAPClient(name: clientName, IPv4: IPAddress)!

        try await client.connect()
        let info = try await client.join(password: secret)
        await client.disconnect()
        
        try await Task.sleep(for: .seconds(2))

        print(info)
    }
}
