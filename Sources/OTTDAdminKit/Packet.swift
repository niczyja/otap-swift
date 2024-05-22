
import Foundation

public struct Packet {
    public let type: PacketType
    public let payload: Payload
    public var size: Int { PacketHeader.encodedLength + payload.size }
    
    init(type: PacketType, payload: Payload) throws {
        self.type = type
        self.payload = payload
        
        guard self.size <= PacketType.MTU else {
            throw OTAPError.exceededMTUSize
        }
    }
}

//MARK: -

public struct PacketHeader {
    public static let encodedLength: Int = PacketType.encodedSizeLength + PacketType.encodedByteLength
    
    public let packetType: PacketType
    public var packetSize: PacketType.PacketSize {
        get {
            data[0...1].toPacketSize()
        }
        set {
            data[0] = UInt8(newValue)
            data[1] = UInt8(newValue >> 8)
        }
    }
    public var payloadSize: Int {
        Int(packetSize) - Self.encodedLength
    }
    public private(set) var data: Data
    
    init(type: PacketType) {
        self.packetType = type
        self.data = Data([0, 0, type.rawValue])
    }
    
    init(buffer: Data) {
        self.data = buffer
        self.packetType = PacketType(rawValue: buffer[2])
        self.packetSize = buffer[0...1].toPacketSize()
    }
}

//MARK: -

internal extension PacketType.Request {
    
    var builder: Builder<WritablePayload, Packet> {
        create { try Packet(type: PacketType(rawValue: rawValue), payload: $0) }
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
