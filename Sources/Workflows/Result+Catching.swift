import Foundation

extension Result {
    /// Creates a new result by evaluating an async throwing closure, capturing the
    /// returned value as a success, or any thrown error as a failure.
    ///
    /// - Parameter body: A potentially async throwing closure to evaluate.
    init(catching work: @Sendable () async throws(Failure) -> Success) async {
        do { self = .success(try await work()) } catch { self = .failure(error) }
    }
}
