import SwiftUI
import UIKit

enum KeyboardDismiss {
    static func resign() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private final class KeyboardDismissController: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissController()

    private weak var window: UIWindow?
    private var recognizer: UITapGestureRecognizer?
    private weak var trackedFirstResponder: UIResponder?

    func installIfNeeded() {
        guard let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        else { return }

        if window === keyWindow, recognizer != nil { return }

        if let recognizer {
            window?.removeGestureRecognizer(recognizer)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        keyWindow.addGestureRecognizer(tap)
        recognizer = tap
        window = keyWindow
    }

    @objc private func handleTap() {
        KeyboardDismiss.resign()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        UIResponder.keyboardFirstResponder != nil
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard UIResponder.keyboardFirstResponder != nil else { return false }
        var view = touch.view
        while let current = view {
            if current is UINavigationBar || current is UIToolbar || current is UITabBar {
                return false
            }
            let name = NSStringFromClass(type(of: current))
            if name.contains("NavigationBar") || name.contains("Toolbar") {
                return false
            }
            view = current.superview
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

extension UIResponder {
    private static weak var _keyboardFirstResponder: UIResponder?

    static var keyboardFirstResponder: UIResponder? {
        _keyboardFirstResponder = nil
        UIApplication.shared.sendAction(#selector(captureFirstResponder), to: nil, from: nil, for: nil)
        return _keyboardFirstResponder
    }

    @objc private func captureFirstResponder() {
        UIResponder._keyboardFirstResponder = self
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        onAppear {
            KeyboardDismissController.shared.installIfNeeded()
        }
    }
}
