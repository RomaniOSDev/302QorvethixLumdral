import Foundation
import Combine
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct PickedImageData: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            PickedImageData(data: data)
        }
    }
}

enum TripStatusFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case visited = "Visited"
    case planned = "Planned"

    var id: String { rawValue }
}

enum JournalRoute: Hashable {
    case timeline
    case activeTrip
}

final class Feature1ViewModel: ObservableObject {
    @Published var showSheet = false
    @Published var editingTrip: Trip?
    @Published var destination = ""
    @Published var country = ""
    @Published var note = ""
    @Published var date = Date()
    @Published var expenses: [TripExpense] = []
    @Published var photoFileNames: [String] = []
    @Published var draftTripId = UUID().uuidString
    @Published var expenseCategory: ExpenseCategory = .food
    @Published var expenseAmount = ""
    @Published var expenseNote = ""
    @Published var shakeTrigger: CGFloat = 0
    @Published var validationMessage: String?
    @Published var searchText = ""
    @Published var statusFilter: TripStatusFilter = .all
    @Published var yearFilter: Int?
    @Published var shareImage: UIImage?
    @Published var showShareSheet = false
    @Published var photoPickerItems: [PhotosPickerItem] = []
    @Published var path = NavigationPath()

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    func openRoute(_ route: JournalRoute) {
        path.append(route)
        HapticService.light()
    }

    var availableYears: [Int] {
        let years = Set(store.trips.map { Calendar.current.component(.year, from: $0.date) })
        return years.sorted(by: >)
    }

    var filteredTrips: [Trip] {
        store.trips.filter { trip in
            let matchesStatus: Bool = {
                switch statusFilter {
                case .all: return true
                case .visited: return trip.visited
                case .planned: return !trip.visited
                }
            }()
            let matchesYear = yearFilter.map { Calendar.current.component(.year, from: trip.date) == $0 } ?? true
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || trip.destination.localizedCaseInsensitiveContains(query)
                || trip.country.localizedCaseInsensitiveContains(query)
                || trip.note.localizedCaseInsensitiveContains(query)
            return matchesStatus && matchesYear && matchesSearch
        }
    }

    func openAdd() {
        editingTrip = nil
        draftTripId = UUID().uuidString
        destination = ""
        country = ""
        note = ""
        date = Date()
        expenses = []
        photoFileNames = []
        expenseAmount = ""
        expenseNote = ""
        validationMessage = nil
        photoPickerItems = []
        showSheet = true
        HapticService.light()
    }

    func openEdit(_ trip: Trip) {
        editingTrip = trip
        draftTripId = trip.id
        destination = trip.destination
        country = trip.country
        note = trip.note
        date = trip.date
        expenses = trip.expenses
        photoFileNames = trip.photoFileNames
        expenseAmount = ""
        expenseNote = ""
        validationMessage = nil
        photoPickerItems = []
        showSheet = true
        HapticService.light()
    }

    func save() {
        let dest = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        let ctry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dest.isEmpty, !ctry.isEmpty else {
            validationMessage = "Destination and country are required."
            shakeTrigger += 1
            HapticService.warning()
            return
        }
        if var existing = editingTrip {
            existing.destination = dest
            existing.country = ctry
            existing.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.date = date
            existing.expenses = expenses
            existing.photoFileNames = photoFileNames
            store.updateTrip(existing)
        } else {
            let trip = Trip(
                id: draftTripId,
                destination: dest,
                country: ctry,
                date: date,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                expenses: expenses,
                photoFileNames: photoFileNames
            )
            store.addTrip(trip)
        }
        showSheet = false
    }

    func addExpense() {
        let cleaned = expenseAmount.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned), amount > 0 else {
            validationMessage = "Enter a valid expense amount."
            shakeTrigger += 1
            HapticService.warning()
            return
        }
        expenses.append(
            TripExpense(
                category: expenseCategory,
                amount: amount,
                note: expenseNote.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        expenseAmount = ""
        expenseNote = ""
        validationMessage = nil
        HapticService.light()
        SoundService.tick()
    }

    func removeExpense(_ expense: TripExpense) {
        expenses.removeAll { $0.id == expense.id }
        HapticService.light()
    }

    func removePhoto(_ fileName: String) {
        PhotoStorageService.delete(tripId: draftTripId, fileName: fileName)
        photoFileNames.removeAll { $0 == fileName }
        if var trip = editingTrip {
            trip.photoFileNames = photoFileNames
            editingTrip = trip
        }
        HapticService.light()
    }

    @MainActor
    func importPickedPhotos() async {
        guard !photoPickerItems.isEmpty else { return }
        for item in photoPickerItems {
            guard photoFileNames.count < 3 else { break }
            if let picked = try? await item.loadTransferable(type: PickedImageData.self),
               let fileName = PhotoStorageService.save(data: picked.data, tripId: draftTripId) {
                photoFileNames.append(fileName)
            }
        }
        photoPickerItems = []
        HapticService.success()
        SoundService.tap()
    }

    func markVisited(_ trip: Trip) {
        store.markVisited(id: trip.id)
    }

    func delete(_ trip: Trip) {
        store.deleteTrip(id: trip.id)
    }

    func setActive(_ trip: Trip) {
        store.setActiveTrip(trip.id)
    }

    @MainActor
    func share(_ trip: Trip) {
        shareImage = TripShareHelper.renderImage(for: trip)
        showShareSheet = shareImage != nil
        if shareImage != nil {
            HapticService.light()
            SoundService.tick()
        }
    }
}
