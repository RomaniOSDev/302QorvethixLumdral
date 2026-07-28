import Foundation

enum AchievementID: String, Codable, CaseIterable, Identifiable {
    case firstStep
    case explorer
    case worldTraveler
    case checklistChampion
    case powerUser
    case activeUser
    case dedicatedUser
    case threeDayStreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstStep: return "First Step"
        case .explorer: return "Explorer"
        case .worldTraveler: return "World Traveler"
        case .checklistChampion: return "Checklist Champion"
        case .powerUser: return "Power User"
        case .activeUser: return "Active User"
        case .dedicatedUser: return "Dedicated User"
        case .threeDayStreak: return "Three-Day Streak"
        }
    }

    var detail: String {
        switch self {
        case .firstStep: return "Added the first destination."
        case .explorer: return "Added ten destinations."
        case .worldTraveler: return "Completed five trips."
        case .checklistChampion: return "Completed ten packing checklists."
        case .powerUser: return "Reached 50 items."
        case .activeUser: return "Completed 10 sessions."
        case .dedicatedUser: return "Completed 50 sessions."
        case .threeDayStreak: return "Used the app 3 days in a row."
        }
    }

    var iconName: String {
        switch self {
        case .firstStep: return "flag.fill"
        case .explorer: return "map.fill"
        case .worldTraveler: return "globe.americas.fill"
        case .checklistChampion: return "checklist"
        case .powerUser: return "bolt.fill"
        case .activeUser: return "figure.walk"
        case .dedicatedUser: return "medal.fill"
        case .threeDayStreak: return "flame.fill"
        }
    }

    func isUnlocked(destinationsAdded: Int, tripsCompleted: Int, checklistsCompleted: Int, streakDays: Int) -> Bool {
        switch self {
        case .firstStep: return destinationsAdded >= 1
        case .explorer: return destinationsAdded >= 10
        case .worldTraveler: return tripsCompleted >= 5
        case .checklistChampion: return checklistsCompleted >= 10
        case .powerUser: return destinationsAdded >= 50
        case .activeUser: return tripsCompleted >= 10
        case .dedicatedUser: return tripsCompleted >= 50
        case .threeDayStreak: return streakDays >= 3
        }
    }

    func progress(destinationsAdded: Int, tripsCompleted: Int, checklistsCompleted: Int, streakDays: Int) -> Double {
        switch self {
        case .firstStep: return min(1, Double(destinationsAdded) / 1)
        case .explorer: return min(1, Double(destinationsAdded) / 10)
        case .worldTraveler: return min(1, Double(tripsCompleted) / 5)
        case .checklistChampion: return min(1, Double(checklistsCompleted) / 10)
        case .powerUser: return min(1, Double(destinationsAdded) / 50)
        case .activeUser: return min(1, Double(tripsCompleted) / 10)
        case .dedicatedUser: return min(1, Double(tripsCompleted) / 50)
        case .threeDayStreak: return min(1, Double(streakDays) / 3)
        }
    }
}
