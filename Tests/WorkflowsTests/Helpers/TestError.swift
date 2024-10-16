import Foundation

/// An error constructed from a given value. Useful in tests for validating the expected error is thrown.
struct TestError<Value: Sendable & Hashable>: Error, Hashable {

    // MARK: Properties

    let value: Value
}
