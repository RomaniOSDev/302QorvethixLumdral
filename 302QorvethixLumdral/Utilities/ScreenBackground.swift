import SwiftUI

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("bgCompass")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.3)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}
