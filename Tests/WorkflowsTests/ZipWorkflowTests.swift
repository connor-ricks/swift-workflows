import Clocks
@testable import Workflows
import Testing

@Suite("ZipWorkflow Tests") struct ZipWorkflowTests {

    // MARK: - Run Tests

    @Test func testZipWorkflow_whenRun_producesExpectedOutput() async throws {
        let (string, int, bool) = try await ZipWorkflow(
            ValueWorkflow(value: "foo"),
            ValueWorkflow(value: 1),
            ValueWorkflow(value: true)
        ).run()

        #expect(string == "foo")
        #expect(int == 1)
        #expect(bool == true)
    }

    @Test func testZipWorkflow_whenRunFirstWorkflowThrows_throwsExpectedError() async throws {
        let expected = TestError()
        await #expect(throws: expected) {
            try await ZipWorkflow(
                ThrowingWorkflow(error: expected),
                ValueWorkflow(value: 1)
            ).run()
        }
    }

    @Test func testZipWorkflow_whenRunLastWorkflowThrows_throwsExpectedError() async throws {
        let expected = TestError()
        await #expect(throws: expected) {
            try await ZipWorkflow(
                ValueWorkflow(value: 1),
                ThrowingWorkflow(error: expected)
            ).run()
        }
    }

    @Test func testZipWorkflow_whenRunMultipleWorkflowsThrow_throwsFirstConcurrentOccurringError() async throws {
        let clock = TestClock()
        let expected = TestError(value: "bar")
        let unexpected = TestError(value: "foo")

        do {
            async let output = try await ZipWorkflow(
                ValueWorkflow(value: 1, delay: .seconds(4), clock: clock),
                ThrowingWorkflow(error: unexpected, delay: .seconds(3), clock: clock),
                ValueWorkflow(value: 2, delay: .seconds(2), clock: clock),
                ThrowingWorkflow(error: expected, delay: .seconds(1), clock: clock)
            ).run()

            await clock.run()
            _ = try await output
            Issue.record("ZipWorkflow should have thrown an error.")
        } catch {
            #expect(error as? TestError<String> == expected)
        }
    }

    @Test func testZipWorkflow_whenRun_executesWorkConcurrently() async throws {
        let clock = TestClock()

        class Trace: @unchecked Sendable {
            var array: [String] = []
        }

        let trace = Trace()

        async let output = try await ZipWorkflow(
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
        #expect(trace.array == ["bar", "foo"])
    }

    // MARK: - Result Tests

//    @Test func foo() async throws {
//        let error = TestError()
//        let workflow = try await ZipWorkflow(
//            ThrowingWorkflow(error: error),
//            ValueWorkflow(value: 1)
//        )
//        .eraseToAnyWorkflow()
//        .run()
//
//        let lol = workflow.run()
////        .run()
//        //.eraseToAnyWorkflow()
//
////        try await workflow.run()
//
////        #expect(throws: error) { try throwing.get() }
////        #expect(try value.get() == 1)
//    }
}
