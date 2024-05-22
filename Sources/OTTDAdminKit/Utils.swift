
import Foundation
import BitByteData

//MARK: -

internal typealias Builder<Input, Output> = (Input) throws -> Output

internal func create<Output, Input>(_ method: @escaping Builder<Input, Output>) -> Builder<Input, Output> {
    return method
}

internal func create<Output, Input>(_ input: Input, method: @escaping Builder<Input, Output>) throws -> Output {
    return try create(method)(input)
}

//MARK: -

extension Data {
    
    @inlinable @inline(__always)
    func toPacketSize() -> PacketType.PacketSize {
        return self.withUnsafeBytes { $0.bindMemory(to: PacketType.PacketSize.self)[0] }
    }
}
