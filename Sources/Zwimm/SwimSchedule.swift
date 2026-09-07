// Sources/Zwimm/SwimSchedule.swift
import Foundation

class SwimSchedule {
    func parseSchedule(data: String) -> [String] {
        // Basic parser - would be expanded with real logic
        return data.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
}
