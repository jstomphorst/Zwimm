import Foundation

public class SwimSchedule {
    
    public init() {}
    
    /// Calculates the distance in kilometers between two GPS coordinates using the Haversine formula.
    public func distance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadiusKm: Double = 6371.0

        let dLat = degreesToRadians(lat2 - lat1)
        let dLon = degreesToRadians(lon2 - lon1)

        let lat1Rad = degreesToRadians(lat1)
        let lat2Rad = degreesToRadians(lat2)

        let a = sin(dLat / 2) * sin(dLat / 2) +
                sin(dLon / 2) * sin(dLon / 2) * cos(lat1Rad) * cos(lat2Rad)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusKm * c
    }

    private func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }

    /// Parses JSON schedule data into ScheduleSlot array
    public func parseScheduleJSON(data: Data) throws -> [ScheduleSlot] {
        let decoder = JSONDecoder()
        return try decoder.decode([ScheduleSlot].self, from: data)
    }

    /// Simple line-based or mock CSV parser for quick ingestion
    public func parseSchedule(data: String) -> [ScheduleSlot] {
        var slots: [ScheduleSlot] = []
        let lines = data.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            // Format example: poolId | Activity | YYYY-MM-DD | HH:mm | HH:mm | Notes
            let parts = trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 5 {
                let poolId = parts[0]
                let activityStr = parts[1]
                let activity = ActivityType(rawValue: activityStr) ?? .overig
                let date = parts[2]
                let startTime = parts[3]
                let endTime = parts[4]
                let notes = parts.count > 5 ? parts[5] : nil
                
                let slot = ScheduleSlot(
                    id: "slot-\(index)",
                    poolId: poolId,
                    activityType: activity,
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    notes: notes
                )
                slots.append(slot)
            }
        }
        return slots
    }

    /// Filters schedule slots based on location, radius, activity type, and date range
    public func filterSlots(
        slots: [ScheduleSlot],
        pools: [Pool],
        userLat: Double,
        userLon: Double,
        maxRadiusKm: Double,
        activityType: ActivityType? = nil,
        startDate: String? = nil,
        endDate: String? = nil
    ) -> [(slot: ScheduleSlot, pool: Pool, distanceKm: Double)] {
        
        let poolDict = Dictionary(uniqueKeysWithValues: pools.map { ($0.id, $0) })
        var results: [(slot: ScheduleSlot, pool: Pool, distanceKm: Double)] = []

        for slot in slots {
            guard let pool = poolDict[slot.poolId] else { continue }
            
            let dist = distance(lat1: userLat, lon1: userLon, lat2: pool.latitude, lon2: pool.longitude)
            if dist > maxRadiusKm { continue }
            
            if let activity = activityType, slot.activityType != activity {
                continue
            }
            
            if let start = startDate, slot.date < start {
                continue
            }
            
            if let end = endDate, slot.date > end {
                continue
            }
            
            results.append((slot: slot, pool: pool, distanceKm: dist))
        }

        // Sort by date, start time, then distance
        results.sort { lhs, rhs in
            if lhs.slot.date != rhs.slot.date {
                return lhs.slot.date < rhs.slot.date
            }
            if lhs.slot.startTime != rhs.slot.startTime {
                return lhs.slot.startTime < rhs.slot.startTime
            }
            return lhs.distanceKm < rhs.distanceKm
        }

        return results
    }
}
