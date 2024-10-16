import Clocks
import Foundation
@testable import Workflows

struct ValueWorkflow<Value: Sendable & Equatable>: Workflow {
    let value: Value
    let delay: Duration
    let clock: any Clock<Duration>

    init(value: Value, delay: Duration = .zero, clock: any Clock<Duration> = ImmediateClock()) {
        self.value = value
        self.delay = delay
        self.clock = clock
    }

    func run() async throws -> Value {
        defer { print("[ INFO ] ValueWorkflow(value: \(value)) Completed run.") }

        print("[ INFO ] ValueWorkflow(value: \(value)) Starting value workflow run...")
        if delay != .zero {
            print("[ INFO ] ValueWorkflow(value: \(value)) Sleeping for \(delay) before returning...")
            try await clock.sleep(for: delay)
            print("[ INFO ] ValueWorkflow(value: \(value)) Finished sleeping.")
        }

        print("[ INFO ] ValueWorkflow(value: \(value)) Returning value.")
        return value
    }
}
