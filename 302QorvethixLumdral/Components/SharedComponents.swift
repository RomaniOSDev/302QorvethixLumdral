import SwiftUI

struct MetalPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color("AppSurface"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color("AppTextSecondary").opacity(0.45),
                                        Color("AppBackground").opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 8, y: 4)
            )
    }
}

struct BannerHeader: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color("AppBackground").opacity(0.15),
                            Color("AppBackground").opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .default).weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(subtitle)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color("AppAccent"))
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color("AppTextSecondary").opacity(0.35), lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    let symbol: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color("AppAccent"))
                .shadow(color: Color("AppPrimary").opacity(0.4), radius: 8, y: 2)
            Text(message)
                .font(.system(.body, design: .default).weight(.medium))
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct AchievementBannerOverlay: View {
    let achievement: AchievementID
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: achievement.iconName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppBackground"))
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("AppPrimary"))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("ACHIEVEMENT")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                    Text(achievement.title)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("AppSurface"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color("AppPrimary"), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 12, y: 6)
            )
            .padding(.horizontal, 16)
            .padding(.top, 10)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) { onDismiss() }
            }
        }
    }
}

enum AppTab: Int, CaseIterable, Identifiable {
    case journal
    case tools
    case achievements
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .journal: return "Journal"
        case .tools: return "Tools"
        case .achievements: return "Badges"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .journal: return "book.closed.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .achievements: return "seal.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct IndustrialTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        selection = tab
                    }
                    HapticService.light()
                    SoundService.tick()
                } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 15, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(selection == tab ? Color("AppBackground") : Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(selection == tab ? Color("AppPrimary") : Color.clear)
                        )
                        .scaleEffect(selection == tab ? 0.95 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color("AppSurface"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color("AppTextSecondary").opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 10, y: -2)
            )
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(
            Color("AppSurface")
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct CompassToolbarLabel: View {
    var body: some View {
        Image(systemName: "location.north.line.fill")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color("AppAccent"))
            .rotationEffect(.degrees(-20))
    }
}
