import Foundation

// MARK: - Workflow

/// A workflow represents a block of work that is run and generates an output.
///
/// Workflows can be useful to encapsulate and create componentized pieces of reusable business logic.
///
/// Below we define a workflow that can be used to load dogs from a cache or api.
/// ```swift
/// struct DogsWorkflow: Workflow {
///   let service: DogsService
///   let cache: DogsCache
///
///   func run() async throws -> some Sendable {
///     if cache.isExpired {
///       let dogs = try await service.fetchDogs()
///       cache.save(dogs)
///       return dogs
///     } else {
///       return cache.get()
///     }
///   }
/// }
/// ```
/// Applications often contain places in which specific logic needs to be repeated and reused.
/// Workflows can help you organize that logic be creating smaller more reusable chunks of work that
/// are more easily reused and easier to test.
public protocol Workflow<Output>: Sendable {
    associatedtype Output: Sendable
    /// Runs the workflow, generating an output.
    @Sendable func run() async throws -> Output
}

// MARK: - Workflow + Map

extension Workflow {
    /// Returns a workflow that transforms the output of this workflow into a new output.
    public func map<U: Sendable>(_ transform: @Sendable @escaping (Output) throws -> U) rethrows -> AnyWorkflow<U> {
        AnyWorkflow { try await transform(self.run()) }
    }

    /// Returns a workflow that transforms the ouput of this workflow into a new workflow.
    public func flatMap<W: Workflow>(_ transform: @Sendable @escaping (Output) throws -> W) rethrows -> AnyWorkflow<W.Output> {
        AnyWorkflow {
            try await transform(self.run()).run()
        }
    }
}
