import SwiftUI

struct TripTimelineView: View {
    @EnvironmentObject private var store: AppDataStore

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private var ordered: [Trip] {
        store.trips.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            if ordered.isEmpty {
                EmptyStateView(symbol: "timeline.selection", message: "Add trips to build your timeline")
                    .padding(.top, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(ordered.enumerated()), id: \.element.id) { index, trip in
                        timelineRow(trip: trip, isLast: index == ordered.count - 1)
                    }
                }
                .padding(16)
            }
        }
        .screenBackground()
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func timelineRow(trip: Trip, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(trip.visited ? Color("AppPrimary") : Color("AppAccent"))
                    .frame(width: 12, height: 12)
                    .padding(.top, 6)
                if !isLast {
                    Rectangle()
                        .fill(Color("AppTextSecondary").opacity(0.35))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            MetalPanel {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(dateFormatter.string(from: trip.date))
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                        Spacer()
                        if trip.visited {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color("AppPrimary"))
                        }
                    }
                    Text(trip.destination)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(trip.country)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                    if !trip.note.isEmpty {
                        Text(trip.note)
                            .font(.footnote)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(3)
                    }
                    if !trip.photoFileNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(trip.photoFileNames, id: \.self) { name in
                                    if let image = PhotoStorageService.load(tripId: trip.id, fileName: name) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 72, height: 72)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    }
                                }
                            }
                        }
                    }
                    if trip.budgetTotal > 0 {
                        Text(BudgetFormat.string(trip.budgetTotal))
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
        }
        .padding(.bottom, 12)
    }
}
