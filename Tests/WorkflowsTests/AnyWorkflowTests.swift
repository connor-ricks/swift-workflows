//import Clocks
//@testable import StorybookWorkflow
//import Testing
//
//@Suite("AnyWorkflow Tests") struct AnyWorkflowTests {
//    @Test func testAnyWorkflow_whenRun_producesExpectedOutput() async throws {
//        let string = try await AnyWorkflow(
//            ValueWorkflow(value: "foo")
//        ).run()
//        #expect(string == "foo")
//    }
//
//    @Test func testAnyWorkflow_whenRunThrows_throwsExpectedError() async throws {
//        let expected = TestError()
//        await #expect(throws: expected) {
//            try await AnyWorkflow(
//                ThrowingWorkflow(error: expected)
//            ).run()
//        }
//    }
//
//    @Test func testAnyWorkflowConvenience_whenRun_producesExpectedOutput() async throws {
//        let string = try await ValueWorkflow(value: "foo")
//            .eraseToAnyWorkflow()
//            .run()
//        #expect(string == "foo")
//    }
//
//    @Test func testAnyWorkflowConvenience_whenRunThrows_throwsExpectedError() async throws {
//        let expected = TestError()
//        await #expect(throws: expected) {
//            try await ThrowingWorkflow(error: expected)
//                .eraseToAnyWorkflow()
//                .run()
//        }
//    }
//}
