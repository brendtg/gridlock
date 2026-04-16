import Foundation

final class MCTSNode {
    let state: GameState
    let move: Move?
    weak var parent: MCTSNode?
    var children: [MCTSNode] = []
    var visits: Int = 0
    var wins: Double = 0.0
    var untriedMoves: [Move]

    init(state: GameState, move: Move? = nil, parent: MCTSNode? = nil) {
        self.state = state
        self.move = move
        self.parent = parent
        self.untriedMoves = GameEngine.legalMoves(in: state)
    }

    var isFullyExpanded: Bool { untriedMoves.isEmpty }
    var isTerminal: Bool { state.isGameOver }

    func uctScore(explorationConstant c: Double = 1.4142135) -> Double {
        guard visits > 0, let p = parent, p.visits > 0 else { return Double.infinity }
        return (wins / Double(visits)) + c * sqrt(log(Double(p.visits)) / Double(visits))
    }

    func bestChild(c: Double = 1.4142135) -> MCTSNode? {
        children.max(by: { $0.uctScore(explorationConstant: c) < $1.uctScore(explorationConstant: c) })
    }

    func mostVisitedChild() -> MCTSNode? {
        children.max(by: { $0.visits < $1.visits })
    }
}

enum MCTSAI {
    static func move(for state: GameState, iterations: Int) -> Move {
        let root = MCTSNode(state: state)
        let rootPlayer = state.currentPlayer

        for _ in 0..<iterations {
            var node = root
            var currentState = state

            // Selection
            while !node.isTerminal && node.isFullyExpanded {
                guard let child = node.bestChild() else { break }
                node = child
                currentState = child.state
            }

            // Expansion
            if !node.isTerminal && !node.untriedMoves.isEmpty {
                let moveIdx = Int.random(in: 0..<node.untriedMoves.count)
                let m = node.untriedMoves.remove(at: moveIdx)
                let newState = GameEngine.apply(m, to: currentState)
                let child = MCTSNode(state: newState, move: m, parent: node)
                node.children.append(child)
                node = child
                currentState = newState
            }

            // Rollout
            let result = rollout(from: currentState, cap: 20)

            // Backpropagation
            var backNode: MCTSNode? = node
            while let n = backNode {
                n.visits += 1
                if result == rootPlayer {
                    n.wins += 1.0
                } else if result == .empty {
                    n.wins += 0.5
                }
                backNode = n.parent
            }
        }

        return root.mostVisitedChild()?.move ?? GameEngine.legalMoves(in: state).randomElement()!
    }

    private static func rollout(from state: GameState, cap: Int) -> Player {
        var s = state
        var steps = 0
        while !s.isGameOver && steps < cap {
            let moves = GameEngine.legalMoves(in: s)
            guard let m = moves.randomElement() else { break }
            s = GameEngine.apply(m, to: s)
            steps += 1
        }
        if s.isGameOver { return s.winner }
        // Use heuristic tiebreak: board count advantage
        let p1Boards = s.metaStatus.filter { $0 == .wonP1 }.count
        let p2Boards = s.metaStatus.filter { $0 == .wonP2 }.count
        if p1Boards > p2Boards { return .p1 }
        if p2Boards > p1Boards { return .p2 }
        return .empty
    }
}
