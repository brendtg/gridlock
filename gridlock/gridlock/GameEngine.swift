import Foundation

enum GameEngine {

    // MARK: - Legal Moves

    static func legalMoves(in state: GameState) -> [Move] {
        guard !state.isGameOver else { return [] }
        var moves: [Move] = []
        let boards = state.activeBoardsForCurrentPlayer
        let tokens = state.currentTokens

        for boardIdx in boards {
            let board = state.boards[boardIdx]
            // Cells
            for (i, occ) in board.cells.enumerated() where occ == .empty {
                moves.append(Move(boardIndex: boardIdx, posType: .cell, posIndex: i))
            }
            guard state.variant.isExtended else { continue }
            // Edges (require edge token if token-budget variant)
            if !state.variant.hasTokenBudget || tokens.hasEdgeTokens {
                for (i, occ) in board.edges.enumerated() where occ == .empty {
                    moves.append(Move(boardIndex: boardIdx, posType: .edge, posIndex: i))
                }
            }
            // Intersections (require intersection token)
            if !state.variant.hasTokenBudget || tokens.hasIntersectionTokens {
                for (i, occ) in board.intersections.enumerated() where occ == .empty {
                    moves.append(Move(boardIndex: boardIdx, posType: .intersection, posIndex: i))
                }
            }
        }
        return moves
    }

    // MARK: - Apply Move

    static func apply(_ move: Move, to state: GameState) -> GameState {
        var s = state
        s.moveHistory.append(move)
        s.moveCount += 1

        // Place piece
        s.boards[move.boardIndex].setOccupant(s.currentPlayer, posType: move.posType, posIndex: move.posIndex)

        // Spend token if needed
        if s.variant.hasTokenBudget {
            var tokens = s.currentTokens
            switch move.posType {
            case .edge: tokens.edgeTokens -= 1
            case .intersection: tokens.intersectionTokens -= 1
            case .cell: break
            }
            s.setCurrentTokens(tokens)
        }

        // Apply meta-blocking (V2 family): placing on an edge blocks an adjacent board's long win line
        if s.variant.hasBlocking && move.posType == .edge {
            applyBlocking(move: move, to: &s)
        }

        // Update sub-board status
        let newStatus = s.boards[move.boardIndex].computeStatus(variant: s.variant)
        s.boards[move.boardIndex].status = newStatus
        s.metaStatus[move.boardIndex] = newStatus

        // Check meta win
        let metaWinner = s.checkMetaWin()
        if metaWinner != .empty {
            s.isGameOver = true
            s.winner = metaWinner
            s.currentPlayer = metaWinner
            return s
        }
        if s.isMetaDraw {
            s.isGameOver = true
            s.winner = .empty
            return s
        }

        // Compute routing for next player
        s.currentPlayer = s.currentPlayer.opponent
        s.activeBoards = computeNextActiveBoards(after: move, in: s)

        return s
    }

    // MARK: - Routing

    static func computeNextActiveBoards(after move: Move, in state: GameState) -> Set<Int> {
        // For classic: cell index directly maps to board index
        // For extended: edge routes to 2 boards, intersection to 3
        var candidates: Set<Int>

        switch move.posType {
        case .cell:
            candidates = [move.posIndex]
        case .edge:
            // Edge routing: which boards share this edge?
            candidates = edgeRoutingBoards(boardIndex: move.boardIndex, edgeIndex: move.posIndex)
        case .intersection:
            candidates = intersectionRoutingBoards(boardIndex: move.boardIndex, intersectionIndex: move.posIndex)
        }

        // Filter out decided boards; if all decided, free move
        var open = candidates.filter { state.metaStatus[$0] == .active }

        if open.isEmpty {
            if state.variant.hasBounce {
                // Bounce to nearest open board
                if let bounce = bounceTarget(from: move.boardIndex, in: state) {
                    open = [bounce]
                } else {
                    open = Set((0..<9).filter { state.metaStatus[$0] == .active })
                }
            } else {
                open = Set((0..<9).filter { state.metaStatus[$0] == .active })
            }
        }

        return open.count == 9 ? [] : open  // empty = free move
    }

    // MARK: - Edge routing tables
    // Board layout (3x3 meta-grid, 0-indexed row-major):
    //   0 1 2
    //   3 4 5
    //   6 7 8
    //
    // Edge index within a sub-board:
    //   0,1,2 = top edge (left-to-right)
    //   3,4,5 = right edge (top-to-bottom)
    //   6,7,8 = bottom edge (left-to-right)
    //   9,10,11 = left edge (top-to-bottom)
    //
    // An edge at position e of board b routes to: b AND the adjacent board across that edge

    static func edgeRoutingBoards(boardIndex b: Int, edgeIndex e: Int) -> Set<Int> {
        let row = b / 3, col = b % 3
        switch e {
        case 0,1,2: // top edge → adjacent board above
            let above = row > 0 ? (row-1)*3 + col : b
            return above == b ? [b] : [b, above]
        case 3,4,5: // right edge → adjacent board to right
            let right = col < 2 ? row*3 + (col+1) : b
            return right == b ? [b] : [b, right]
        case 6,7,8: // bottom edge → adjacent board below
            let below = row < 2 ? (row+1)*3 + col : b
            return below == b ? [b] : [b, below]
        case 9,10,11: // left edge → adjacent board to left
            let left = col > 0 ? row*3 + (col-1) : b
            return left == b ? [b] : [b, left]
        default: return [b]
        }
    }

    static func intersectionRoutingBoards(boardIndex b: Int, intersectionIndex i: Int) -> Set<Int> {
        // Intersection index: 0=TL, 1=TR, 2=BR, 3=BL
        let row = b / 3, col = b % 3
        var result: Set<Int> = [b]
        switch i {
        case 0: // TL corner: b, board above, board to left, board above-left
            if row > 0 { result.insert((row-1)*3 + col) }
            if col > 0 { result.insert(row*3 + (col-1)) }
            if row > 0 && col > 0 { result.insert((row-1)*3 + (col-1)) }
        case 1: // TR corner
            if row > 0 { result.insert((row-1)*3 + col) }
            if col < 2 { result.insert(row*3 + (col+1)) }
            if row > 0 && col < 2 { result.insert((row-1)*3 + (col+1)) }
        case 2: // BR corner
            if row < 2 { result.insert((row+1)*3 + col) }
            if col < 2 { result.insert(row*3 + (col+1)) }
            if row < 2 && col < 2 { result.insert((row+1)*3 + (col+1)) }
        case 3: // BL corner
            if row < 2 { result.insert((row+1)*3 + col) }
            if col > 0 { result.insert(row*3 + (col-1)) }
            if row < 2 && col > 0 { result.insert((row+1)*3 + (col-1)) }
        default: break
        }
        return result
    }

    // MARK: - Bounce routing

    static func bounceTarget(from boardIndex: Int, in state: GameState) -> Int? {
        let openBoards = (0..<9).filter { state.metaStatus[$0] == .active }
        guard !openBoards.isEmpty else { return nil }
        let row = boardIndex / 3, col = boardIndex % 3
        var best: (Int, Int)? = nil  // (distance, index)
        for b in openBoards {
            let br = b / 3, bc = b % 3
            let dist = max(abs(br - row), abs(bc - col))  // Chebyshev
            if let current = best {
                if dist < current.0 || (dist == current.0 && b < current.1) {
                    best = (dist, b)
                }
            } else {
                best = (dist, b)
            }
        }
        return best?.1
    }

    // MARK: - Meta-blocking

    static func applyBlocking(move: Move, to state: inout GameState) {
        guard move.posType == .edge else { return }
        // Determine which adjacent board's long-win line to block
        let e = move.posIndex
        let b = move.boardIndex
        let row = b / 3, col = b % 3

        // For each adjacent board sharing this edge, block the corresponding long-win line
        var adjacentBoardAndLine: [(Int, Int)]? = nil

        switch e {
        case 0,1,2: // top edge of b = bottom edge of board above
            if row > 0 {
                let above = (row-1)*3 + col
                // In board 'above', the bottom edge corresponds to blocking cells 6,7,8 (bottom row long win line index 2)
                adjacentBoardAndLine = [(above, 2)]
            }
        case 3,4,5: // right edge of b = left edge of board to right
            if col < 2 {
                let right = row*3 + (col+1)
                // In board 'right', left column = win line index 3 (cells 0,3,6)
                adjacentBoardAndLine = [(right, 3)]
            }
        case 6,7,8: // bottom edge of b = top edge of board below
            if row < 2 {
                let below = (row+1)*3 + col
                // In board 'below', top row = win line index 0 (cells 0,1,2)
                adjacentBoardAndLine = [(below, 0)]
            }
        case 9,10,11: // left edge of b = right edge of board to left
            if col > 0 {
                let left = row*3 + (col-1)
                // In board 'left', right column = win line index 4 (cells 2,5,8)
                adjacentBoardAndLine = [(left, 4)]
            }
        default: break
        }

        if let pairs = adjacentBoardAndLine {
            for (adjBoard, lineIdx) in pairs {
                if state.metaStatus[adjBoard] == .active {
                    state.boards[adjBoard].blockedLongWinLines.insert(lineIdx)
                }
            }
        }
    }

    // MARK: - Heuristic

    static func heuristicScore(_ state: GameState, for player: Player) -> Int {
        var score = 0
        let opp = player.opponent
        for line in GameState.metaWinLines {
            let statuses = line.map { state.metaStatus[$0] }
            let playerWon = statuses.filter { $0.winner == player }.count
            let oppWon = statuses.filter { $0.winner == opp }.count
            let active = statuses.filter { $0 == .active }.count
            if playerWon == 3 { return 10000 }
            if oppWon == 3 { return -10000 }
            if oppWon == 0 && playerWon == 2 && active == 1 { score += 200 }
            if playerWon == 0 && oppWon == 2 && active == 1 { score -= 200 }
            if oppWon == 0 && playerWon == 1 && active == 2 { score += 10 }
            if playerWon == 0 && oppWon == 1 && active == 2 { score -= 10 }
        }
        // Active board bonus
        let activeBoards = state.activeBoardsForCurrentPlayer.count
        if state.currentPlayer == player { score += activeBoards }
        return score
    }
}
