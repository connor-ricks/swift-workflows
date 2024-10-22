import Clocks

extension TestClock {
    func run(afterYield: Bool) async {
        if afterYield {
            await Task.megaYield(count: 100)
        }

        await run()
    }
}
