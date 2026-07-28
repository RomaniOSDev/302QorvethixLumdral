import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MetalPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MISSION LOG")
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .foregroundStyle(Color("AppAccent"))
                            HStack {
                                metric("Trips", store.destinationsAdded)
                                metric("Done", store.tripsCompleted)
                                metric("Lists", store.checklistsCompleted)
                                metric("Streak", store.streakDays)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AchievementID.allCases) { achievement in
                            let unlocked = store.achievementsUnlocked[achievement.rawValue] != nil
                            let progress = achievement.progress(
                                destinationsAdded: store.destinationsAdded,
                                tripsCompleted: store.tripsCompleted,
                                checklistsCompleted: store.checklistsCompleted,
                                streakDays: store.streakDays
                            )
                            MetalPanel {
                                VStack(spacing: 10) {
                                    Image(systemName: achievement.iconName)
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundStyle(unlocked ? Color("AppPrimary") : Color("AppTextSecondary"))
                                        .frame(height: 36)
                                    Text(achievement.title)
                                        .font(.system(.subheadline, design: .default).weight(.bold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                    Text(achievement.detail)
                                        .font(.system(.caption2, design: .default))
                                        .foregroundStyle(Color("AppTextSecondary"))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                        .minimumScaleFactor(0.7)
                                    ProgressView(value: progress)
                                        .tint(unlocked ? Color("AppAccent") : Color("AppTextSecondary"))
                                }
                                .frame(maxWidth: .infinity)
                                .opacity(unlocked ? 1 : 0.55)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .screenBackground()
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CompassToolbarLabel()
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func metric(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
            Text(title)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}
