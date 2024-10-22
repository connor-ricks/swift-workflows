import Clocks

extension TestClock {
    func run(afterYield: Bool) async {
        if afterYield {
            await Task.yield()
        }

        await run()
    }
}
