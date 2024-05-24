
public enum PacketType {
    
    case request(Request),
         response(Response),
         invalid
    
    public enum Request: PacketByte {
        
        case join,              ///< The admin announces and authenticates itself to the server.
             quit,              ///< The admin tells the server that it is quitting.
             updateFrequency,   ///< The admin tells the server the update frequency of a particular piece of information.
             poll,              ///< The admin explicitly polls for a piece of information.
             chat,              ///< The admin sends a chat message to be distributed.
             rcon,              ///< The admin sends a remote console command.
             gameScript,        ///< The admin sends a JSON string for the GameScript.
             ping,              ///< The admin sends a ping to the server, expecting a ping-reply (PONG) packet.
             externalChat       ///< The admin sends a chat message from external source.
    }
    
    public enum Response: PacketByte {
        
        case full = 100,        ///< The server tells the admin it cannot accept the admin.
             banned,            ///< The server tells the admin it is banned.
             error,             ///< The server tells the admin an error has occurred.
             protocolVersion,   ///< The server tells the admin its protocol version.
             welcome,           ///< The server welcomes the admin to a game.
             newGame,           ///< The server tells the admin its going to start a new game.
             shutdown,          ///< The server tells the admin its shutting down.
             date,              ///< The server tells the admin what the current game date is.
             clientJoin,        ///< The server tells the admin that a client has joined.
             clientInfo,        ///< The server gives the admin information about a client.
             clientUpdate,      ///< The server gives the admin an information update on a client.
             clientQuit,        ///< The server tells the admin that a client quit.
             clientError,       ///< The server tells the admin that a client caused an error.
             companyNew,        ///< The server tells the admin that a new company has started.
             companyInfo,       ///< The server gives the admin information about a company.
             companyUpdate,     ///< The server gives the admin an information update on a company.
             companyRemove,     ///< The server tells the admin that a company was removed.
             companyEconomy,    ///< The server gives the admin some economy related company information.
             companyStats,      ///< The server gives the admin some statistics about a company.
             chat,              ///< The server received a chat message and relays it.
             rcon,              ///< The server's reply to a remove console command.
             console,           ///< The server gives the admin the data that got printed to its console.
             cmdNames,          ///< The server sends out the names of the DoCommands to the admins.
             cmdLoggingOld,     ///< Used to be the type ID of \c ADMIN_PACKET_SERVER_CMD_LOGGING in \c NETWORK_GAME_ADMIN_VERSION 1.
             gameScript,        ///< The server gives the admin information from the GameScript in JSON.
             rconEnd,           ///< The server indicates that the remote console command has completed.
             pong,              ///< The server replies to a ping request from the admin.
             cmdLogging         ///< The server gives the admin copies of incoming command packets.
    }
}

//MARK: -

public extension PacketType {
    
    init(_ request: Request) {
        self.init(rawValue: request.rawValue)
    }
    
    var asRequest: Request? {
        Request(rawValue: rawValue)
    }

    init(_ response: Response) {
        self.init(rawValue: response.rawValue)
    }
    
    var asResponse: Response? {
        Response(rawValue: rawValue)
    }
}

public extension PacketType.Request {
    
    var type: PacketType {
        PacketType(self)
    }
}

public extension PacketType.Response {
    
    var type: PacketType {
        PacketType(self)
    }
}

//MARK: -

public extension PacketType {
    
    static let MTU: Int = 1460
    
    typealias PacketByte = UInt8
    typealias PacketSize = UInt16

    static let encodedByteLength: Int = MemoryLayout<PacketByte>.size
    static let encodedSizeLength: Int = MemoryLayout<PacketSize>.size
}

internal extension PacketType {
    
    static let requestPacketRawValues: ClosedRange<PacketByte> = 0...8
    static let responsePacketRawValues: ClosedRange<PacketByte> = 100...127
    static let invalidPacketRawValue: PacketByte = 0xFF
}

//MARK: -

extension PacketType: RawRepresentable {
    
    public typealias RawValue = PacketByte
    
    public var rawValue: PacketByte {
        switch self {
        case .request(let type):
            return type.rawValue
        case .response(let type):
            return type.rawValue
        case .invalid:
            return Self.invalidPacketRawValue
        }
    }
    
    public init(rawValue: PacketByte) {
        switch rawValue {
        case Self.requestPacketRawValues:
            self = .request(PacketType.Request(rawValue: rawValue)!)
        case Self.responsePacketRawValues:
            self = .response(PacketType.Response(rawValue: rawValue)!)
        default:
            self = .invalid
        }
    }
}
