@testable import Semalot
import Testing

final class SemalotTests: Sendable {
    @MainActor
    var count = 0 {
        didSet {
            print(String(count), terminator: " ")
            #expect(count >= 0 && count <= 100)
        }
    }

    @Test func bonusTickets() async {
        let semalot = Semalot(tickets: 10)
        await semalot.setBonusTickets(90)

        await withTaskGroup(of: Void.self) { group in
            for x in 0 ..< 500 {
                if x == 50 {
                    await semalot.setBonusTickets(0)
                }
                group.addTask {
                    await semalot.takeTicket()
                    await MainActor.run { self.count += 1 }
                    try? await Task.sleep(for: .milliseconds(.random(in: 5 ..< 100)))
                    await MainActor.run { self.count -= 1 }
                    semalot.returnTicket()
                }
            }
        }

        print()
        await #expect(count == 0)
    }

    /// The number of concurrent ticket holders must never exceed the ticket count.
    @Test func strictConcurrencyCap() async {
        let limit: UInt = 8
        let semalot = Semalot(tickets: limit)
        let tracker = ConcurrencyTracker()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 200 {
                group.addTask {
                    await semalot.takeTicket()
                    await tracker.enter()
                    try? await Task.sleep(for: .milliseconds(.random(in: 1 ..< 10)))
                    await tracker.leave()
                    semalot.returnTicket()
                }
            }
        }

        #expect(await tracker.maxObserved <= Int(limit))
        #expect(await tracker.current == 0)
    }

    /// A single ticket should behave as a mutual exclusion lock.
    @Test func singleTicketIsMutex() async {
        let semalot = Semalot(tickets: 1)
        let tracker = ConcurrencyTracker()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 100 {
                group.addTask {
                    await semalot.takeTicket()
                    await tracker.enter()
                    try? await Task.sleep(for: .milliseconds(.random(in: 1 ..< 5)))
                    await tracker.leave()
                    semalot.returnTicket()
                }
            }
        }

        #expect(await tracker.maxObserved == 1)
        #expect(await tracker.current == 0)
    }

    /// Injecting bonus tickets must wake tasks that are already suspended in the
    /// queue, not just benefit future callers.
    @Test func bonusTicketsWakeQueuedWaiters() async {
        let semalot = Semalot(tickets: 2)
        // Hold both real tickets for the duration of the test; never return them.
        await semalot.takeTicket()
        await semalot.takeTicket()

        let resumed = Counter()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 3 {
                group.addTask {
                    await semalot.takeTicket()
                    await resumed.increment()
                    semalot.returnTicket()
                }
            }

            // Give the three tasks time to suspend in the queue.
            try? await Task.sleep(for: .milliseconds(100))
            #expect(await resumed.value == 0)

            // No real ticket is returned; only the bonus injection can free them.
            await semalot.setBonusTickets(3)
            await group.waitForAll()
        }

        #expect(await resumed.value == 3)
    }

    /// Queued tasks should resume in first-come-first-serve order.
    @Test func fairOrdering() async {
        let semalot = Semalot(tickets: 1)
        await semalot.takeTicket() // hold the only ticket

        let recorder = OrderRecorder()
        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 5 {
                group.addTask {
                    await semalot.takeTicket()
                    await recorder.record(i)
                    semalot.returnTicket()
                }
                // Let task `i` reach takeTicket and suspend before launching the
                // next one, so their queue order is deterministic.
                try? await Task.sleep(for: .milliseconds(30))
            }

            semalot.returnTicket() // release the held ticket
            await group.waitForAll()
        }

        #expect(await recorder.values == [0, 1, 2, 3, 4])
    }

    /// waitForAllTickets must not return until every outstanding ticket is back.
    @Test func waitForAllTicketsActsAsBarrier() async {
        let semalot = Semalot(tickets: 4)
        let released = Counter()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 4 {
                group.addTask {
                    await semalot.takeTicket()
                    try? await Task.sleep(for: .milliseconds(150))
                    await released.increment()
                    semalot.returnTicket()
                }
            }

            group.addTask {
                // Let the holders take all four tickets first.
                try? await Task.sleep(for: .milliseconds(20))
                await semalot.waitForAllTickets()
                #expect(await released.value == 4)
            }

            await group.waitForAll()
        }
    }

    /// Real tickets must be reusable after a full take/return cycle.
    @Test func ticketsAreReusableAfterFullCycle() async {
        let semalot = Semalot(tickets: 3)

        for _ in 0 ..< 3 { await semalot.takeTicket() }
        for _ in 0 ..< 3 { semalot.returnTicket() }
        // Let the detached returns settle before reusing.
        try? await Task.sleep(for: .milliseconds(100))

        let tracker = ConcurrencyTracker()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 30 {
                group.addTask {
                    await semalot.takeTicket()
                    await tracker.enter()
                    try? await Task.sleep(for: .milliseconds(.random(in: 1 ..< 5)))
                    await tracker.leave()
                    semalot.returnTicket()
                }
            }
        }

        #expect(await tracker.maxObserved <= 3)
        #expect(await tracker.maxObserved >= 1)
        #expect(await tracker.current == 0)
    }

    /// Once returned, bonus tickets are gone for good - capacity throttles back
    /// down to the real ticket count.
    @Test func bonusTicketsAreNotReissued() async {
        let semalot = Semalot(tickets: 2)
        await semalot.setBonusTickets(2)

        // Transient capacity of 4: all four acquisitions succeed immediately.
        await semalot.takeTicket()
        await semalot.takeTicket()
        await semalot.takeTicket()
        await semalot.takeTicket()

        // Return all four; the two bonus tickets must not re-enter the pool.
        semalot.returnTicket()
        semalot.returnTicket()
        semalot.returnTicket()
        semalot.returnTicket()
        try? await Task.sleep(for: .milliseconds(100))

        // Capacity is back down to 2, so only two of four waiters may proceed.
        let acquired = Counter()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 4 {
                group.addTask {
                    await semalot.takeTicket()
                    await acquired.increment()
                    try? await Task.sleep(for: .milliseconds(150))
                    semalot.returnTicket()
                }
            }

            try? await Task.sleep(for: .milliseconds(60))
            #expect(await acquired.value == 2)

            await group.waitForAll()
        }

        #expect(await acquired.value == 4)
    }
}

private actor ConcurrencyTracker {
    private(set) var current = 0
    private(set) var maxObserved = 0

    func enter() {
        current += 1
        maxObserved = max(maxObserved, current)
    }

    func leave() {
        current -= 1
    }
}

private actor Counter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

private actor OrderRecorder {
    private(set) var values: [Int] = []

    func record(_ value: Int) {
        values.append(value)
    }
}
