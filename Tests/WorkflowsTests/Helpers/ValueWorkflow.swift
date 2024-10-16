import Clocks
import Foundation
import Testing
@testable import Workflows

/// Creates a workflow that outputs the provided value or throws the provided value wrapped in a `TestError`.
struct ValueWorkflow<Value: Sendable & Hashable>: Workflow {

    // MARK: Properties

    private let result: Result<Value, TestError<Value>>
    let delay: Duration
    let clock: any Clock<Duration>
    let trace: Trace?

    // MARK: Initializers

    /// Creates a workflow that outputs the provided value.
    init(
        value: Value,
        delay: Duration = .zero,
        clock: any Clock<Duration> = ImmediateClock(),
        trace: Trace? = nil
    ) {
        self.result = .success(value)
        self.delay = delay
        self.clock = clock
        self.trace = trace
    }

    /// Creates a workflow that throws the provided value wrapped in a `TestError`.
    init(
        throwing value: Value,
        delay: Duration = .zero,
        clock: any Clock<Duration> = ImmediateClock(),
        trace: Trace? = nil
    ) {
        self.result = .failure(TestError(value: value))
        self.delay = delay
        self.clock = clock
        self.trace = trace
    }

    // MARK: Workflow

    func run() async throws -> Value {
        defer { log("completed run.") }

        log("starting run")
        if delay != .zero {
            log("sleeping for \(delay)")
            print("Starting Sleep")
            try? await clock.sleep(for: delay)
            log("finished sleeping.")
        }

        log("checking cancellation")
        try Task.checkCancellation()

        switch result {
        case .success(let value):
            log("tracing value.")
            await trace?(value)
            log("returning value")
            return value
        case .failure(let error):
            log("tracing value.")
            await trace?(error)
            log("throwing error")
            throw error
        }
    }

    private func log(_ message: String) {
//        let prefix = switch result {
//        case .success(let value):
//            "[ INFO ] ValueWorkflow(value: \(value))"
//        case .failure(let error):
//            "[ INFO ] ValueWorkflow(throwing: \(error))"
//        }
//
//        print("\(prefix) \(message)")
    }
}
