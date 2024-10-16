import Foundation

/// A type-erased workflow.
///
/// Use ``AnyWorkflow`` to wrap a workflow whose type has details you don't want to expose across API
/// boundaries, such as different modules. When you use type erasure this way, you can change the
/// underlying parser over time without affecting existing clients.
public struct AnyWorkflow<Output: Sendable>: Workflow {

    // MARK: Properties

    private let block: @Sendable () async throws -> Output

    // MARK: Initializers

    init(_ block: @Sendable @escaping () async throws -> Output) {
        self.block = block
    }

    /// Creates a type-erased workflow from the provided workflow.
    public init<W: Workflow>(_ workflow: W) where W.Output == Output {
        self.block = workflow.run
    }

    // MARK: Workflow

    /// Runs the workflow, generating an output.
    public func run() async throws -> Output {
        try await block()
    }
}

// MARK: - Workflow + AnyWorkflow

extension AnyWorkflow {
    /// Creates a type-erased workflow from this ``Workflow``.
    public func eraseToAnyWorkflow() -> AnyWorkflow<Output> {
        AnyWorkflow(self)
    }
}
