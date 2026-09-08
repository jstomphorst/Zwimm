import Foundation

public class SwimManager {
    private var pools: [Pool] = []
    private var slots: [ScheduleSlot] = []
    private let scheduleEngine = SwimSchedule()

    public init(pools: [Pool] = [], slots: [ScheduleSlot] = []) {
        self.pools = pools
        self.slots = slots
    }

    public func setPools(_ pools: [Pool]) {
        self.pools = pools
    }

    public func setSlots(_ slots: [ScheduleSlot]) {
        self.slots = slots
    }

    public func addPool(_ pool: Pool) {
        self.pools.append(pool)
    }

    public func addSlot(_ slot: ScheduleSlot) {
        self.slots.append(slot)
    }

    /// Searches available swim slots for a user location, radius, activity and optional date range
    public func searchSwimSessions(
        userLat: Double,
        userLon: Double,
        maxRadiusKm: Double,
        activityType: ActivityType? = nil,
        startDate: String? = nil,
        endDate: String? = nil
    ) -> [(slot: ScheduleSlot, pool: Pool, distanceKm: Double)] {
        
        return scheduleEngine.filterSlots(
            slots: slots,
            pools: pools,
            userLat: userLat,
            userLon: userLon,
            maxRadiusKm: maxRadiusKm,
            activityType: activityType,
            startDate: startDate,
            endDate: endDate
        )
    }

    /// Loads mock data representing typical pools and swimming sessions in the Netherlands
    public func loadMockData() {
        self.pools = [
            Pool(id: "pool-de-pijp", name: "Zuiderbad", address: "Hobbemakade 67, Amsterdam", latitude: 52.3550, longitude: 4.8910, website: "https://zuiderbad.nl"),
            Pool(id: "pool-sloterpark", name: "Sloterparkbad", address: "President Allendelaan 3, Amsterdam", latitude: 52.3680, longitude: 4.8250, website: "https://sloterparkbad.nl"),
            Pool(id: "pool-breda", name: "Sportbad Breda", address: "Duivelsbruglaan 7, Breda", latitude: 51.5880, longitude: 4.7930, website: "https://sportbadbreda.nl")
        ]

        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // YYYY-MM-DD
        
        self.slots = [
            ScheduleSlot(id: "s1", poolId: "pool-de-pijp", activityType: .banenzwemmen, date: String(today), startTime: "07:00", endTime: "09:00", notes: "Ochtendbanen"),
            ScheduleSlot(id: "s2", poolId: "pool-sloterpark", activityType: .banenzwemmen, date: String(today), startTime: "08:00", endTime: "10:30", notes: "Olympisch bad"),
            ScheduleSlot(id: "s3", poolId: "pool-sloterpark", activityType: .recreatief, date: String(today), startTime: "13:00", endTime: "17:00", notes: "Glijbaan open"),
            ScheduleSlot(id: "s4", poolId: "pool-breda", activityType: .banenzwemmen, date: String(today), startTime: "07:30", endTime: "09:30", notes: "Vroegzwemmen")
        ]
    }
}
