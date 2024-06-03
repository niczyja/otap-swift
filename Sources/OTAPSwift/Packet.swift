
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
            throw OTAPError.exceededMTUSize
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

internal extension PacketType.Request {
    
    var builder: Builder<WritablePayload, Packet> {
        create { try Packet(type: self.type, payload: $0) }
    }
}

//MARK: -

internal extension PacketType.Response {
    
    var builder: Builder<Data, Packet> {
        switch self {
        case .full:
            fatalError()
        case .banned:
            fatalError()
        case .error:
            create { try Packet(type: self.type, payload: ServerError(data: $0)) }
        case .protocolVersion:
            create { try Packet(type: self.type, payload: ProtocolVersion(data: $0)) }
        case .welcome:
            create { try Packet(type: self.type, payload: Welcome(data: $0)) }
        case .newGame:
            fatalError()
        case .shutdown:
            create { _ in try Packet(type: self.type, payload: Empty()) }
        case .date:
            fatalError()
        case .clientJoin:
            fatalError()
        case .clientInfo:
            fatalError()
        case .clientUpdate:
            fatalError()
        case .clientQuit:
            fatalError()
        case .clientError:
            fatalError()
        case .companyNew:
            fatalError()
        case .companyInfo:
            fatalError()
        case .companyUpdate:
            fatalError()
        case .companyRemove:
            fatalError()
        case .companyEconomy:
            fatalError()
        case .companyStats:
            fatalError()
        case .chat:
            fatalError()
        case .rcon:
            fatalError()
        case .console:
            fatalError()
        case .cmdNames:
            fatalError()
        case .cmdLoggingOld:
            fatalError()
        case .gameScript:
            fatalError()
        case .rconEnd:
            fatalError()
        case .pong:
            create { try Packet(type: PacketType(self), payload: Pong(data: $0)) }
        case .cmdLogging:
            fatalError()
        }
    }
}
