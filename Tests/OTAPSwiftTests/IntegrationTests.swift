
import XCTest
import Network
@testable import OTAPSwift

final class IntegrationTests: XCTestCase {
    
    /// To setup test server locally run OpenTTD executable directly from command line like this:
    ///  `./openttd -D`
    /// Following tests expect to be able to authenticate to the server using `secret` password
    
    static let clientName = "Test Client"
    static let IPAddress = "0.0.0.0"
    static let password = "secret"
    
    func testSuccessfulConnection() async throws {
        let client = OTAPClient(name: Self.clientName, IPv4: Self.IPAddress)!

        try await client.connect()
        XCTAssertEqual(client.state, .connected)
        
        await client.disconnect()
        XCTAssertEqual(client.state, .disconnected)
    }
    
    func testSuccessfulAuthentication() async throws {
        let client = OTAPClient(name: Self.clientName, IPv4: Self.IPAddress)!
        
        try await client.connect()
        XCTAssertEqual(client.state, .connected)

        try await client.join(password: Self.password)
        XCTAssertEqual(client.state, .authenticated)
        
        await client.disconnect()
        XCTAssertEqual(client.state, .disconnected)
    }
    
    func testFailedAuthentication() async throws {
        let client = OTAPClient(name: Self.clientName, IPv4: Self.IPAddress)!
        let expectataion = expectation(description: "Client throws an error indicating wrong password was used.")
        
        try await client.connect()
        XCTAssertEqual(client.state, .connected)

        do {
            try await client.join(password: "wrong password")
        } catch {
            if case OTAPClientError.serverError(.wrongPassword) = error {
                expectataion.fulfill()
            }
        }
        
        await fulfillment(of: [expectataion], timeout: TimeInterval(OTAPConnection.authenticationTimeout))
    }

//TODO: bring it back along with Listeners
//    func testAuthenticationTimeout() async throws {
//        let client = OTAPClient(name: Self.clientName, IPv4: Self.IPAddress)!
//
//        try await client.connect()
//        XCTAssertEqual(client.state, .connected)
//        
//        let _ = await XCTWaiter.fulfillment(of: [expectation(description: "Allow authentication timeout to pass.")],
//                                                 timeout: TimeInterval(OTAPConnection.authenticationTimeout))
//        
//        XCTAssertEqual(client.state, .disconnected)
//    }
    
    func testPublishers() async throws {
        let expectedStateSequence: [OTAPClient.State] = [.disconnected, .connecting, .connected, .authenticated, .disconnected]
        var actualStateSequence: [OTAPClient.State] = []
        var gameServer: GameServer? = nil
        
        let client = OTAPClient(name: Self.clientName, IPv4: Self.IPAddress)!
        let sub1 = client.$state.sink { actualStateSequence.append($0) }
        let sub2 = client.$gameServer.sink { gameServer = $0 }
        
        try await client.connect()
        try await client.join(password: Self.password)
        try await client.quit()
        
        XCTAssertEqual(expectedStateSequence, actualStateSequence)
        XCTAssertNotNil(client.gameServer)
        XCTAssertNotNil(gameServer)
        
        sub1.cancel()
        sub2.cancel()
    }
    
    func testPingPong() async throws {
        let client = OTAPClient(name: Self.clientName, IPv4: Self.IPAddress)!

        try await client.connect()
        XCTAssertEqual(client.state, .connected)

        try await client.join(password: Self.password)
        XCTAssertEqual(client.state, .authenticated)
        
        let pong = try await client.ping()
        XCTAssertTrue(pong)
        
        await client.disconnect()
        XCTAssertEqual(client.state, .disconnected)
    }
    
    func testQuit() async throws {
        let client = OTAPClient(name: Self.clientName, IPv4: Self.IPAddress)!

        try await client.connect()
        XCTAssertEqual(client.state, .connected)

        try await client.join(password: Self.password)
        XCTAssertEqual(client.state, .authenticated)
        
        try await client.quit()
        XCTAssertEqual(client.state, .disconnected)
    }
}
