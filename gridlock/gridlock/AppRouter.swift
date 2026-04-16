import SwiftUI
import Observation

enum AppRoute: Hashable {
    case variantPicker(mode: RouteMode)
    case difficultyPicker(variant: GameVariant)
    case game(config: GameConfig)
    case gameOver(finalState: GameState, config: GameConfig)
    case howToPlay
    case settings
    case onlineLobby
}

enum RouteMode: Hashable {
    case vsComputer
    case passAndPlay
    case online
}

struct GameConfig: Hashable, Codable {
    var variant: GameVariant
    var playMode: GameConfigMode
    var playerSide: Player       // for vsComputer: which side is human
    var difficulty: Difficulty
    var player1Name: String
    var player2Name: String

    static func vsComputer(variant: GameVariant, difficulty: Difficulty, side: Player, p1Name: String, p2Name: String) -> GameConfig {
        GameConfig(variant: variant, playMode: .vsComputer, playerSide: side, difficulty: difficulty, player1Name: p1Name, player2Name: p2Name)
    }
    static func passAndPlay(variant: GameVariant, p1Name: String, p2Name: String) -> GameConfig {
        GameConfig(variant: variant, playMode: .passAndPlay, playerSide: .p1, difficulty: .medium, player1Name: p1Name, player2Name: p2Name)
    }
    static func online(variant: GameVariant) -> GameConfig {
        GameConfig(variant: variant, playMode: .online, playerSide: .p1, difficulty: .medium, player1Name: "You", player2Name: "Opponent")
    }
}

enum GameConfigMode: Hashable, Codable {
    case vsComputer
    case passAndPlay
    case online
}

@Observable
final class AppRouter {
    var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty { path.removeLast() }
    }

    func popToRoot() {
        path.removeAll()
    }

    func replace(with route: AppRoute) {
        if !path.isEmpty { path.removeLast() }
        path.append(route)
    }
}
