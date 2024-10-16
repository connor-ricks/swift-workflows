import Foundation

// MARK: - Workflow

public protocol Workflow<Output>: Sendable {
    associatedtype Output: Sendable
    func run() async throws -> Output
}

// MARK: - Workflow + Helpers

extension Workflow {
    var result: Result<Output, Error> {
        get async {
            await Result {
                try await run()
            }
        }
    }
}

// MARK: - Result + Async Catching

extension Result {
    init(catching work: () async throws(Failure) -> Success) async {
        do {
            self = .success(try await work())
        } catch {
            self = .failure(error)
        }
    }
}
