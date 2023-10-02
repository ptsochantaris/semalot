import Lista

// An instance of the counting semaphore
public final actor Semalot {
    private var headroom: UInt
    private let maxHeadroom: UInt
    private var bonusTickets: UInt = 0
    private var bonusLoaned: UInt = 0
    private let queue = Lista<() -> Void>()

    /// Initialise the counter with an initial ticket count
    /// - Parameter tickets: The number of tickets that are available to take before the calling task needs to suspend until one of the tickets is returned.
    public init(tickets: UInt) {
        headroom = tickets
        maxHeadroom = tickets
    }

    /// Take a ticket. If there are none available, suspend until one becomes available. Scheduling is fair, meaning that the tasks waiting will resume on a first-come-first-serve basis as tickets are returned by other tasks. Calls to this method MUST be balanced with a call to ``returnTicket()`` at some point.
    public func takeTicket() async {
        guard headroom == 0 else {
            headroom -= 1
            return
        }

        guard bonusTickets == 0 else {
            bonusTickets -= 1
            bonusLoaned += 1
            return
        }

        await withCheckedContinuation { continuation in
            queue.append {
                continuation.resume()
            }
        }
    }

    /// Set this to a non-zero value to create a temporary extra bunch of tickets that can be sent out immediately. These tickets won't be re-used once they are returned - but _they must_ be returned just like the others. This is very useful when some constraint needs to be large initially for responsiveness, but becomes throttled over time for long operations.
    public func setBonusTickets(_ count: UInt) {
        bonusTickets = count
    }

    /// A convenience method that will wait until all tickets have been returned before continuing. No new tickets will be issued if requested from other places until this method instance returns. Note that this does *not* take into account any bonus tickets.
    public func waitForAllTickets() async {
        for _ in 0 ..< maxHeadroom {
            await takeTicket()
        }
        for _ in 0 ..< maxHeadroom {
            returnTicket()
        }
    }

    private func _returnTicket() {
        if bonusLoaned > 0 {
            bonusLoaned -= 1
        } else if let nextInQueue = queue.pop() {
            nextInQueue()
        } else {
            headroom += 1
        }
    }

    /// Return a ticket to the counter after having taken one out. Not returning a ticket will eventually cause the counter to run out and stop handing more out until some are returned.
    public nonisolated func returnTicket() {
        Task.detached {
            await self._returnTicket()
        }
    }
}
