
import Foundation
import BitByteData

//MARK: -

extension Data {
    
    @inlinable @inline(__always)
    func toPacketSize() -> PacketType.PacketSize {
        return self.withUnsafeBytes { $0.bindMemory(to: PacketType.PacketSize.self)[0] }
    }
}

//MARK: -

extension Task where Failure == Error {
    
    static func delayed(for duration: Duration,
                        priority: TaskPriority? = nil,
                        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            try await Task<Never, Never>.sleep(for: duration, tolerance: .zero)
            return try await operation()
        }
    }
}

//MARK: -

extension AsyncThrowingStream {

    /// Allows to build the stream with async build closure
    public init(_ elementType: Element.Type = Element.self,
                bufferingPolicy limit: AsyncThrowingStream<Element, Failure>.Continuation.BufferingPolicy = .unbounded,
                _ build: @Sendable @escaping (AsyncThrowingStream<Element, Failure>.Continuation) async -> Void
    ) where Failure == Error {
        self = AsyncThrowingStream(elementType, bufferingPolicy: limit) { continuation in
            let task = Task {
                await build(continuation)
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

//MARK: -

extension ExpressibleByIntegerLiteral {

    init(_ booleanLiteral: BooleanLiteralType) {
        self = booleanLiteral ? 1 : 0
    }
}
