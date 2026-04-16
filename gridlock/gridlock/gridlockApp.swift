import SwiftUI
import GameKit

@main
struct gridlockApp: App {
    @State private var router = AppRouter()
    @State private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomeView(router: router, settings: settings)
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .variantPicker(let mode):
            VariantPickerView(router: router, mode: mode, settings: settings)

        case .difficultyPicker(let variant):
            DifficultyPickerView(router: router, variant: variant, settings: settings)

        case .game(let config):
            GameBoardView(config: config, settings: settings, router: router)

        case .gameOver(let finalState, let config):
            GameOverView(finalState: finalState, config: config, router: router)

        case .howToPlay:
            HowToPlayView()

        case .settings:
            SettingsView(settings: settings)

        case .onlineLobby:
            OnlineLobbyView(router: router)
        }
    }
}
