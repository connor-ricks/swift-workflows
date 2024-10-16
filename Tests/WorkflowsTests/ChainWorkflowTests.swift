import Clocks
@testable import Workflows
import Testing

@Suite("ChainWorkflow Tests") struct ChainWorkflowTests {
    @Test func testChainWorkflow_whenRun_producesExpectedOutput() async throws {
        let (string, int, bool) = try await ChainWorkflow(
            ValueWorkflow(value: "foo"),
            ValueWorkflow(value: 1),
            ValueWorkflow(value: true)
        ).run()

        #expect(string == "foo")
        #expect(int == 1)
        #expect(bool == true)
    }

    @Test func testChainWorkflow_whenRunFirstWorkflowThrows_throwsExpectedError() async throws {
        let expected = TestError(value: 1)
        await #expect(throws: expected) {
            try await ChainWorkflow(
                ThrowingWorkflow(error: expected),
                ValueWorkflow(value: "foo")
            ).run()
        }
    }

    @Test func testChainWorkflow_whenRunLastWorkflowThrows_throwsExpectedError() async throws {
        let expected = TestError()
        await #expect(throws: expected) {
            try await ChainWorkflow(
                ValueWorkflow(value: 1),
                ThrowingWorkflow(error: expected)
            ).run()
        }
    }

    @Test func testChainWorkflow_whenRunMultipleWorkflowsThrow_throwsFirstSyncronousOccurringError() async throws {
        let clock = TestClock()
        let expected = TestError(value: "foo")
        let unexpected = TestError(value: "bar")

        do {
            async let output = try await ChainWorkflow(
                ValueWorkflow(value: 1, delay: .seconds(4), clock: clock),
                ThrowingWorkflow(error: expected, delay: .seconds(3), clock: clock),
                ValueWorkflow(value: 2, delay: .seconds(2), clock: clock),
                ThrowingWorkflow(error: unexpected, delay: .seconds(1), clock: clock)
            ).run()

            await clock.run()
            _ = try await output
            Issue.record("ChainWorkflow should have thrown an error.")
        } catch {
            #expect(error as? TestError<String> == expected)
        }
    }

    @Test func testChainWorkflow_whenRun_executesWorkSyncronously() async throws {
        let clock = TestClock()

        class Trace: @unchecked Sendable {
            var array: [String] = []
        }

        let trace = Trace()

        async let output = try await ChainWorkflow(
            BlockWorkflow {
                try await clock.sleep(for: .seconds(5))
                trace.array.append("foo")
                return "foo"
            },
            BlockWorkflow {
                try await clock.sleep(for: .seconds(2))
                trace.array.append("bar")
                return "bar"
            }
        ).run()

        await clock.run()

        let (first, second) = try await output
        #expect(first == "foo")
        #expect(second == "bar")
        #expect(trace.array == ["foo", "bar"])
    }
}
