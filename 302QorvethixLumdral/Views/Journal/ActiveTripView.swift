import SwiftUI

struct ActiveTripView: View {
    @EnvironmentObject private var store: AppDataStore

    private var trip: Trip? { store.activeTrip }

    private var packingItems: [TripItem] {
        store.items(for: .packing).filter { !$0.completed }
    }

    private var destinationClock: StaticCityOption? {
        guard let trip else { return nil }
        let dest = trip.destination.lowercased()
        return StaticCityOption.catalog.first {
            dest.contains($0.name.lowercased()) || $0.name.lowercased().contains(dest)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let trip {
                    activeHeader(trip)
                    packingPanel
                    clockPanel
                    Button {
                        store.setActiveTrip(nil)
                    } label: {
                        Text("End Active Trip")
                            .font(.headline)
                            .foregroundStyle(Color.red.opacity(0.95))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.red.opacity(0.45), lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color("AppSurface"))
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    EmptyStateView(symbol: "airplane.departure", message: "No active trip")
                    Text("Open a trip and choose Set Active.")
                        .font(.footnote)
                        .foregroundStyle(Color("AppTextSecondary"))
                    if !store.trips.isEmpty {
                        MetalPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("QUICK ACTIVATE")
                                    .font(.system(.caption, design: .monospaced).weight(.bold))
                                    .foregroundStyle(Color("AppAccent"))
                                ForEach(store.trips.prefix(5)) { candidate in
                                    Button {
                                        store.setActiveTrip(candidate.id)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(candidate.destination)
                                                    .foregroundStyle(Color("AppTextPrimary"))
                                                Text(candidate.country)
                                                    .font(.caption)
                                                    .foregroundStyle(Color("AppTextSecondary"))
                                            }
                                            Spacer()
                                            Image(systemName: "bolt.fill")
                                                .foregroundStyle(Color("AppPrimary"))
                                        }
                                        .frame(minHeight: 44)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .navigationTitle("Active Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .dismissKeyboardOnTap()
    }

    private func activeHeader(_ trip: Trip) -> some View {
        MetalPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text("NOW TRAVELING")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
                Text(trip.destination.uppercased())
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(trip.country)
                    .foregroundStyle(Color("AppPrimary"))
                if trip.budgetTotal > 0 {
                    Text("Budget \(BudgetFormat.string(trip.budgetTotal))")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }

    private var packingPanel: some View {
        MetalPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("PACKING LEFT")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
                if packingItems.isEmpty {
                    Text("All packed")
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(packingItems.prefix(8)) { item in
                        Button {
                            store.toggleItem(id: item.id)
                        } label: {
                            HStack {
                                Image(systemName: "square")
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Text(item.title)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Spacer()
                            }
                            .frame(minHeight: 40)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var clockPanel: some View {
        MetalPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("LOCAL TIME")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    if let clock = destinationClock {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(clock.name)
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text(formatTime(context.date, offset: clock.timezoneOffset))
                                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                    } else if let first = store.worldClocks.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(first.name)
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text(formatTime(context.date, offset: first.timezoneOffset))
                                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                    } else {
                        Text("Add a world clock or use a known city name.")
                            .font(.footnote)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
            }
        }
    }

    private func formatTime(_ date: Date, offset: Double) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: Int(offset * 3600)) ?? TimeZone(secondsFromGMT: 0)!
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = store.preferredTimeFormat == "12-hour" ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }
}
