import Foundation
import Combine

final class Feature3ViewModel: ObservableObject {
    @Published var showSheet = false
    @Published var searchText = ""

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    var clocks: [WorldClockCity] { store.worldClocks }
    var preferredTimeFormat: String { store.preferredTimeFormat }
    var recentCities: [String] { store.recentCities }

    var filteredOptions: [StaticCityOption] {
        let existing = Set(clocks.map(\.name))
        let base = StaticCityOption.catalog.filter { !existing.contains($0.name) }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func openAdd() {
        searchText = ""
        showSheet = true
        HapticService.light()
    }

    func add(_ option: StaticCityOption) {
        store.addClock(from: option)
        showSheet = false
    }

    func delete(id: String) {
        store.deleteClock(id: id)
    }

    func toggleFormat() {
        let next = preferredTimeFormat == "24-hour" ? "12-hour" : "24-hour"
        store.setTimeFormat(next)
    }

    func formattedTime(date: Date, offsetHours: Double) -> String {
        let seconds = offsetHours * 3600
        let cityDate = date.addingTimeInterval(seconds - TimeInterval(TimeZone.current.secondsFromGMT(for: date)))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = preferredTimeFormat == "12-hour" ? "h:mm:ss a" : "HH:mm:ss"
        return formatter.string(from: cityDate)
    }

    func offsetLabel(_ offset: Double) -> String {
        let sign = offset >= 0 ? "+" : ""
        if offset.truncatingRemainder(dividingBy: 1) == 0 {
            return "UTC\(sign)\(Int(offset))"
        }
        return String(format: "UTC%@%.1f", sign, offset)
    }
}
