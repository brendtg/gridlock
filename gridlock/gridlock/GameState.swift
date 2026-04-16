import Foundation

struct GameState: Codable, Equatable, Hashable {
    var boards: [SubBoard]           // 9 sub-boards
    var metaStatus: [BoardStatus]    // 9 entries matching boards
    var currentPlayer: Player
    var activeBoards: Set<Int>       // boards current player may play in; empty = all undecided boards
    var variant: GameVariant
    var p1Tokens: TokenBudget
    var p2Tokens: TokenBudget
    var moveCount: Int
    var isGameOver: Bool
    var winner: Player
    var moveHistory: [Move]
    // For extended variants: after a move on a shared edge/intersection, opponent must
    // pick which board to play in (from the routing set). This field holds the pending
    // routing choice set. When non-empty, the current player must submit a "choose board" action.
    var pendingRoutingChoice: Set<Int>

    static func initial(variant: GameVariant) -> GameState {
        let s = GameState(
            boards: Array(repeating: SubBoard(), count: 9),
            metaStatus: Array(repeating: .active, count: 9),
            currentPlayer: .p1,
            activeBoards: [],   // empty = free move (all active boards)
            variant: variant,
            p1Tokens: variant.hasTokenBudget ? .initial : TokenBudget(edgeTokens: 0, intersectionTokens: 0),
            p2Tokens: variant.hasTokenBudget ? .initial : TokenBudget(edgeTokens: 0, intersectionTokens: 0),
            moveCount: 0,
            isGameOver: false,
            winner: .empty,
            moveHistory: [],
            pendingRoutingChoice: []
        )
        return s
    }

    var currentTokens: TokenBudget {
        get { currentPlayer == .p1 ? p1Tokens : p2Tokens }
    }

    mutating func setCurrentTokens(_ t: TokenBudget) {
        if currentPlayer == .p1 { p1Tokens = t } else { p2Tokens = t }
    }

    var activeBoardsForCurrentPlayer: [Int] {
        if activeBoards.isEmpty {
            return (0..<9).filter { metaStatus[$0] == .active }
        }
        return activeBoards.filter { metaStatus[$0] == .active }.sorted()
    }

    // Meta-board win check
    static let metaWinLines: [[Int]] = [
        [0,1,2],[3,4,5],[6,7,8],
        [0,3,6],[1,4,7],[2,5,8],
        [0,4,8],[2,4,6]
    ]

    func checkMetaWin() -> Player {
        for line in GameState.metaWinLines {
            let statuses = line.map { metaStatus[$0] }
            if statuses.allSatisfy({ $0 == .wonP1 }) { return .p1 }
            if statuses.allSatisfy({ $0 == .wonP2 }) { return .p2 }
        }
        return .empty
    }

    var isMetaDraw: Bool {
        guard winner == .empty else { return false }
        return metaStatus.allSatisfy { $0 != .active }
    }
}
