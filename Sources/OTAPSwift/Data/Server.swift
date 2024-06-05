
// https://github.com/OpenTTD/OpenTTD/blob/d9cadb49b069fc27f4778665bd1db8f0c31037bb/src/network/network_admin.cpp#L170

public struct Server {
    public let name: String                 ///< name of the server
    public let revision: String             ///< ottd revision run by this server
    public let isDedicated: Bool            ///< is it a dedicated server
    public let startingYear: UInt32         ///< current game starting year
    public let map: Map

    public struct Map {
        public let name: String             ///< name of the map, apparently not used anymore
        public let seed: UInt32             ///< seed used to generate server map
        public let landscape: UInt8         ///< type of the landscape of the map
        public let sizeX: UInt16            ///< map size x
        public let sizeY: UInt16            ///< map size y
    }
}
