import Foundation

struct TestError<Value: Sendable & Equatable>: Error, Equatable {
    let value: Value

    init() where Value == Int {
        self.init(value: 1)
    }

    init(value: Value) {
        self.value = value
    }
}
