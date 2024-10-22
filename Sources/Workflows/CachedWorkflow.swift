import Foundation

// MARK: - OutputCache

/// A cache used to power the ``CachedWorkflow/Output`` of a ``CachedWorkflow``.
///
/// An ``OutputCache`` stores the result of ``CachedWorkflow/run()`,
/// allowing subsequent calls to pull from the the cache, rather than re-running
/// the ``Output`` again.
///
/// You can create your own ``OutputCache`` objects by conforming to the ``OutputCache``
/// protocol and implementing the ``read()`` and ``save(_:)`` requirements.
///
/// Creating your own cache can be useful for creating more complex caches.
public protocol OutputCache<Output>: Sendable {
    associatedtype Output: Sendable
    func read() async throws -> Result<Output, Error>?
    func save(_ result: Result<Output, Error>) async throws
}

// MARK: - InMemoryOutputCache

/// An in-memory cache used to power the ``CachedWorkflow/Output`` of a ``CachedWorkflow``
///
/// The ``InMemoryOutputCache`` stores its output in memory, returning the result last saved.
public actor InMemoryOutputCache<Output: Sendable>: OutputCache {

    // MARK: Properties

    /// The currently cached result.
    private var result: Result<Output, Error>?

    // MARK: Initailizers

    /// Creates an in-memory cache initialized with the provided result.
    public init(result: Result<Output, Error>? = nil) {
        self.result = result
    }

    // MARK: OutputCache

    /// Returns the saved result, if one exists, from the cache.
    public func read() -> Result<Output, Error>? {
        result
    }

    /// Saves the provided result to the cache.
    public func save(_ result: Result<Output, Error>) {
        self.result = result
    }

    /// Deletes the saved result, if one exists, from the cache.
    public func delete() {
        self.result = nil
    }
}

// MARK: - CachedWorkflow

/// A workflow that performs a child workflow once, caching the child's output for subsequent runs.
public actor CachedWorkflow<W: Workflow>: Workflow {
    public typealias Output = W.Output

    // MARK: Properties

    /// The cache that backs the workflow.
    private var cache: any OutputCache<Output>

    /// The wrapped workflow.
    private let workflow: W

    // MARK: Initializers

    /// Creates a workflow that will cache the first output for subsequent runs.
    public init(workflow: W, cache: any OutputCache<Output> = InMemoryOutputCache<W.Output>()) {
        self.workflow = workflow
        self.cache = cache
    }

    // MARK: Workflow

    /// Runs the workflow, generating an output.
    public func run() async throws -> W.Output {
        guard let result = try await cache.read() else {
            let result = await Result(catching: {
                let output = try await workflow.run()
                try Task.checkCancellation()
                return output
            })

            try await self.cache.save(result)
            return try result.get()
        }

        try Task.checkCancellation()
        return try result.get()
    }
}
