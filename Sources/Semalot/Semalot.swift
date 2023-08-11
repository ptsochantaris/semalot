#if swift(<5.9)

import Lista

// An instance of the counting semaphore
public final actor Semalot {
    private var headroom: Int
    private let queue = Lista<() -> Void>()

    /// Initialise the counter with an initial ticket count
    /// - Parameter tickets: The number of tickets that are available to take before the calling task needs to suspend until one of the tickets is returned.
    public init(tickets: Int) {
        headroom = tickets
    }

    /// Take a ticket. If there are none available, suspend until one becomes available. Scheduling is fair, meaning that the tasks waiting will resume on a first-come-first-serve basis as tickets are returned by other tasks. Calls to this method MUST be balanced with a call to ``returnTicket()`` at some point.
    public func takeTicket() async {
        guard headroom == 0 else {
            headroom -= 1
            return
        }
        
        await withCheckedContinuation { continuation in
            queue.append {
                continuation.resume()
            }
        }
    }

    private func _returnTicket() {
        if let nextInQueue = queue.pop() {
            nextInQueue()
        } else {
            headroom += 1
        }
    }

    /// Return a ticket to the counter after having taken one out.
    nonisolated public func returnTicket() {
        Task.detached {
            await self._returnTicket()
        }
    }
}

#else

// An instance of the counting semaphore
public struct Semalot {
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation
    
    /// Initialise the counter with an initial ticket count
    /// - Parameter tickets: The number of tickets that are available to take before the calling task needs to suspend until one of the tickets is returned.
    public init(tickets: Int) {
        (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        for _ in 0 ..< tickets {
            continuation.yield()
        }
    }
    
    /// Take a ticket. If there are none available, suspend until one becomes available. Scheduling is fair, meaning that the tasks waiting will resume on a first-come-first-serve basis as tickets are returned by other tasks. Calls to this method MUST be balanced with a call to ``returnTicket()`` at some point.
    public func takeTicket() async {
        await stream.first { true }
    }
    
    /// Return a ticket to the counter after having taken one out.
    public func returnTicket() {
        Task.detached {
            self.continuation.yield()
        }
    }
}

#endif
