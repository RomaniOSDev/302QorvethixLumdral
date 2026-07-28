import Foundation
import UserNotifications

enum ReminderService {
    private static let center = UNUserNotificationCenter.current()

    static func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    static func reschedule(for trip: Trip, packingIncomplete: Bool) {
        cancel(for: trip.id)

        let calendar = Calendar.current
        let startOfTrip = calendar.startOfDay(for: trip.date)

        if let packDay = calendar.date(byAdding: .day, value: -3, to: startOfTrip),
           packDay > Date() {
            var comps = calendar.dateComponents([.year, .month, .day], from: packDay)
            comps.hour = 10
            comps.minute = 0
            schedule(
                id: "pack-\(trip.id)",
                title: "Pack for \(trip.destination)",
                body: "Your trip to \(trip.destination), \(trip.country) is in 3 days.",
                components: comps
            )
        }

        if packingIncomplete,
           let dayBefore = calendar.date(byAdding: .day, value: -1, to: startOfTrip),
           dayBefore > Date() {
            var comps = calendar.dateComponents([.year, .month, .day], from: dayBefore)
            comps.hour = 18
            comps.minute = 0
            schedule(
                id: "checklist-\(trip.id)",
                title: "Checklist still open",
                body: "Finish packing before \(trip.destination).",
                components: comps
            )
        }
    }

    static func cancel(for tripId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [
            "pack-\(tripId)",
            "checklist-\(tripId)"
        ])
    }

    static func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    private static func schedule(
        id: String,
        title: String,
        body: String,
        components: DateComponents
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = SoundService.isEnabled ? .default : nil

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}
