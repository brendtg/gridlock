import SwiftUI
import Observation

struct DifficultyCardItem: Identifiable {
    let id: Difficulty
    let displayName: String
    let avatarSystemImage: String
    let description: String
    let thinkTimeLabel: String
    var isSelected: Bool
}

@Observable
final class DifficultyPickerViewModel {
    let router: AppRouter
    let variant: GameVariant
    let settings: SettingsStore
    var selectedDifficulty: Difficulty = .medium
    var selectedSide: Player = .p1

    init(router: AppRouter, variant: GameVariant, settings: SettingsStore) {
        self.router = router
        self.variant = variant
        self.settings = settings
    }

    var cards: [DifficultyCardItem] {
        Difficulty.allCases.map { d in
            DifficultyCardItem(
                id: d,
                displayName: d.displayName,
                avatarSystemImage: avatarImage(for: d),
                description: d.description,
                thinkTimeLabel: d.thinkTimeLabel,
                isSelected: selectedDifficulty == d
            )
        }
    }

    private func avatarImage(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy:   return "face.smiling"
        case .medium: return "cpu"
        case .hard:   return "bolt.fill"
        }
    }

    func select(_ difficulty: Difficulty) {
        selectedDifficulty = difficulty
    }

    func start() {
        let config = GameConfig.vsComputer(
            variant: variant,
            difficulty: selectedDifficulty,
            side: selectedSide,
            p1Name: settings.player1Name,
            p2Name: settings.player2Name
        )
        router.push(.game(config: config))
    }
}
