import Foundation
import Combine

final class Feature2ViewModel: ObservableObject {
    @Published var showSheet = false
    @Published var title = ""
    @Published var category: TripItemCategory = .essentials
    @Published var shakeTrigger: CGFloat = 0
    @Published var validationMessage: String?
    @Published var completedPulseId: String?

    private let store: AppDataStore
    let kind: TripItemKind

    init(kind: TripItemKind, store: AppDataStore = .shared) {
        self.kind = kind
        self.store = store
    }

    var items: [TripItem] { store.items(for: kind) }

    func openAdd() {
        title = ""
        category = .essentials
        validationMessage = nil
        showSheet = true
        HapticService.light()
    }

    func save() {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            validationMessage = "Enter an item name."
            shakeTrigger += 1
            HapticService.warning()
            return
        }
        store.addItem(TripItem(title: cleaned, category: category, kind: kind))
        showSheet = false
    }

    func toggle(_ item: TripItem) {
        store.toggleItem(id: item.id)
        if !item.completed {
            completedPulseId = item.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                if self?.completedPulseId == item.id {
                    self?.completedPulseId = nil
                }
            }
        }
    }

    func delete(_ item: TripItem) {
        store.deleteItem(id: item.id)
    }

    func reorder(from source: IndexSet, to destination: Int) {
        store.reorderItems(kind: kind, from: source, to: destination)
    }
}
