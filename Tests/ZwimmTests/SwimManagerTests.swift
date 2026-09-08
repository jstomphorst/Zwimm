import XCTest
@testable import Zwimm

final class SwimManagerTests: XCTestCase {
    
    func testSwimManagerMockDataAndSearch() {
        let manager = SwimManager()
        manager.loadMockData()
        
        // Search from Amsterdam center (52.3676, 4.9041) within 15 km for Banenzwemmen
        let results = manager.searchSwimSessions(
            userLat: 52.3676,
            userLon: 4.9041,
            maxRadiusKm: 15.0,
            activityType: .banenzwemmen
        )
        
        // Should find Zuiderbad and Sloterparkbad, but NOT Sportbad Breda (which is ~100 km away)
        XCTAssertEqual(results.count, 2)
        let poolNames = results.map { $0.pool.name }
        XCTAssertTrue(poolNames.contains("Zuiderbad"))
        XCTAssertTrue(poolNames.contains("Sloterparkbad"))
        XCTAssertFalse(poolNames.contains("Sportbad Breda"))
    }
}
