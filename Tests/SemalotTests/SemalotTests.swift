@testable import Semalot
import XCTest

final class SemalotTests: XCTestCase {
    var count = 0 {
        didSet {
            print(String(count), terminator: " ")
            XCTAssert(count >= 0 && count <= 100)
        }
    }

    @MainActor
    func testBonusTickets() async {
        let semalot = Semalot(tickets: 10)
        await semalot.setBonusTickets(90)
        
        await withTaskGroup(of: Void.self) { group in
            for x in 0 ..< 500 {
                if x == 50 {
                    await semalot.setBonusTickets(0)
                }
                group.addTask { @MainActor in
                    await semalot.takeTicket()
                    self.count += 1
                    try? await Task.sleep(nanoseconds: UInt64.random(in: 5 ..< 100) * NSEC_PER_MSEC)
                    self.count -= 1
                    semalot.returnTicket()
                }
            }
        }

        print()
        XCTAssertEqual(count, 0)
    }
}
