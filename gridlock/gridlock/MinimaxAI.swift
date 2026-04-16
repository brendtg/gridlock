import Foundation

enum MinimaxAI {
    static func move(for state: GameState, depth: Int) -> Move {
        let moves = GameEngine.legalMoves(in: state)
        guard !moves.isEmpty else { fatalError("MinimaxAI: no legal moves") }
        let maximizingPlayer = state.currentPlayer
        var bestMove = moves[0]
        var bestScore = Int.min
        for m in moves {
            let newState = GameEngine.apply(m, to: state)
            let score = minimax(newState, depth: depth - 1, alpha: Int.min, beta: Int.max,
                                maximizing: newState.currentPlayer == maximizingPlayer,
                                rootPlayer: maximizingPlayer)
            if score > bestScore {
                bestScore = score
                bestMove = m
            }
        }
        return bestMove
    }

    private static func minimax(_ state: GameState, depth: Int, alpha: Int, beta: Int,
                                 maximizing: Bool, rootPlayer: Player) -> Int {
        if state.isGameOver {
            if state.winner == rootPlayer { return 10000 }
            if state.winner == rootPlayer.opponent { return -10000 }
            return 0
        }
        if depth == 0 {
            return GameEngine.heuristicScore(state, for: rootPlayer)
        }
        let moves = GameEngine.legalMoves(in: state)
        if moves.isEmpty { return GameEngine.heuristicScore(state, for: rootPlayer) }

        var alpha = alpha
        var beta = beta

        if maximizing {
            var value = Int.min
            for m in moves {
                let newState = GameEngine.apply(m, to: state)
                let childMaximizing = newState.currentPlayer == rootPlayer
                value = max(value, minimax(newState, depth: depth - 1, alpha: alpha, beta: beta,
                                           maximizing: childMaximizing, rootPlayer: rootPlayer))
                alpha = max(alpha, value)
                if beta <= alpha { break }
            }
            return value
        } else {
            var value = Int.max
            for m in moves {
                let newState = GameEngine.apply(m, to: state)
                let childMaximizing = newState.currentPlayer == rootPlayer
                value = min(value, minimax(newState, depth: depth - 1, alpha: alpha, beta: beta,
                                           maximizing: childMaximizing, rootPlayer: rootPlayer))
                beta = min(beta, value)
                if beta <= alpha { break }
            }
            return value
        }
    }
}
