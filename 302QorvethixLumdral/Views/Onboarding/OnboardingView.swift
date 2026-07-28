import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page = 0
    @State private var appeared = false

    private let pages: [(headline: String, detail: String, image: String)] = [
        (
            "Plan Trips Easily",
            "Effortlessly organize your travel plans and keep track of destinations.",
            "bgCompass"
        ),
        (
            "Create Checklists",
            "Simply tap to add items to your packing checklists.",
            "bannerCity"
        ),
        (
            "Start Your Journey",
            "Begin by adding your first destination now.",
            "worldClocks"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text(pages[page].headline.uppercased())
                    .font(.system(.title2, design: .monospaced).weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(.horizontal, 20)
                    .padding(.top, 28)

                Text(pages[page].detail)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(.horizontal, 20)

                Image(pages[page].image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .overlay(
                        Rectangle()
                            .stroke(Color("AppTextSecondary").opacity(0.35), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .id(page)
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                MetalPanel {
                    HStack(spacing: 12) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Rectangle()
                                .fill(index == page ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.3))
                                .frame(height: 3)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer()

            Button {
                HapticService.light()
                SoundService.tick()
                if page < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        page += 1
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        store.completeOnboarding()
                    }
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Get Started")
                    .font(.system(.headline, design: .monospaced).weight(.bold))
                    .foregroundStyle(Color("AppBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color("AppPrimary"))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(color: Color("AppPrimary").opacity(0.35), radius: 10, y: 4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
            .frame(minHeight: 44)
        }
        .screenBackground()
        .onAppear {
            appeared = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        .onChange(of: page) { _ in
            appeared = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}
