import SwiftUI
import PhotosUI

struct Feature1View: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = Feature1ViewModel()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            Group {
                if store.trips.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            BannerHeader(
                                imageName: "bannerCity",
                                title: "Trip Journal",
                                subtitle: "LOG // DESTINATIONS"
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            EmptyStateView(symbol: "globe", message: "No trips yet")
                        }
                    }
                } else {
                    List {
                        Section {
                            BannerHeader(
                                imageName: "bannerCity",
                                title: "Trip Journal",
                                subtitle: "LOG // DESTINATIONS"
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                            filterBar
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }

                        if viewModel.filteredTrips.isEmpty {
                            Text("No trips match filters")
                                .font(.footnote)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }

                        ForEach(viewModel.filteredTrips) { trip in
                            tripRow(trip)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .screenBackground()
            .navigationTitle("Trip Journal")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Search destination, country")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Timeline") { viewModel.openRoute(.timeline) }
                        Button("Active Trip") { viewModel.openRoute(.activeTrip) }
                    } label: {
                        Image(systemName: "location.north.line.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color("AppAccent"))
                            .rotationEffect(.degrees(-20))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.openAdd()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color("AppPrimary"))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: JournalRoute.self) { route in
                switch route {
                case .timeline:
                    TripTimelineView()
                case .activeTrip:
                    ActiveTripView()
                }
            }
            .sheet(isPresented: $viewModel.showSheet) {
                tripForm
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let image = viewModel.shareImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Status", selection: $viewModel.statusFilter) {
                ForEach(TripStatusFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if !viewModel.availableYears.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        yearChip(title: "All years", selected: viewModel.yearFilter == nil) {
                            viewModel.yearFilter = nil
                        }
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            yearChip(title: "\(year)", selected: viewModel.yearFilter == year) {
                                viewModel.yearFilter = year
                            }
                        }
                    }
                }
            }
        }
    }

    private func yearChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(selected ? Color("AppBackground") : Color("AppTextSecondary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? Color("AppPrimary") : Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func tripRow(_ trip: Trip) -> some View {
        Button {
            viewModel.openEdit(trip)
        } label: {
            MetalPanel {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(trip.destination.uppercased())
                                .font(.system(.headline, design: .monospaced).weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            if store.activeTripId == trip.id {
                                Text("ACTIVE")
                                    .font(.system(.caption2, design: .monospaced).weight(.bold))
                                    .foregroundStyle(Color("AppBackground"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color("AppAccent"))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        Text(trip.country)
                            .font(.subheadline)
                            .foregroundStyle(Color("AppAccent"))
                        Text(dateFormatter.string(from: trip.date))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color("AppTextSecondary"))
                        if !trip.note.isEmpty {
                            Text(trip.note)
                                .font(.footnote)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .lineLimit(2)
                        }
                        if trip.budgetTotal > 0 {
                            Text(BudgetFormat.string(trip.budgetTotal))
                                .font(.system(.caption2, design: .monospaced).weight(.bold))
                                .foregroundStyle(Color("AppPrimary"))
                        }
                    }
                    Spacer()
                    if trip.visited {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.delete(trip)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            if !trip.visited {
                Button {
                    viewModel.markVisited(trip)
                } label: {
                    Label("Visited", systemImage: "checkmark")
                }
                .tint(Color("AppPrimary"))
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                viewModel.setActive(trip)
            } label: {
                Label("Active", systemImage: "bolt.fill")
            }
            .tint(Color("AppAccent"))
            Button {
                viewModel.share(trip)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(Color("AppPrimary"))
        }
        .contextMenu {
            Button {
                viewModel.setActive(trip)
            } label: {
                Label("Set Active Trip", systemImage: "bolt.fill")
            }
            Button {
                viewModel.share(trip)
            } label: {
                Label("Share Card", systemImage: "square.and.arrow.up")
            }
            if !trip.visited {
                Button {
                    viewModel.markVisited(trip)
                } label: {
                    Label("Mark Visited", systemImage: "checkmark.seal")
                }
            }
        }
    }

    private var tripForm: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    TextField("Destination", text: $viewModel.destination)
                    TextField("Country", text: $viewModel.country)
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    TextField("Note", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Budget") {
                    ForEach(viewModel.expenses) { expense in
                        HStack {
                            Image(systemName: expense.category.icon)
                                .foregroundStyle(Color("AppPrimary"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(expense.category.rawValue)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                if !expense.note.isEmpty {
                                    Text(expense.note)
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            Spacer()
                            Text(BudgetFormat.string(expense.amount))
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .foregroundStyle(Color("AppAccent"))
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.removeExpense(expense)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    Picker("Category", selection: $viewModel.expenseCategory) {
                        ForEach(ExpenseCategory.allCases) { Text($0.rawValue).tag($0) }
                    }
                    TextField("Amount", text: $viewModel.expenseAmount)
                        .keyboardType(.decimalPad)
                    TextField("Expense note", text: $viewModel.expenseNote)
                    Button("Add Expense") {
                        viewModel.addExpense()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                    if !viewModel.expenses.isEmpty {
                        Text("Total \(BudgetFormat.string(viewModel.expenses.reduce(0) { $0 + $1.amount }))")
                            .font(.system(.footnote, design: .monospaced).weight(.bold))
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }

                Section("Photos (max 3)") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.photoFileNames, id: \.self) { name in
                                ZStack(alignment: .topTrailing) {
                                    if let image = PhotoStorageService.load(tripId: viewModel.draftTripId, fileName: name) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 84, height: 84)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                    Button {
                                        viewModel.removePhoto(name)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Color.white, Color.black.opacity(0.7))
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                    if viewModel.photoFileNames.count < 3 {
                        PhotosPicker(
                            selection: $viewModel.photoPickerItems,
                            maxSelectionCount: 3 - viewModel.photoFileNames.count,
                            matching: .images
                        ) {
                            Label("Add Photos", systemImage: "photo.on.rectangle")
                                .foregroundStyle(Color("AppPrimary"))
                        }
                        .onChange(of: viewModel.photoPickerItems) { _ in
                            Task { await viewModel.importPickedPhotos() }
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
            .navigationTitle(viewModel.editingTrip == nil ? "Add Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showSheet = false
                        HapticService.light()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .dismissKeyboardOnTap()
        .presentationDetents([.large])
    }
}
