
import Foundation
import Network

class OTAP: NWProtocolFramerImplementation {
    
    static let definition = NWProtocolFramer.Definition(implementation: OTAP.self)
    static var label: String = "OpenTTD Admin Protocol"
    
    required init(framer: NWProtocolFramer.Instance) { }
    
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { .ready }
    func wakeup(framer: NWProtocolFramer.Instance) { }
    func stop(framer: NWProtocolFramer.Instance) -> Bool { true }
    func cleanup(framer: NWProtocolFramer.Instance) { }
    
    func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        do {
            guard let header = message.packetHeader else {
                throw OTAPError.missingPacketHeader
            }
            guard case .request(_) = header.packetType else {
                throw OTAPError.invalidPacketType
            }
            guard header.payloadSize == messageLength else {
                throw OTAPError.unexpectedPayloadLength
            }
            
            framer.writeOutput(data: header.data)
            try framer.writeOutputNoCopy(length: messageLength)
        } catch (let error) {
            fatalError(error.localizedDescription)
        }
    }
    
    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            var header: PacketHeader? = nil
            let headerLength = PacketHeader.encodedLength
            let parsed = framer.parseInput(minimumIncompleteLength: headerLength, maximumLength: headerLength) { buffer, isComplete in
                guard let buffer, buffer.count == headerLength else {
                    return 0
                }
                header = PacketHeader(buffer: Data(buffer))
                return headerLength
            }
            
            guard parsed, let header else {
                return headerLength
            }
            
            let message = NWProtocolFramer.Message(packetHeader: header)
            if !framer.deliverInputNoCopy(length: header.payloadSize, message: message, isComplete: true) {
                return 0
            }
        }
    }
}

//MARK: -

extension NWProtocolFramer.Message {
    
    private static let packetHeaderKey = "PacketHeader"
    
    var packetHeader: PacketHeader? { self[Self.packetHeaderKey] as? PacketHeader }
    
    convenience init(packetHeader: PacketHeader) {
        self.init(definition: OTAP.definition)
        self[Self.packetHeaderKey] = packetHeader
    }
}
