import Clocks

extension TestClock {
    func run(afterYield: Bool) async {
        await run(timeout: .seconds(5))
    }
}
