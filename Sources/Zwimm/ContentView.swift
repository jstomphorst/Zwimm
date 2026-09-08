import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14.0, macOS 11.0, *)
public struct ContentView: View {
    @StateObject private var viewModel = SwimViewModel()

    public init() {}

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Controls Header
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Activiteit", selection: $viewModel.selectedActivity) {
                        ForEach(ActivityType.allCases, id: \.self) { activity in
                            Text(activity.rawValue).tag(activity)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    HStack {
                        Text("Straal: \(Int(viewModel.searchRadiusKm)) km")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Slider(value: $viewModel.searchRadiusKm, in: 5...50, step: 5)
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(radius: 1)

                // Sessions List
                List {
                    Section(header: Text("Beschikbare Zwemsessies (\(viewModel.filteredSessions.count))")) {
                        if viewModel.filteredSessions.isEmpty {
                            Text("Geen zwemsessies gevonden binnen \(Int(viewModel.searchRadiusKm)) km voor deze activiteit.")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.filteredSessions, id: \.slot.id) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.pool.name)
                                            .font(.headline)
                                        Spacer()
                                        Text(String(format: "%.1f km", item.distanceKm))
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text(item.pool.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Image(systemName: "clock")
                                        Text("\(item.slot.startTime) - \(item.slot.endTime)")
                                            .bold()
                                        Spacer()
                                        Text(item.slot.date)
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.subheadline)
                                    .padding(.top, 2)
                                    
                                    if let notes = item.slot.notes, !notes.isEmpty {
                                        Text("💡 \(notes)")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .padding(.top, 2)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("🏊‍♂️ Zwimm")
        }
    }
}
#endif
