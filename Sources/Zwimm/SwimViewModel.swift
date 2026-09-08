import Foundation

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

@available(macOS 10.15, iOS 13.0, *)
@MainActor
public class SwimViewModel: ObservableObject {
    @Published public var manager: SwimManager
    @Published public var selectedActivity: ActivityType = .banenzwemmen
    @Published public var searchRadiusKm: Double = 15.0
    @Published public var userLatitude: Double = 52.3676 // Default Amsterdam Center
    @Published public var userLongitude: Double = 4.9041
    
    public init(manager: SwimManager = SwimManager()) {
        self.manager = manager
        self.manager.loadMockData()
    }

    public var filteredSessions: [(slot: ScheduleSlot, pool: Pool, distanceKm: Double)] {
        return manager.searchSwimSessions(
            userLat: userLatitude,
            userLon: userLongitude,
            maxRadiusKm: searchRadiusKm,
            activityType: selectedActivity
        )
    }
}
#endif
