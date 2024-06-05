
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

//MARK: -

internal final class ThrowingEmitter<Value: Sendable, Failure: Error>: Sendable {
    
    typealias Stream = AsyncThrowingStream<Value, Error>
    
    let stream: Stream
    private let continuation: Stream.Continuation
    
    init() {
        (stream, continuation) = Stream.makeStream()
    }
    
    func emit(_ value: Value) {
        continuation.yield(value)
    }
    
    func finish(throwing error: Failure) {
        continuation.finish(throwing: error)
    }
    
    func finish() {
        continuation.finish()
    }
}

//MARK: -

extension Task where Failure == Error {
    
    static func delayed(for duration: Duration,
                        priority: TaskPriority? = nil,
                        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            try await Task<Never, Never>.sleep(for: duration)
            return try await operation()
        }
    }
}
