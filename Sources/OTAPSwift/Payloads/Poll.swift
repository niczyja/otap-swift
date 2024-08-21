
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/88e53dbdc8b196c18d8354b31d7bda7ab8b28544/src/network/network_admin.cpp#L683

public struct Poll: WritablePayload {
    public private(set) var writer: Writer
    
    init(update: GameServer.Update, param: UInt32 = 0) {
        self.writer = Writer()
        self.writer.append(byte: UInt8(truncatingIfNeeded: update.rawValue))
        self.writer.append(int: param)
    }
}
