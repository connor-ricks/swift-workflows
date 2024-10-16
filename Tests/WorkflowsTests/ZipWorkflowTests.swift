import Clocks
import ConcurrencyExtras
import Testing
@testable import Workflows

@Suite("ZipWorkflow Tests") struct ZipWorkflowTests {
    @Test func testZipWorkflow_whenRun_producesExpectedResultsConcurrently() async throws {
        try await withMainSerialExecutor {
            let clock = TestClock()
            let trace = Trace()

            async let output = await ZipWorkflow(
                ValueWorkflow(value: 1, delay: .seconds(3), clock: clock, trace: trace),
                ValueWorkflow(value: "foo", delay: .seconds(1), clock: clock, trace: trace),
                ValueWorkflow(throwing: 1, delay: .seconds(4), clock: clock, trace: trace),
                ValueWorkflow(value: true, delay: .seconds(2), clock: clock, trace: trace)
            ).run()

            await clock.run(afterYield: true)

            let (one, two, three, four) = await output
            try #expect(one.get() == 1)
            try #expect(two.get() == "foo")
            #expect(throws: TestError(value: 1)) { try three.get() }
            try #expect(four.get() == true)
            #expect(await trace == Array("foo", true, 1, TestError(value: 1)))
        }
    }

    @Test func testZipWorkflow_whenResultAndNoThrows_producesResultConcurrently() async throws {
        try await withMainSerialExecutor {
            let clock = TestClock()
            let trace = Trace()

            async let output = await ZipWorkflow(
                ValueWorkflow(value: 1, delay: .seconds(3), clock: clock, trace: trace),
                ValueWorkflow(value: "foo", delay: .seconds(1), clock: clock, trace: trace),
                ValueWorkflow(value: true, delay: .seconds(2), clock: clock, trace: trace)
            ).result()

            await clock.run(afterYield: true)

            let (one, two, three) = try await output
            #expect(one == 1)
            #expect(two == "foo")
            #expect(three == true)
            #expect(await trace == Array("foo", true, 1))
        }
    }

    @Test func testZipWorkflow_whenResultAndThrows_producesResultConcurrentlyStoppingAfterError() async throws {
        await withMainSerialExecutor {
            let clock = TestClock()
            let trace = Trace()

            async let output = await ZipWorkflow(
                ValueWorkflow(throwing: 1, delay: .seconds(2), clock: clock, trace: trace),
                ValueWorkflow(value: 1, delay: .seconds(3), clock: clock, trace: trace),
                ValueWorkflow(value: "foo", delay: .seconds(1), clock: clock, trace: trace)
            ).result()

            await clock.run(afterYield: true)

            do {
                _ = try await output
                Issue.record("Workflow should have thrown an error.")
            } catch {
                #expect(error as? TestError<Int> == TestError(value: 1))
            }

            #expect(await trace == Array("foo", TestError(value: 1)))
        }
    }
}
