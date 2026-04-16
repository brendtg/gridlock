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

    // MARK: - Edge / Intersection routing tables
    //
    // Routing is determined by which cells a position is adjacent to.
    // Cell indices 0-8 are the meta-board indices, so adjacency directly
    // gives the target meta-boards regardless of which sub-board was played.
    //
    // 5x5 grid (cells at even rows/cols, edges/intersections on the lines):
    //        col0   col1     col2   col3     col4
    // row0:  C[0]   E[9]     C[1]   E[3]     C[2]
    // row1:  E[0]   I[0]=TL  E[1]   I[1]=TR  E[2]
    // row2:  C[3]   E[10]    C[4]   E[4]     C[5]
    // row3:  E[6]   I[3]=BL  E[7]   I[2]=BR  E[8]
    // row4:  C[6]   E[11]    C[7]   E[5]     C[8]

    static func edgeRoutingBoards(boardIndex b: Int, edgeIndex e: Int) -> Set<Int> {
        switch e {
        case 0:  return [0, 3]   // top div line, left col:   between C[0] and C[3]
        case 1:  return [1, 4]   // top div line, center col: between C[1] and C[4]
        case 2:  return [2, 5]   // top div line, right col:  between C[2] and C[5]
        case 3:  return [1, 2]   // right div line, top row:  between C[1] and C[2]
        case 4:  return [4, 5]   // right div line, mid row:  between C[4] and C[5]
        case 5:  return [7, 8]   // right div line, bot row:  between C[7] and C[8]
        case 6:  return [3, 6]   // bot div line, left col:   between C[3] and C[6]
        case 7:  return [4, 7]   // bot div line, center col: between C[4] and C[7]
        case 8:  return [5, 8]   // bot div line, right col:  between C[5] and C[8]
        case 9:  return [0, 1]   // left div line, top row:   between C[0] and C[1]
        case 10: return [3, 4]   // left div line, mid row:   between C[3] and C[4]
        case 11: return [6, 7]   // left div line, bot row:   between C[6] and C[7]
        default: return [b]
        }
    }

    static func intersectionRoutingBoards(boardIndex b: Int, intersectionIndex i: Int) -> Set<Int> {
        // Each intersection touches the 4 surrounding cells.
        switch i {
        case 0: return [0, 1, 3, 4]  // TL: touches C[0], C[1], C[3], C[4]
        case 1: return [1, 2, 4, 5]  // TR: touches C[1], C[2], C[4], C[5]
        case 2: return [4, 5, 7, 8]  // BR: touches C[4], C[5], C[7], C[8]
        case 3: return [3, 4, 6, 7]  // BL: touches C[3], C[4], C[6], C[7]
        default: return [b]
        }
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
