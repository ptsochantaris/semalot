import Foundation
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

    @Test func testBonusTickets() async {
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
                    try? await Task.sleep(nanoseconds: UInt64.random(in: 5 ..< 100) * NSEC_PER_MSEC)
                    await MainActor.run { self.count -= 1 }
                    semalot.returnTicket()
                }
            }
        }

        print()
        await #expect(count == 0)
    }
}
