import Foundation

/// A workflow that outputs a Task with a success value of the provided workflow.
struct TaskWorkflow<Output: Sendable>: Workflow {

    // MARK: Properties

    private let block: @Sendable () async throws -> Output

    // MARK: Initializers

    init<W: Workflow>(_ workflow: W) where W.Output == Output {
        self.block = workflow.run
    }

    // MARK: Run

    func run() async -> Task<Output, Error> {
        Task {
            try await block()
        }
    }
}
