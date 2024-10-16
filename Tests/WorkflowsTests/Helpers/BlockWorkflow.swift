import Foundation
@testable import Workflows

struct BlockWorkflow<Value: Sendable & Equatable>: Workflow {
    let block: @Sendable () async throws -> Value

    init(_ block: @Sendable @escaping () async throws -> Value) {
        self.block = block
    }

    func run() async throws -> Value {
        try await block()
    }
}
