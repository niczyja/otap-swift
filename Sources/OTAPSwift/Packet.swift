
import Foundation

public struct Packet {
    public let payload: Payload
    public private(set) var header: Header
    public var size: Int { Header.encodedLength + payload.size }
    
    init(type: PacketType, payload: Payload) throws {
        self.payload = payload
        self.header = Header(type: type)
        self.header.packetSize = PacketType.PacketSize(self.size)
        
        guard self.size <= PacketType.MTU else {
            throw OTAPPacketError.exceededMTUSize
        }
    }
}

//MARK: -

extension Packet {
    
    public struct Header {
        public static let encodedLength: Int = PacketType.encodedSizeLength + PacketType.encodedByteLength
        
        public private(set) var data: Data
        
        public var packetType: PacketType {
            get { PacketType(rawValue: data[2]) }
            set { data[2] = newValue.rawValue }
        }
        
        public var packetSize: PacketType.PacketSize {
            get { data[0...1].toPacketSize() }
            set {
                data[0] = UInt8(newValue)
                data[1] = UInt8(newValue >> 8)
            }
        }
        
        public var payloadSize: Int { Int(packetSize) - Self.encodedLength }
        
        init(type: PacketType, size: PacketType.PacketSize? = nil) {
            self.data = Data(count: Self.encodedLength)
            self.packetType = type
            self.packetSize = size ?? 0
        }
        
        init(buffer: Data) {
            self.data = buffer
        }
    }
}

//MARK: -

internal extension PacketType {
    
    //MARK: Creating request packets
    
    func packet(with payload: WritablePayload) throws -> Packet {
        switch self {
        case .request(.join),
                .request(.updateFrequency),
                .request(.poll),
                .request(.chat),
                .request(.rcon),
                .request(.gameScript),
                .request(.ping),
                .request(.externalChat):
            return try Packet(type: self, payload: payload)
        default:
            throw OTAPPacketError.cannotCreatePacket
        }
    }
    
    func packet() throws -> Packet {
        switch self {
        case .request(.quit):
            return try Packet(type: self, payload: Empty())
        default:
            throw OTAPPacketError.cannotCreatePacket
        }
    }
    
    //MARK: Creating response packets
    
    func packet(with data: Data?) throws -> Packet {
        guard let data else {
            switch self {
            case .response(.full),
                    .response(.banned),
                    .response(.newGame),
                    .response(.shutdown):
                return try Packet(type: self, payload: Empty())
            default:
                throw OTAPPacketError.cannotCreatePacket
            }
        }
        
        switch self {
        case .response(.error):
            return try Packet(type: self, payload: ServerError(data: data))
        case .response(.protocolVersion):
            return try Packet(type: self, payload: ProtocolVersion(data: data))
        case .response(.welcome):
            return try Packet(type: self, payload: Welcome(data: data))
        case .response(.date):
            return try Packet(type: self, payload: DateResponse(data: data))
        case .response(.clientJoin):
            fatalError("Not implemented")
        case .response(.clientInfo):
            fatalError("Not implemented")
        case .response(.clientUpdate):
            fatalError("Not implemented")
        case .response(.clientQuit):
            fatalError("Not implemented")
        case .response(.clientError):
            fatalError("Not implemented")
        case .response(.companyNew):
            fatalError("Not implemented")
        case .response(.companyInfo):
            fatalError("Not implemented")
        case .response(.companyUpdate):
            fatalError("Not implemented")
        case .response(.companyRemove):
            fatalError("Not implemented")
        case .response(.companyEconomy):
            fatalError("Not implemented")
        case .response(.companyStats):
            fatalError("Not implemented")
        case .response(.chat):
            fatalError("Not implemented")
        case .response(.rcon):
            fatalError("Not implemented")
        case .response(.console):
            fatalError("Not implemented")
        case .response(.cmdNames):
            fatalError("Not implemented")
        case .response(.cmdLoggingOld):
            fatalError("Not implemented")
        case .response(.gameScript):
            fatalError("Not implemented")
        case .response(.rconEnd):
            fatalError("Not implemented")
        case .response(.pong):
            return try Packet(type: self, payload: Pong(data: data))
        case .response(.cmdLogging):
            fatalError("Not implemented")
        default:
            throw OTAPPacketError.cannotCreatePacket
        }
    }
}
