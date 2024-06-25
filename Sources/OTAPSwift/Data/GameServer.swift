
import Foundation

public struct GameServer {
    public let protocolVersion: UInt8       ///< version of admin protocol supported by server
    public let info: Info                   ///< basic info about game server
    public let map: Map                     ///< map information
    public let updates: Updates             ///< frequencies for each type of update
}

//MARK: -

public extension GameServer {
    
    struct Info {
        public let name: String             ///< name of the server
        public let revision: String         ///< ottd revision run by this server
        public let isDedicated: Bool        ///< is it a dedicated server
        public let startDate: GameDate      ///< current game starting year
    }
}

//MARK: -

public extension GameServer {
    
    struct Map {
        public let name: String             ///< name of the map, apparently not used anymore
        public let seed: UInt32             ///< seed used to generate server map
        public let landscape: Landscape     ///< type of the landscape of the map
        public let sizeX: UInt16            ///< map size x
        public let sizeY: UInt16            ///< map size y
        
        public enum Landscape: UInt8 {
            case temperate, arctic, tropic, toyland
        }
    }
}

//MARK: -

public extension GameServer {
    
    typealias Updates = [Update: Update.Frequency]

    enum Update: UInt16 {
        case date,              ///< Updates about the date of the game. Default frequency: poll | daily | weekly | monthly | quarterly | anually
             clientInfo,        ///< Updates about the information of clients. Default frequency: poll | automatic
             companyInfo,       ///< Updates about the generic information of companies. Default frequency: poll | automatic
             companyEconomy,    ///< Updates about the economy of companies. Default frequency: poll | weekly | monthly | quarterly | anually
             companyStats,      ///< Updates about the statistics of companies. Default frequency: poll | weekly | monthly | quarterly | anually
             chat,              ///< The admin would like to have chat messages. Default frequency: automatic
             console,           ///< The admin would like to have console messages. Default frequency: automatic
             cmdNames,          ///< The admin would like a list of all DoCommand names. Default frequency: poll
             cmdLogging,        ///< The admin would like to have DoCommand information. Default frequency: automatic
             gameScript         ///< The admin would like to have gamescript messages. Default frequency: automatic

        public struct Frequency: OptionSet {
            public var rawValue: UInt16
            
            public static let poll         = Frequency(rawValue: 0x01) ///< The admin can poll this.
            public static let daily        = Frequency(rawValue: 0x02) ///< The admin gets information about this on a daily basis.
            public static let weekly       = Frequency(rawValue: 0x04) ///< The admin gets information about this on a weekly basis.
            public static let monthly      = Frequency(rawValue: 0x08) ///< The admin gets information about this on a monthly basis.
            public static let quarterly    = Frequency(rawValue: 0x10) ///< The admin gets information about this on a quarterly basis.
            public static let anually      = Frequency(rawValue: 0x20) ///< The admin gets information about this on a yearly basis.
            public static let automatic    = Frequency(rawValue: 0x40) ///< The admin gets information about this when it changes.
            
            public init(rawValue: UInt16) {
                self.rawValue = rawValue
            }
        }
    }
}
