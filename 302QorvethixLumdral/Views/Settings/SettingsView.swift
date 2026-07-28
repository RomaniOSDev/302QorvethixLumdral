import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetAlert = false
    @State private var soundEnabled = SoundService.isEnabled
    @State private var hapticEnabled = HapticService.isEnabled

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NavigationLink {
                        StatisticsView()
                    } label: {
                        MetalPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("STATS")
                                        .font(.system(.caption, design: .monospaced).weight(.bold))
                                        .foregroundStyle(Color("AppAccent"))
                                    Spacer()
                                    Text("Charts")
                                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                                        .foregroundStyle(Color("AppPrimary"))
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                                HStack {
                                    statChip("Trips", store.destinationsAdded)
                                    statChip("Visited", store.tripsCompleted)
                                    statChip("Lists", store.checklistsCompleted)
                                }
                                HStack {
                                    statChip("Sessions", store.totalSessionsCompleted)
                                    statChip("Minutes", store.totalMinutesUsed)
                                    statChip("Streak", store.streakDays)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    MetalPanel {
                        VStack(spacing: 0) {
                            if SoundService.isAvailable {
                                settingsToggle(
                                    title: "Sound",
                                    systemImage: "speaker.wave.2.fill",
                                    isOn: $soundEnabled
                                ) { value in
                                    SoundService.isEnabled = value
                                    if value { SoundService.tick() }
                                }
                                Divider().background(Color("AppTextSecondary").opacity(0.25))
                            }
                            settingsToggle(
                                title: "Haptic Feedback",
                                systemImage: "waveform",
                                isOn: $hapticEnabled
                            ) { value in
                                HapticService.isEnabled = value
                                if value { HapticService.light() }
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    MetalPanel {
                        VStack(spacing: 0) {
                            settingsButton(title: "Rate Us", systemImage: "star.fill") {
                                rateApp()
                            }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            settingsButton(title: "Privacy Policy", systemImage: "hand.raised.fill") {
                                openURL(AppLinks.privacyPolicy)
                            }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            settingsButton(title: "Terms of Use", systemImage: "doc.text.fill") {
                                openURL(AppLinks.termsOfUse)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    Button {
                        HapticService.warning()
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset All Data")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundStyle(Color.red.opacity(0.95))
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color("AppSurface"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color.red.opacity(0.45), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CompassToolbarLabel()
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAllData()
                }
            } message: {
                Text("This clears all locally stored data on this device.")
            }
        }
    }

    private func statChip(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.headline, design: .monospaced).weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
            Text(title)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color("AppBackground").opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func settingsToggle(
        title: String,
        systemImage: String,
        isOn: Binding<Bool>,
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(isOn: Binding(
            get: { isOn.wrappedValue },
            set: { newValue in
                isOn.wrappedValue = newValue
                onChange(newValue)
            }
        )) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color("AppPrimary"))
                    .frame(width: 28)
                Text(title)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .tint(Color("AppPrimary"))
        .frame(minHeight: 44)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private func settingsButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.light()
            SoundService.tick()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color("AppPrimary"))
                    .frame(width: 28)
                Text(title)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(minHeight: 44)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
