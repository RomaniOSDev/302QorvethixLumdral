import SwiftUI

struct Feature2View: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var packingVM = Feature2ViewModel(kind: .packing)
    @StateObject private var todoVM = Feature2ViewModel(kind: .todo)
    @Binding var segment: ToolsSegment

    var body: some View {
        Group {
            switch segment {
            case .packing:
                organizerContent(viewModel: packingVM)
            case .todo:
                organizerContent(viewModel: todoVM)
            case .clocks:
                Feature3View()
            }
        }
    }

    @ViewBuilder
    private func organizerContent(viewModel: Feature2ViewModel) -> some View {
        let items = viewModel.items
        Group {
                if items.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        EmptyStateView(
                            symbol: "suitcase.fill",
                            message: "Start planning by adding your first item!"
                        )
                        if viewModel.kind == .packing {
                            MetalPanel {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("TEMPLATES")
                                        .font(.system(.caption, design: .monospaced).weight(.bold))
                                        .foregroundStyle(Color("AppAccent"))
                                    ForEach(PackingTemplate.all) { template in
                                        Button {
                                            store.applyPackingTemplate(template)
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: template.icon)
                                                    .foregroundStyle(Color("AppPrimary"))
                                                    .frame(width: 28)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(template.title)
                                                        .foregroundStyle(Color("AppTextPrimary"))
                                                    Text(template.detail)
                                                        .font(.caption)
                                                        .foregroundStyle(Color("AppTextSecondary"))
                                                }
                                                Spacer()
                                            }
                                            .frame(minHeight: 44)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            } else {
                List {
                    ForEach(TripItemCategory.allCases) { category in
                        let sectionItems = items.filter { $0.category == category }
                        if !sectionItems.isEmpty {
                            Section {
                                ForEach(sectionItems) { item in
                                    itemRow(item, viewModel: viewModel)
                                        .listRowBackground(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color("AppSurface"))
                                                .padding(.vertical, 2)
                                        )
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                viewModel.delete(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                                .onMove { source, destination in
                                    moveCategoryItems(
                                        viewModel: viewModel,
                                        category: category,
                                        from: source,
                                        to: destination
                                    )
                                }
                            } header: {
                                Text(category.rawValue.uppercased())
                                    .font(.system(.caption, design: .monospaced).weight(.bold))
                                    .foregroundStyle(Color("AppAccent"))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Trip Organizer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    if viewModel.kind == .packing {
                        Menu {
                            ForEach(PackingTemplate.all) { template in
                                Button {
                                    store.applyPackingTemplate(template)
                                } label: {
                                    Label(template.title, systemImage: template.icon)
                                }
                            }
                        } label: {
                            Image(systemName: "square.stack.3d.up.fill")
                                .foregroundStyle(Color("AppAccent"))
                                .frame(minWidth: 36, minHeight: 44)
                        }
                    }
                    EditButton()
                        .foregroundStyle(Color("AppTextSecondary"))
                    Button {
                        viewModel.openAdd()
                    } label: {
                        Text("Add")
                            .font(.system(.body, design: .monospaced).weight(.bold))
                            .foregroundStyle(Color("AppPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 8)
                            .frame(minHeight: 44)
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showSheet },
            set: { viewModel.showSheet = $0 }
        )) {
            itemForm(viewModel: viewModel)
        }
    }

    private func itemRow(_ item: TripItem, viewModel: Feature2ViewModel) -> some View {
        Button {
            viewModel.toggle(item)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.completed ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(item.completed ? Color("AppPrimary") : Color("AppTextSecondary"))
                    .overlay {
                        if viewModel.completedPulseId == item.id {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AppAccent"))
                                .offset(x: 14, y: -10)
                        }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body)
                        .strikethrough(item.completed)
                        .foregroundStyle(item.completed ? Color("AppTextSecondary") : Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(item.category.rawValue)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                Spacer()
            }
            .padding(.vertical, 4)
            .background(viewModel.completedPulseId == item.id ? Color("AppAccent").opacity(0.25) : Color.clear)
            .animation(.easeInOut(duration: 0.3), value: viewModel.completedPulseId)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }

    private func itemForm(viewModel: Feature2ViewModel) -> some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item name", text: Binding(
                        get: { viewModel.title },
                        set: { viewModel.title = $0 }
                    ))
                    Picker("Category", selection: Binding(
                        get: { viewModel.category },
                        set: { viewModel.category = $0 }
                    )) {
                        ForEach(TripItemCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                if let message = viewModel.validationMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.red)
                }
            }
            .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showSheet = false
                        HapticService.light()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.save() }
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .dismissKeyboardOnTap()
        .presentationDetents([.medium])
    }

    private func moveCategoryItems(
        viewModel: Feature2ViewModel,
        category: TripItemCategory,
        from source: IndexSet,
        to destination: Int
    ) {
        var kindItems = store.items(for: viewModel.kind)
        var categoryItems = kindItems.filter { $0.category == category }
        categoryItems.move(fromOffsets: source, toOffset: destination)

        var rebuilt: [TripItem] = []
        var inserted = false
        for item in kindItems {
            if item.category == category {
                if !inserted {
                    rebuilt.append(contentsOf: categoryItems)
                    inserted = true
                }
            } else {
                rebuilt.append(item)
            }
        }
        if !inserted {
            rebuilt.append(contentsOf: categoryItems)
        }
        for idx in rebuilt.indices {
            rebuilt[idx].sortOrder = idx
        }
        store.replaceKindItems(rebuilt, kind: viewModel.kind)
    }
}

enum ToolsSegment: String, CaseIterable, Identifiable {
    case packing = "Packing"
    case todo = "To-Do"
    case clocks = "Clocks"

    var id: String { rawValue }
}

struct ToolsRootView: View {
    @State private var segment: ToolsSegment = .packing

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tools", selection: $segment) {
                    ForEach(ToolsSegment.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .onChange(of: segment) { _ in
                    HapticService.light()
                    SoundService.tick()
                }

                Feature2View(segment: $segment)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CompassToolbarLabel()
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
