import SwiftUI

struct Feature3View: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = Feature3ViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        Group {
            if store.worldClocks.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        BannerHeader(
                            imageName: "worldClocks",
                            title: "World Clocks",
                            subtitle: "TIME // GRID"
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        EmptyStateView(symbol: "globe", message: "No clocks added yet")
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        BannerHeader(
                            imageName: "worldClocks",
                            title: "World Clocks",
                            subtitle: "TIME // GRID"
                        )

                        HStack {
                            Text(store.preferredTimeFormat.uppercased())
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Spacer()
                            Button {
                                viewModel.toggleFormat()
                            } label: {
                                Text("12 / 24")
                                    .font(.system(.caption, design: .monospaced).weight(.bold))
                                    .foregroundStyle(Color("AppBackground"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color("AppPrimary"))
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .frame(minHeight: 44)
                        }

                        if scenePhase == .active {
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                clockGrid(date: context.date)
                            }
                        } else {
                            clockGrid(date: Date())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("World Clocks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.openAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color("AppPrimary"))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .sheet(isPresented: $viewModel.showSheet) {
            addCitySheet
        }
    }

    private func clockGrid(date: Date) -> some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(store.worldClocks) { city in
                MetalPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(city.name.uppercased())
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(viewModel.formattedTime(date: date, offsetHours: city.timezoneOffset))
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text(viewModel.offsetLabel(city.timezoneOffset))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.delete(id: city.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.worldClocks.map(\.id))
    }

    private var addCitySheet: some View {
        NavigationStack {
            List {
                if !store.recentCities.isEmpty {
                    Section("Recent") {
                        ForEach(store.recentCities, id: \.self) { name in
                            if let option = StaticCityOption.catalog.first(where: { $0.name == name }),
                               !store.worldClocks.contains(where: { $0.name == name }) {
                                Button {
                                    viewModel.add(option)
                                } label: {
                                    cityRow(option)
                                }
                            }
                        }
                    }
                }
                Section("Cities") {
                    ForEach(viewModel.filteredOptions) { option in
                        Button {
                            viewModel.add(option)
                        } label: {
                            cityRow(option)
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search cities")
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.showSheet = false
                        HapticService.light()
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .dismissKeyboardOnTap()
    }

    private func cityRow(_ option: StaticCityOption) -> some View {
        HStack {
            Text(option.name)
                .foregroundStyle(Color("AppTextPrimary"))
            Spacer()
            Text(viewModel.offsetLabel(option.timezoneOffset))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(minHeight: 44)
    }
}
