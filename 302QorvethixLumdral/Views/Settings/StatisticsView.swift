import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                overviewPanel
                tripStatusChart
                tripsByMonthChart
                countriesChart
                checklistChart
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var overviewPanel: some View {
        MetalPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("OVERVIEW")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    statChip("Trips", store.destinationsAdded)
                    statChip("Visited", store.tripsCompleted)
                    statChip("Lists", store.checklistsCompleted)
                    statChip("Sessions", store.totalSessionsCompleted)
                    statChip("Minutes", store.totalMinutesUsed)
                    statChip("Streak", store.streakDays)
                }
            }
        }
    }

    private var tripStatusChart: some View {
        let visited = store.trips.filter(\.visited).count
        let planned = max(0, store.trips.count - visited)
        let slices: [StatusPoint] = [
            StatusPoint(label: "Visited", value: visited),
            StatusPoint(label: "Planned", value: planned)
        ].filter { $0.value > 0 }

        return MetalPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("TRIP STATUS")
                if slices.isEmpty {
                    emptyChartHint("Add trips to see status")
                } else {
                    Chart(slices) { slice in
                        BarMark(
                            x: .value("Count", slice.value),
                            y: .value("Status", slice.label)
                        )
                        .foregroundStyle(slice.label == "Visited" ? Color("AppPrimary") : Color("AppAccent"))
                        .cornerRadius(3)
                    }
                    .frame(height: 120)
                }
            }
        }
    }

    private var tripsByMonthChart: some View {
        let points = monthlyTripCounts()
        return MetalPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("TRIPS BY MONTH")
                if points.allSatisfy({ $0.count == 0 }) {
                    emptyChartHint("No trips in the last 6 months")
                } else {
                    Chart(points) { point in
                        BarMark(
                            x: .value("Month", point.label),
                            y: .value("Trips", point.count)
                        )
                        .foregroundStyle(Color("AppPrimary"))
                        .cornerRadius(3)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private var countriesChart: some View {
        let points = topCountries()
        return MetalPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("TOP COUNTRIES")
                if points.isEmpty {
                    emptyChartHint("Countries appear after you add trips")
                } else {
                    Chart(points) { point in
                        BarMark(
                            x: .value("Trips", point.count),
                            y: .value("Country", point.label)
                        )
                        .foregroundStyle(Color("AppAccent"))
                        .cornerRadius(3)
                    }
                    .frame(height: CGFloat(max(140, points.count * 36)))
                }
            }
        }
    }

    private var checklistChart: some View {
        let packing = store.tripItems.filter { $0.kind == .packing }
        let todos = store.tripItems.filter { $0.kind == .todo }
        let rows: [(label: String, done: Int, total: Int)] = [
            ("Packing", packing.filter(\.completed).count, packing.count),
            ("To-Do", todos.filter(\.completed).count, todos.count)
        ]

        return MetalPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("CHECKLISTS")
                if rows.allSatisfy({ $0.total == 0 }) {
                    emptyChartHint("Packing and to-do items will show here")
                } else {
                    Chart {
                        ForEach(rows, id: \.label) { row in
                            BarMark(
                                x: .value("Done", row.done),
                                y: .value("List", row.label)
                            )
                            .foregroundStyle(Color("AppPrimary"))
                            .cornerRadius(3)

                            BarMark(
                                x: .value("Remaining", max(0, row.total - row.done)),
                                y: .value("List", row.label)
                            )
                            .foregroundStyle(Color("AppTextSecondary").opacity(0.35))
                            .cornerRadius(3)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom)
                    }
                    .frame(height: 140)
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .monospaced).weight(.bold))
            .foregroundStyle(Color("AppAccent"))
    }

    private func emptyChartHint(_ text: String) -> some View {
        Text(text)
            .font(.system(.footnote, design: .default))
            .foregroundStyle(Color("AppTextSecondary"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 24)
    }

    private func statChip(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.headline, design: .monospaced).weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
            Text(title)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color("AppBackground").opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func monthlyTripCounts() -> [MonthPoint] {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return (0..<6).reversed().compactMap { offset -> MonthPoint? in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: now) else { return nil }
            let comps = calendar.dateComponents([.year, .month], from: date)
            let count = store.trips.filter {
                let c = calendar.dateComponents([.year, .month], from: $0.date)
                return c.year == comps.year && c.month == comps.month
            }.count
            return MonthPoint(id: "\(comps.year!)-\(comps.month!)", label: formatter.string(from: date), count: count)
        }
    }

    private func topCountries() -> [CountryPoint] {
        let grouped = Dictionary(grouping: store.trips) { trip in
            let name = trip.country.trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? "Unknown" : name
        }
        return grouped
            .map { CountryPoint(id: $0.key, label: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }
}

private struct MonthPoint: Identifiable {
    let id: String
    let label: String
    let count: Int
}

private struct CountryPoint: Identifiable {
    let id: String
    let label: String
    let count: Int
}

private struct StatusPoint: Identifiable {
    var id: String { label }
    let label: String
    let value: Int
}
