import Foundation

// MARK: - TupleWorkflow

/// A workfklow that runs a tuple of child workflows.
///
/// You can specify whether or not the workflows should execute concurrently
/// or not using the ``TupleWorkflow/shouldExecuteConcurrently`` property.
public struct TupleWorkflow<each O: Sendable>: Workflow {
    public typealias Output = (repeat each O)

    // MARK: Properties

    private let workflow: (repeat AnyWorkflow<each O>)

    private let shouldExecuteConcurrently: Bool

    // MARK: Initializers

    public init<each W: Workflow>(_ workflow: repeat each W, shouldExecuteConcurrently: Bool) where repeat (each W).Output == each O {
        self.workflow = (repeat (each workflow).eraseToAnyWorkflow())
        self.shouldExecuteConcurrently = shouldExecuteConcurrently
    }

    // MARK: Workflow

    public func run() async throws -> Output {
        guard shouldExecuteConcurrently else {
            return try await (repeat (each workflow).run())
        }

        /// Convert the workflows into tasks.
        let task = await (repeat TaskWorkflow(each workflow).run())

        /// Create a task group to make sure that the correct error is propogated.
        /// Without this task group, the workflow throws the last seen error in the collection of workflows.
        /// With this task group, the parameter pack correctly throws when the first error occurs.
        try await withThrowingTaskGroup(of: Void.self) { group in
            for task in repeat each task {
                group.addTask { _ = try await task.value }
            }

            try await group.waitForAll()
        }

        return try await (repeat (each task).value)
    }

//    public var result: (repeat Result<each O, Error>) {
//        get async {
//            guard shouldExecuteConcurrently else {
//                return await (repeat (each workflow).result)
//            }
//
//            /// Convert the workflows into tasks.
//            let task = await (repeat TaskWorkflow(each workflow).run())
//
//            /// Create a task group to make sure that the correct error is propogated.
//            /// Without this task group, the workflow throws the last seen error in the collection of workflows.
//            /// With this task group, the parameter pack correctly throws when the first error occurs.
//            await withTaskGroup(of: Void.self) { group in
//                for task in repeat each task {
//                    group.addTask { _ = await task.result }
//                }
//
//                await group.waitForAll()
//            }
//
//            return await (repeat (each task).result)
//        }
//    }
}

// swiftlint:disable identifier_name

// MARK: - ZipWorkflow

/// A workflow that performs a series of child workflows concurrently.
public func ZipWorkflow<each W: Workflow>(
    _ workflow: repeat each W
) -> TupleWorkflow<repeat (each W).Output> {
    TupleWorkflow(repeat each workflow, shouldExecuteConcurrently: true)
}

// MARK: - ChainWorkflow

/// A workflow that runs a series of child workflows syncronously.
public func ChainWorkflow<each W: Workflow>(
    _ workflow: repeat each W
) -> TupleWorkflow<repeat (each W).Output> {
    TupleWorkflow(repeat each workflow, shouldExecuteConcurrently: false)
}

// swiftlint:enable identifier_name

// MARK: - TupleWorkflow + Helpers

//extension TupleWorkflow {
//
//    //    /// Creates a new workflow that transforms the output of this workflow using the provided transform.
//    //    public func map<U>(_ transform: @escaping (Output) async throws -> U) async rethrows -> some Workflow {
//    //        BlockWorkflow {
//    //            try await transform(run())
//    //        }.eraseToAnyWorkflow()
//    //    }
//
//    public func append<W: Workflow>(_ other: W) async throws -> TupleWorkflow<repeat each O, W.Output> {
//        TupleWorkflow<repeat each O, W.Output>(
//            repeat each workflow, other, shouldExecuteConcurrently: shouldExecuteConcurrently
//        )
//    }
//}
