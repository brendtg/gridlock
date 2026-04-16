import UIKit

@MainActor
enum HapticService {
    static func confirmMove(settings: SettingsStore) {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func gameOver(win: Bool, settings: SettingsStore) {
        guard settings.hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(win ? .success : .warning)
    }

    static func tap(settings: SettingsStore) {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
