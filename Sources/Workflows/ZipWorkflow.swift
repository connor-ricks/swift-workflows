import Foundation

/// A workflow that performs a pack of child workflows concurrently.
public struct ZipWorkflow<each W: Workflow>: Workflow {
    public typealias Output = (repeat Result<(each W).Output, Error>)

    // MARK: Properties

    /// The pack of wrapped workflows.
    private let workflow: (repeat each W)

    // MARK: Initializers

    /// Creates a workflow that will run the provided workflows concurrently.
    public init(_ workflow: repeat each W) {
        self.workflow = (repeat each workflow)
    }

    // MARK: Workflow

    /// Runs the workflow, generating a result for each child workflow in the zip.
    public func run() async -> Output {
        /// Wrap all the child workflows in a cache.
        let cache = (repeat CachedWorkflow(workflow: each workflow))

        await withTaskGroup(of: Void.self) { group in
            /// Run each cache workflow.
            for cache in repeat each cache {
                group.addTask { _ = try? await cache.run() }
            }

            /// Wait for all the cache workflows to finish.
            await group.waitForAll()
        }

        /// Re-run each cache inside a result to convert to the cached output to a result.
        return (repeat await Result(catching: { try await (each cache).run() }))
    }

    /// Runs the workflow, generating a tuple of outputs from the zip.
    ///
    /// If any of the child workflows throws an error while generating their output, the whole zip will fail,
    /// throwing the first encountered error. Any remaining workflows in the zip will also be cancelled.
    public func result() async throws -> (repeat (each W).Output) {
        /// Wrap all the child workflows in a cache.
        let cache = (repeat CachedWorkflow(workflow: each workflow))

        try await withThrowingTaskGroup(of: Void.self) { group in
            /// Run each cache workflow.
            for cache in repeat each cache {
                group.addTask {
                    try Task.checkCancellation()
                    _ = try await cache.run()
                }
            }

            while !group.isEmpty {
                do { try await group.next() }
                /// If any of the cache workflows throws an error, cancel all
                /// remaining workflows and throw the error.
                catch { group.cancelAll(); throw error }
            }
        }

        try Task.checkCancellation()

        /// Re-run each cache inside a result to convert to the cached output to a result.
        return try await (repeat (each cache).run())
    }
}
