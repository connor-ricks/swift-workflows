import ConcurrencyExtras
import Foundation

/// An actor that traces a sequence of values. Useful for verifying the order of workflow completions in tests.
actor Trace {

    // MARK: Properties

    private(set) var store: [AnyHashableSendable] = []

    // MARK: Helpers

    func callAsFunction<Value: Hashable & Sendable>(_ value: Value) {
        store.append(AnyHashableSendable(value))
    }

    static func == (lhs: Trace, rhs: [AnyHashableSendable]) async -> Bool {
        await lhs.store == rhs
    }

    static func == (lhs: [AnyHashableSendable], rhs: Trace) async -> Bool {
        await lhs == rhs.store
    }

    static func == <Value: Hashable & Sendable>(lhs: Trace, rhs: [Value]) async -> Bool {
        await lhs.store == rhs.map(AnyHashableSendable.init)
    }

    static func == <Value: Hashable & Sendable>(lhs: [Value], rhs: Trace) async -> Bool {
        await lhs.map(AnyHashableSendable.init) == rhs.store
    }
}

extension Array where Element == AnyHashableSendable {
    /// Creates an array of `AnyHashableSendable` objects with the provided parameter pack.
    init<each Value: Hashable & Sendable>(_ value: repeat each Value) {
        var array: [AnyHashableSendable] = []
        for value in repeat each value {
            array.append(AnyHashableSendable(value))
        }

        self = array
    }
}
