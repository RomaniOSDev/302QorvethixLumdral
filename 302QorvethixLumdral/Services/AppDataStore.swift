import Foundation
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var hasSeenOnboarding: Bool
    @Published var trips: [Trip]
    @Published var tripItems: [TripItem]
    @Published var worldClocks: [WorldClockCity]
    @Published var recentCities: [String]
    @Published var preferredTimeFormat: String
    @Published var activeTripId: String?
    @Published var destinationsAdded: Int
    @Published var tripsCompleted: Int
    @Published var checklistsCompleted: Int
    @Published var totalSessionsCompleted: Int
    @Published var totalMinutesUsed: Int
    @Published var streakDays: Int
    @Published var lastActivityDate: Date?
    @Published var achievementsUnlocked: [String: Date]
    @Published var bannerQueue: [AchievementID] = []
    @Published var currentBanner: AchievementID?

    private let defaults = UserDefaults.standard
    private var sessionStartedAt = Date()
    private var isPresentingBanner = false

    private enum Keys {
        static let onboarding = "pf_hasSeenOnboarding"
        static let trips = "pf_trips"
        static let tripItems = "pf_tripItems"
        static let worldClocks = "pf_worldClocks"
        static let recentCities = "pf_recentCities"
        static let timeFormat = "pf_preferredTimeFormat"
        static let activeTripId = "pf_activeTripId"
        static let destinationsAdded = "pf_destinationsAdded"
        static let tripsCompleted = "pf_tripsCompleted"
        static let checklistsCompleted = "pf_checklistsCompleted"
        static let sessions = "pf_totalSessionsCompleted"
        static let minutes = "pf_totalMinutesUsed"
        static let streak = "pf_streakDays"
        static let lastActivity = "pf_lastActivityDate"
        static let achievements = "pf_achievementsUnlocked"
    }

    private init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.onboarding)
        trips = Self.decode([Trip].self, key: Keys.trips) ?? []
        tripItems = Self.decode([TripItem].self, key: Keys.tripItems) ?? []
        worldClocks = Self.decode([WorldClockCity].self, key: Keys.worldClocks) ?? []
        recentCities = Self.decode([String].self, key: Keys.recentCities) ?? []
        preferredTimeFormat = defaults.string(forKey: Keys.timeFormat) ?? "24-hour"
        activeTripId = defaults.string(forKey: Keys.activeTripId)
        destinationsAdded = defaults.integer(forKey: Keys.destinationsAdded)
        tripsCompleted = defaults.integer(forKey: Keys.tripsCompleted)
        checklistsCompleted = defaults.integer(forKey: Keys.checklistsCompleted)
        totalSessionsCompleted = defaults.integer(forKey: Keys.sessions)
        totalMinutesUsed = defaults.integer(forKey: Keys.minutes)
        streakDays = defaults.integer(forKey: Keys.streak)
        if let ts = defaults.object(forKey: Keys.lastActivity) as? TimeInterval {
            lastActivityDate = Date(timeIntervalSince1970: ts)
        } else {
            lastActivityDate = nil
        }
        achievementsUnlocked = Self.decode([String: Date].self, key: Keys.achievements) ?? [:]
        let snapshotTrips = trips
        let snapshotItems = tripItems
        DispatchQueue.global(qos: .utility).async {
            for trip in snapshotTrips {
                let packing = snapshotItems.filter { $0.kind == .packing }
                let incomplete = packing.isEmpty || packing.contains { !$0.completed }
                ReminderService.reschedule(for: trip, packingIncomplete: incomplete)
            }
        }
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Keys.onboarding)
        totalSessionsCompleted += 1
        defaults.set(totalSessionsCompleted, forKey: Keys.sessions)
        recordActivity()
        evaluateAchievements()
    }

    // MARK: - Trips

    var activeTrip: Trip? {
        guard let activeTripId else { return nil }
        return trips.first { $0.id == activeTripId }
    }

    func addTrip(_ trip: Trip) {
        trips.insert(trip, at: 0)
        destinationsAdded += 1
        persistTrips()
        defaults.set(destinationsAdded, forKey: Keys.destinationsAdded)
        recordActivity()
        evaluateAchievements()
        refreshReminder(for: trip)
        HapticService.medium()
        SoundService.tap()
        HapticService.success()
        SoundService.success()
    }

    func updateTrip(_ trip: Trip) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[index] = trip
        persistTrips()
        recordActivity()
        refreshReminder(for: trip)
        HapticService.medium()
        SoundService.tap()
        SoundService.success()
    }

    func markVisited(id: String) {
        guard let index = trips.firstIndex(where: { $0.id == id }) else { return }
        if !trips[index].visited {
            trips[index].visited = true
            tripsCompleted += 1
            defaults.set(tripsCompleted, forKey: Keys.tripsCompleted)
        }
        persistTrips()
        recordActivity()
        evaluateAchievements()
        refreshReminder(for: trips[index])
        HapticService.medium()
        SoundService.success()
    }

    func deleteTrip(id: String) {
        PhotoStorageService.deleteAll(tripId: id)
        ReminderService.cancel(for: id)
        if activeTripId == id {
            setActiveTrip(nil)
        }
        trips.removeAll { $0.id == id }
        persistTrips()
        HapticService.warning()
        SoundService.tick()
    }

    func setActiveTrip(_ id: String?) {
        activeTripId = id
        if let id {
            defaults.set(id, forKey: Keys.activeTripId)
        } else {
            defaults.removeObject(forKey: Keys.activeTripId)
        }
        HapticService.medium()
        SoundService.tick()
    }

    func applyPackingTemplate(_ template: PackingTemplate) {
        var kindItems = items(for: .packing)
        var added = 0
        for entry in template.items {
            let exists = kindItems.contains {
                $0.title.compare(entry.title, options: .caseInsensitive) == .orderedSame
            }
            guard !exists else { continue }
            let item = TripItem(
                title: entry.title,
                category: entry.category,
                kind: .packing,
                sortOrder: (kindItems.map(\.sortOrder).max() ?? -1) + 1
            )
            kindItems.append(item)
            tripItems.append(item)
            added += 1
        }
        guard added > 0 else {
            HapticService.warning()
            return
        }
        persistItems()
        recordActivity()
        if let trip = activeTrip ?? trips.sorted(by: { $0.date < $1.date }).first {
            refreshReminder(for: trip)
        }
        HapticService.success()
        SoundService.success()
    }

    func addPhoto(data: Data, to tripId: String) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else { return }
        guard trips[index].photoFileNames.count < 3 else {
            HapticService.warning()
            return
        }
        guard let fileName = PhotoStorageService.save(data: data, tripId: tripId) else {
            HapticService.warning()
            return
        }
        trips[index].photoFileNames.append(fileName)
        persistTrips()
        HapticService.success()
        SoundService.tap()
    }

    func removePhoto(fileName: String, from tripId: String) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else { return }
        PhotoStorageService.delete(tripId: tripId, fileName: fileName)
        trips[index].photoFileNames.removeAll { $0 == fileName }
        persistTrips()
        HapticService.light()
    }

    func refreshReminder(for trip: Trip) {
        let packing = tripItems.filter { $0.kind == .packing }
        let incomplete = !packing.isEmpty && packing.contains { !$0.completed }
        ReminderService.reschedule(for: trip, packingIncomplete: incomplete || packing.isEmpty)
    }

    // MARK: - Trip Items

    func addItem(_ item: TripItem) {
        var next = item
        let sameKind = tripItems.filter { $0.kind == item.kind }
        next.sortOrder = (sameKind.map(\.sortOrder).max() ?? -1) + 1
        tripItems.append(next)
        persistItems()
        recordActivity()
        HapticService.medium()
        SoundService.tap()
        SoundService.success()
    }

    func toggleItem(id: String) {
        guard let index = tripItems.firstIndex(where: { $0.id == id }) else { return }
        let wasComplete = tripItems[index].completed
        tripItems[index].completed.toggle()
        let kind = tripItems[index].kind
        persistItems()
        if !wasComplete && tripItems[index].completed {
            HapticService.medium()
            SoundService.tap()
            if kind == .packing {
                let packing = tripItems.filter { $0.kind == .packing }
                if !packing.isEmpty && packing.allSatisfy(\.completed) {
                    checklistsCompleted += 1
                    defaults.set(checklistsCompleted, forKey: Keys.checklistsCompleted)
                    evaluateAchievements()
                }
            }
        } else {
            HapticService.light()
        }
        if kind == .packing, let trip = activeTrip ?? trips.first {
            refreshReminder(for: trip)
        }
        recordActivity()
    }

    func deleteItem(id: String) {
        tripItems.removeAll { $0.id == id }
        persistItems()
        HapticService.warning()
        SoundService.tick()
    }

    func reorderItems(kind: TripItemKind, from source: IndexSet, to destination: Int) {
        var ordered = tripItems
            .filter { $0.kind == kind }
            .sorted { $0.sortOrder < $1.sortOrder }
        ordered.move(fromOffsets: source, toOffset: destination)
        for (idx, _) in ordered.enumerated() {
            ordered[idx].sortOrder = idx
        }
        let others = tripItems.filter { $0.kind != kind }
        tripItems = others + ordered
        persistItems()
        HapticService.light()
    }

    func replaceKindItems(_ items: [TripItem], kind: TripItemKind) {
        var rebuilt = items
        for idx in rebuilt.indices {
            rebuilt[idx].sortOrder = idx
            rebuilt[idx].kind = kind
        }
        let others = tripItems.filter { $0.kind != kind }
        tripItems = others + rebuilt
        persistItems()
        HapticService.light()
    }

    func items(for kind: TripItemKind) -> [TripItem] {
        tripItems
            .filter { $0.kind == kind }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - World Clocks

    func addClock(from option: StaticCityOption) {
        guard !worldClocks.contains(where: { $0.name == option.name }) else {
            HapticService.warning()
            return
        }
        let city = WorldClockCity(name: option.name, timezoneOffset: option.timezoneOffset)
        worldClocks.append(city)
        if !recentCities.contains(option.name) {
            recentCities.insert(option.name, at: 0)
            if recentCities.count > 8 {
                recentCities = Array(recentCities.prefix(8))
            }
            persistRecent()
        }
        persistClocks()
        recordActivity()
        evaluateAchievements()
        HapticService.medium()
        SoundService.vibrate()
        SoundService.success()
    }

    func deleteClock(id: String) {
        worldClocks.removeAll { $0.id == id }
        persistClocks()
        HapticService.medium()
        SoundService.vibrate()
    }

    func setTimeFormat(_ format: String) {
        preferredTimeFormat = format
        defaults.set(format, forKey: Keys.timeFormat)
        HapticService.light()
        SoundService.tick()
    }

    // MARK: - Achievements / Stats

    func dismissBanner() {
        currentBanner = nil
        isPresentingBanner = false
        presentNextBanner()
    }

    func flushSessionMinutes() {
        let elapsed = max(0, Int(Date().timeIntervalSince(sessionStartedAt) / 60))
        if elapsed > 0 {
            totalMinutesUsed += elapsed
            defaults.set(totalMinutesUsed, forKey: Keys.minutes)
            sessionStartedAt = Date()
        }
    }

    func resetAllData() {
        flushSessionMinutes()
        trips.forEach { PhotoStorageService.deleteAll(tripId: $0.id) }
        ReminderService.cancelAll()
        trips = []
        tripItems = []
        worldClocks = []
        recentCities = []
        preferredTimeFormat = "24-hour"
        activeTripId = nil
        destinationsAdded = 0
        tripsCompleted = 0
        checklistsCompleted = 0
        totalSessionsCompleted = 0
        totalMinutesUsed = 0
        streakDays = 0
        lastActivityDate = nil
        achievementsUnlocked = [:]
        bannerQueue = []
        currentBanner = nil
        isPresentingBanner = false

        let keys = [
            Keys.trips, Keys.tripItems, Keys.worldClocks, Keys.recentCities,
            Keys.timeFormat, Keys.activeTripId, Keys.destinationsAdded,
            Keys.tripsCompleted, Keys.checklistsCompleted, Keys.sessions,
            Keys.minutes, Keys.streak, Keys.lastActivity, Keys.achievements
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
        defaults.set(hasSeenOnboarding, forKey: Keys.onboarding)
        NotificationCenter.default.post(name: .dataReset, object: nil)
        HapticService.warning()
        SoundService.tick()
    }

    private func recordActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let last = lastActivityDate {
            let lastDay = calendar.startOfDay(for: last)
            let days = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if days == 1 {
                streakDays += 1
            } else if days > 1 {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }
        lastActivityDate = today
        defaults.set(streakDays, forKey: Keys.streak)
        defaults.set(today.timeIntervalSince1970, forKey: Keys.lastActivity)
    }

    private func evaluateAchievements() {
        var newly: [AchievementID] = []
        for achievement in AchievementID.allCases {
            let unlocked = achievement.isUnlocked(
                destinationsAdded: destinationsAdded,
                tripsCompleted: tripsCompleted,
                checklistsCompleted: checklistsCompleted,
                streakDays: streakDays
            )
            if unlocked && achievementsUnlocked[achievement.rawValue] == nil {
                achievementsUnlocked[achievement.rawValue] = Date()
                newly.append(achievement)
            }
        }
        if !newly.isEmpty {
            persistAchievements()
            bannerQueue.append(contentsOf: newly)
            presentNextBanner()
        }
    }

    private func presentNextBanner() {
        guard !isPresentingBanner, let next = bannerQueue.first else { return }
        bannerQueue.removeFirst()
        isPresentingBanner = true
        currentBanner = next
        HapticService.success()
        SoundService.success()
    }

    private func persistTrips() {
        encode(trips, key: Keys.trips)
    }

    private func persistItems() {
        encode(tripItems, key: Keys.tripItems)
    }

    private func persistClocks() {
        encode(worldClocks, key: Keys.worldClocks)
    }

    private func persistRecent() {
        encode(recentCities, key: Keys.recentCities)
    }

    private func persistAchievements() {
        encode(achievementsUnlocked, key: Keys.achievements)
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
