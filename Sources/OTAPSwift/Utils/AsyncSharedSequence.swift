
import Foundation

/// Async sequence implementation that can be shared amond multiple stream consumers
/// Something like basic Combine publisher but with structured concurrency
/// Largely inspired by: https://github.com/reddavis/Asynchrone/blob/main/Sources/Asynchrone/Sequences/SharedAsyncSequence.swift
///
public struct AsyncSharedSequence<Base: AsyncSequence>: AsyncSequence, Sendable where Base: Sendable {
    
    public typealias SubSequence = AsyncThrowingStream<Base.Element, Error>
    public typealias AsyncIterator = SubSequence.Iterator
    public typealias Element = SubSequence.Element

    private let base: Base
    private let manager: SharedSequenceManager
    
    public init(_ base: Base) {
        self.base = base
        self.manager = SharedSequenceManager(base)
    }
    
    public func shared() -> SubSequence {
        self.manager.makeSharedSequence()
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        self.manager.makeSharedSequence().makeAsyncIterator()
    }
    
    actor SharedSequenceManager {
        
        private var base: Base
        private var continuations: [String: SubSequence.Continuation] = [:]
        private var subscriptionTask: Task<Void, Never>?
        
        init(_ base: Base) {
            self.base = base
        }
        
        deinit {
            subscriptionTask?.cancel()
        }
        
        nonisolated func makeSharedSequence() -> SubSequence {
            let id = UUID().uuidString
            let sequence = SubSequence {
                $0.onTermination = { @Sendable _ in
                    self.remove(id)
                }
                await self.add(id: id, continuation: $0)
            }
            return sequence
        }
        
        nonisolated private func remove(_ id: String) {
            Task {
                await self._remove(id)
            }
        }
        
        private func _remove(_ id: String) {
            self.continuations.removeValue(forKey: id)
        }
        
        private func add(id: String, continuation: SubSequence.Continuation) {
            self.continuations[id] = continuation
            self.subscribeToBaseSequenceIfNeeded()
        }
        
        private func subscribeToBaseSequenceIfNeeded() {
            guard self.subscriptionTask == nil else { return }
            
            self.subscriptionTask = Task { [weak self, base] in
                guard let self else { return }
                
                guard !Task.isCancelled else {
                    await self.continuations.values.forEach { $0.finish(throwing: CancellationError()) }
                    return
                }
                
                do {
                    for try await value in base {
                        await self.continuations.values.forEach { $0.yield(value) }
                    }
                    await self.continuations.values.forEach { $0.finish() }
                } catch {
                    await self.continuations.values.forEach { $0.finish(throwing: error) }
                }
            }
        }
    }
}

//MARK: -

extension AsyncSequence {

    /// Wraps `AsyncSequence` in shared sequence
    public func shared() -> AsyncSharedSequence<Self> where Self: Sendable {
        .init(self)
    }
}
