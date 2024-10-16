import Foundation

// MARK: - AnyWorkflow

/// A workflow that erases the type of the provided workflow.
public struct AnyWorkflow<Output: Sendable>: Workflow {

    // MARK: Properties

    private let block: @Sendable () async throws -> Output

    // MARK: Initializers

    public init<W: Workflow>(_ workflow: W) where W.Output == Output {
        self.block = workflow.run
    }

    // MARK: Run

    public func run() async throws -> Output {
        try await block()
    }
}

// MARK: - Workflow + AnyWorkflow

extension Workflow {
    /// Wraps this workflow with a type eraser.
    public func eraseToAnyWorkflow() -> AnyWorkflow<Output> {
        AnyWorkflow(self)
    }
}
