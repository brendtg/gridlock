import SwiftUI
import Observation

@Observable
final class GameOverViewModel {
    let finalState: GameState
    let config: GameConfig
    let router: AppRouter

    init(finalState: GameState, config: GameConfig, router: AppRouter) {
        self.finalState = finalState
        self.config = config
        self.router = router
    }

    var winnerName: String {
        switch finalState.winner {
        case .p1: return config.playMode == .vsComputer && config.playerSide == .p2 ? config.difficulty.avatarName : config.player1Name
        case .p2: return config.playMode == .vsComputer && config.playerSide == .p1 ? config.difficulty.avatarName : config.player2Name
        case .empty: return "Draw"
        }
    }

    var isDraw: Bool { finalState.winner == .empty }

    func playAgain() {
        let newConfig = config
        router.replace(with: .game(config: newConfig))
    }

    func changeVariant() {
        router.pop()
        router.pop()
        // Navigate back to variant picker by popping to before game
    }

    func mainMenu() {
        router.popToRoot()
    }
}
