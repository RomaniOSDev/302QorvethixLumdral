import AudioToolbox
import Foundation

enum SoundService {
    /// System sounds are used throughout the app; hide Settings toggle when false.
    static let isAvailable = true

    private static let key = "pf_soundEnabled"

    static var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: key) == nil { return true }
            return UserDefaults.standard.bool(forKey: key)
        }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func tap() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    static func tick() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1003)
    }

    static func success() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }

    static func vibrate() {
        guard HapticService.isEnabled else { return }
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
