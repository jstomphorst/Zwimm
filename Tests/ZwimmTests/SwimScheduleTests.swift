import XCTest
@testable import Zwimm

final class SwimScheduleTests: XCTestCase {
    
    func testDistanceCalculation() {
        let schedule = SwimSchedule()
        // Amsterdam Central to Utrecht Central is approx 35-38 km
        // Amdsterdam: 52.3791, 4.9003
        // Utrecht: 52.0907, 5.1097
        let dist = schedule.distance(lat1: 52.3791, lon1: 4.9003, lat2: 52.0907, lon2: 5.1097)
        XCTAssertTrue(dist > 30.0 && dist < 45.0, "Calculated distance \(dist) km is out of expected range.")
    }

    func testParseScheduleText() {
        let schedule = SwimSchedule()
        let rawData = """
        pool-1 | Banenzwemmen | 2026-09-10 | 07:00 | 09:00 | Early bird session
        pool-2 | Recreatief zwemmen | 2026-09-10 | 12:00 | 17:00 | Family fun
        """
        let slots = schedule.parseSchedule(data: rawData)
        XCTAssertEqual(slots.count, 2)
        XCTAssertEqual(slots[0].poolId, "pool-1")
        XCTAssertEqual(slots[0].activityType, .banenzwemmen)
        XCTAssertEqual(slots[0].startTime, "07:00")
        XCTAssertEqual(slots[1].activityType, .recreatief)
    }

    func testFilterSlotsByRadiusAndActivity() {
        let schedule = SwimSchedule()
        
        let pools = [
            Pool(id: "pool-near", name: "Dichtbij Bad", address: "Straat 1", latitude: 52.3700, longitude: 4.8900),
            Pool(id: "pool-far", name: "Ver Bad", address: "Straat 2", latitude: 53.0000, longitude: 6.0000)
        ]
        
        let slots = [
            ScheduleSlot(id: "s1", poolId: "pool-near", activityType: .banenzwemmen, date: "2026-09-10", startTime: "08:00", endTime: "10:00"),
            ScheduleSlot(id: "s2", poolId: "pool-far", activityType: .banenzwemmen, date: "2026-09-10", startTime: "08:00", endTime: "10:00"),
            ScheduleSlot(id: "s3", poolId: "pool-near", activityType: .recreatief, date: "2026-09-10", startTime: "13:00", endTime: "17:00")
        ]
        
        // User in Amsterdam (52.3791, 4.9003), radius 20 km, activity Banenzwemmen
        let results = schedule.filterSlots(
            slots: slots,
            pools: pools,
            userLat: 52.3791,
            userLon: 4.9003,
            maxRadiusKm: 20.0,
            activityType: .banenzwemmen
        )
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].slot.id, "s1")
        XCTAssertEqual(results[0].pool.name, "Dichtbij Bad")
    }
}
