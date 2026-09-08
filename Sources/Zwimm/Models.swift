import Foundation

public enum ActivityType: String, Codable, CaseIterable, Sendable {
    case banenzwemmen = "Banenzwemmen"
    case recreatief = "Recreatief zwemmen"
    case leszwemmen = "Leszwemmen"
    case doelgroep = "Doelgroep"
    case overig = "Overig"
}

public struct Pool: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let address: String
    public let latitude: Double
    public let longitude: Double
    public let website: String?
    public let sourceURL: String?

    public init(id: String, name: String, address: String, latitude: Double, longitude: Double, website: String? = nil, sourceURL: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.website = website
        self.sourceURL = sourceURL
    }
}

public struct ScheduleSlot: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let poolId: String
    public let activityType: ActivityType
    public let date: String // Format: YYYY-MM-DD
    public let startTime: String // Format: HH:mm
    public let endTime: String // Format: HH:mm
    public let notes: String?

    public init(id: String, poolId: String, activityType: ActivityType, date: String, startTime: String, endTime: String, notes: String? = nil) {
        self.id = id
        self.poolId = poolId
        self.activityType = activityType
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }
}
