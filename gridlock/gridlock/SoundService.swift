import AudioToolbox
import Foundation

enum SoundService {
    static func playMove(settings: SettingsStore) {
        guard settings.soundEffectsEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    static func playWin(settings: SettingsStore) {
        guard settings.soundEffectsEnabled else { return }
        AudioServicesPlaySystemSound(1025)
    }

    static func playDraw(settings: SettingsStore) {
        guard settings.soundEffectsEnabled else { return }
        AudioServicesPlaySystemSound(1073)
    }
}
