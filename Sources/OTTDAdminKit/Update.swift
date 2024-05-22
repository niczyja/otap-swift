
public enum Update: UInt16 {
    
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
}

public extension Update {
    
    struct Frequency: OptionSet {
        
        public var rawValue: UInt16
        
        static let poll         = Frequency(rawValue: 0x01) ///< The admin can poll this.
        static let daily        = Frequency(rawValue: 0x02) ///< The admin gets information about this on a daily basis.
        static let weekly       = Frequency(rawValue: 0x04) ///< The admin gets information about this on a weekly basis.
        static let monthly      = Frequency(rawValue: 0x08) ///< The admin gets information about this on a monthly basis.
        static let quarterly    = Frequency(rawValue: 0x10) ///< The admin gets information about this on a quarterly basis.
        static let anually      = Frequency(rawValue: 0x20) ///< The admin gets information about this on a yearly basis.
        static let automatic    = Frequency(rawValue: 0x40) ///< The admin gets information about this when it changes.
        
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
    }
}
