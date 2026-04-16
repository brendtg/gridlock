import SwiftUI
import Observation

@Observable
final class HomeViewModel {
    let router: AppRouter
    let settings: SettingsStore

    init(router: AppRouter, settings: SettingsStore) {
        self.router = router
        self.settings = settings
    }

    func startVsComputer() {
        router.push(.variantPicker(mode: .vsComputer))
    }

    func startPassAndPlay() {
        router.push(.variantPicker(mode: .passAndPlay))
    }

    func startOnline() {
        router.push(.onlineLobby)
    }

    func openHowToPlay() {
        router.push(.howToPlay)
    }

    func openSettings() {
        router.push(.settings)
    }
}
