import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: AppTab = .journal
    @State private var loadedTabs: Set<AppTab> = [.journal]

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                if loadedTabs.contains(.journal) {
                    tabPage(.journal) { Feature1View() }
                }
                if loadedTabs.contains(.tools) {
                    tabPage(.tools) { ToolsRootView() }
                }
                if loadedTabs.contains(.achievements) {
                    tabPage(.achievements) { AchievementsView() }
                }
                if loadedTabs.contains(.settings) {
                    tabPage(.settings) { SettingsView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 70)

            IndustrialTabBar(selection: $selection)

            if let banner = store.currentBanner {
                AchievementBannerOverlay(achievement: banner) {
                    store.dismissBanner()
                }
                .zIndex(10)
            }
        }
        .dismissKeyboardOnTap()
        .ignoresSafeArea(.keyboard)
        .onChange(of: selection) { tab in
            loadedTabs.insert(tab)
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                store.flushSessionMinutes()
            }
        }
    }

    @ViewBuilder
    private func tabPage<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(selection == tab ? 1 : 0)
            .allowsHitTesting(selection == tab)
            .accessibilityHidden(selection != tab)
            .zIndex(selection == tab ? 1 : 0)
    }
}
