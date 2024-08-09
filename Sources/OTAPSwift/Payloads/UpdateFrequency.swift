
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/88e53dbdc8b196c18d8354b31d7bda7ab8b28544/src/network/network_admin.cpp#L663

public struct UpdateFrequency: WritablePayload {
    public private(set) var writer: Writer
    
    init(update: GameServer.Update, frequency: GameServer.Update.Frequency) {
        self.writer = Writer()
        self.writer.append(int: update.rawValue)
        self.writer.append(int: frequency.rawValue)
    }
}
