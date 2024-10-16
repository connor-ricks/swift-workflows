import Foundation

/// A workflow that performs a pack of child workflows syncronously.
public struct SequenceWorkflow<each W: Workflow>: Workflow {
    public typealias Output = (repeat Result<(each W).Output, Error>)

    // MARK: Properties

    /// The pack of wrapped workflows.
    private let workflow: (repeat each W)

    // MARK: Initializers

    /// Creates a workflow that will run the provided workflows syncronously..
    public init(_ workflow: repeat each W) {
        self.workflow = (repeat each workflow)
    }

    // MARK: Workflow

    /// Runs the workflow, generating a result for each child workflow in the sequence.
    public func run() async -> Output {
        (repeat await Result(catching: {
            try Task.checkCancellation()
            return try await (each workflow).run()
        }))
    }

    /// Runs the workflow, generating a tuple of outputs from the sequence.
    ///
    /// If any of the child workflows throws an error while generating their output, the whole sequence will fail,
    /// throwing the first encountered error. Remaining workflows in the sequence will not be run.
    public func result() async throws -> (repeat (each W).Output) {
        let cache = (repeat CachedWorkflow(workflow: each workflow))
        for cache in repeat each cache {
            _ = try await cache.run()
        }

        return try await (repeat (each cache).run())
    }
}
