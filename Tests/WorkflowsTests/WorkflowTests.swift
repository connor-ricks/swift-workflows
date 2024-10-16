import Clocks
@testable import Workflows
import Testing

@Suite("Workflow Tests") struct WorkflowTests {
    @Test func testWorkflow_whenRun_producesExpectedOutput() async throws {
        let string = try await ValueWorkflow(value: "foo").run()
        #expect(string == "foo")
    }

    @Test func testWorkflow_whenRunThrows_throwsExpectedError() async throws {
        let expected = TestError()
        await #expect(throws: expected) {
            try await ThrowingWorkflow(error: expected).run()
        }
    }

//    @Test func testWorkflow_whenResult_producesExpectedOutput() async throws {
//        let result = await ValueWorkflow(value: "foo").result
//        #expect(try result.get() == "foo")
//    }
//
//    @Test func testWorkflow_whenResultThrows_producesExpectedOutput() async throws {
//        let expected = TestError()
//        await #expect(throws: expected) {
//            try await ThrowingWorkflow(error: expected).result.get()
//        }
//    }
}
