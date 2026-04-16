import Foundation

enum RandomAI {
    static func move(for state: GameState) -> Move {
        let moves = GameEngine.legalMoves(in: state)
        guard !moves.isEmpty else { fatalError("RandomAI called with no legal moves") }
        return moves.randomElement()!
    }
}
