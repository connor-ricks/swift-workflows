import Clocks
import Foundation
@testable import Workflows

struct ThrowingWorkflow<Value: Sendable & Equatable>: Workflow {
    let error: TestError<Value>
    let delay: Duration
    let clock: any Clock<Duration>

    init(error: TestError<Value>, delay: Duration = .zero, clock: any Clock<Duration> = ImmediateClock()) {
        self.error = error
        self.delay = delay
        self.clock = clock
    }

    func run() async throws -> String {
        defer { print("[ INFO ] ThrowingWorkflow(error: \(error)) Completed run.") }

        print("[ INFO ] ThrowingWorkflow(error: \(error)) Starting throwing workflow run...")
        if delay != .zero {
            print("[ INFO ] ThrowingWorkflow(error: \(error)) Sleeping for \(delay) before throwing...")
            try await clock.sleep(for: delay)
            print("[ INFO ] ThrowingWorkflow(error: \(error)) Finished sleeping.")
        }

        print("[ INFO ] ThrowingWorkflow(error: \(error)) Throwing error.")
        throw error
    }
}
