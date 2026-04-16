import Foundation

actor AIPlayer {
    static let shared = AIPlayer()

    func bestMove(for state: GameState, difficulty: Difficulty) async -> Move {
        // Artificial delay so UI feels responsive/realistic
        let delayMs: UInt64
        switch difficulty {
        case .easy:   delayMs = 400
        case .medium: delayMs = 800
        case .hard:   delayMs = 1000
        }
        // Compute move (CPU-bound, runs on actor's executor = non-main thread)
        let move = computeMove(for: state, difficulty: difficulty)
        // Apply delay after computing so UI sees thinking indicator
        try? await Task.sleep(nanoseconds: delayMs * 1_000_000)
        return move
    }

    private func computeMove(for state: GameState, difficulty: Difficulty) -> Move {
        switch difficulty {
        case .easy:
            return RandomAI.move(for: state)

        case .medium:
            let iterations = state.variant.isExtended ? 40 : 80
            return MCTSAI.move(for: state, iterations: iterations)

        case .hard:
            // Try minimax for classic, MCTS with higher iterations otherwise
            if !state.variant.isExtended {
                // Use MCTS first for speed, fallback to minimax for classic
                let mctsMove = MCTSAI.move(for: state, iterations: 300)
                // Also run minimax depth 3 and pick best
                let mmMove = MinimaxAI.move(for: state, depth: 3)
                // Prefer minimax for classic (stronger at depth)
                return mmMove
            } else {
                return MCTSAI.move(for: state, iterations: 100)
            }
        }
    }
}
