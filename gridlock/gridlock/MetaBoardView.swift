import SwiftUI

@MainActor
struct MetaBoardView: View {
    let vm: GameViewModel

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let boardSize = (size - 8) / 3

            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { col in
                            let idx = row * 3 + col
                            CompactSubBoardView(boardIndex: idx, vm: vm)
                                .frame(width: boardSize, height: boardSize)
                                .onTapGesture { vm.tapSubBoard(idx) }
                        }
                    }
                }
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

@MainActor
struct CompactSubBoardView: View {
    let boardIndex: Int
    let vm: GameViewModel

    private var board: SubBoard { vm.state.boards[boardIndex] }
    private var status: BoardStatus { vm.state.metaStatus[boardIndex] }
    private var isExtended: Bool { vm.state.variant.isExtended }
    private var isActive: Bool {
        if vm.state.isGameOver { return false }
        let legalBoards = vm.state.activeBoardsForCurrentPlayer
        return legalBoards.isEmpty || legalBoards.contains(boardIndex)
    }
    private var isFreeMoveActive: Bool {
        vm.state.activeBoards.isEmpty && status == .active
    }
    private var isPendingTarget: Bool {
        vm.pendingMoveTargets.contains(boardIndex) && status == .active
    }
    private var isZoomed: Bool {
        vm.zoomedBoardIndex == boardIndex
    }
    private var currentPlayerColor: Color { AppTheme.playerColor(vm.state.currentPlayer) }
    private var opponentColor: Color { AppTheme.playerColor(vm.state.currentPlayer.opponent) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(AppTheme.surface)

            if status == .wonP1 || status == .wonP2 {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppTheme.wonBoardColor(status.winner))
                Text(status.winner.symbol)
                    .font(.sfRounded(22, weight: .bold))
                    .foregroundColor(.white)
            } else if status == .drawn {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppTheme.drawnBoard)
                Text("–")
                    .font(.sfRounded(20, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
            } else {
                MiniBoardGrid(board: board, isExtended: isExtended)
                    .padding(3)
            }

            // Zoomed board: light fill in current player's color
            if isZoomed {
                RoundedRectangle(cornerRadius: 6)
                    .fill(currentPlayerColor.opacity(0.18))
                RoundedRectangle(cornerRadius: 6)
                    .stroke(currentPlayerColor.opacity(0.8), lineWidth: 3)
            }

            // Routing target: outlined in opponent's color
            if isPendingTarget {
                RoundedRectangle(cornerRadius: 6)
                    .fill(opponentColor.opacity(0.15))
                RoundedRectangle(cornerRadius: 6)
                    .stroke(opponentColor, lineWidth: 3)
            }

            // Active board ring: current player's color shows where they can play
            if isActive && status == .active && !isPendingTarget && !isZoomed {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isFreeMoveActive
                            ? currentPlayerColor.opacity(0.5)
                            : currentPlayerColor,
                        lineWidth: isFreeMoveActive ? 2 : 3
                    )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPendingTarget)
        .animation(.easeInOut(duration: 0.2), value: isZoomed)
    }
}

// MARK: - Mini board grid (non-interactive)

private struct MiniBoardGrid: View {
    let board: SubBoard
    let isExtended: Bool

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            if isExtended {
                ExtendedMiniBoardGrid(board: board, size: size)
            } else {
                ClassicMiniBoardGrid(board: board, size: size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct ClassicMiniBoardGrid: View {
    let board: SubBoard
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { col in
                            let idx = row * 3 + col
                            MiniPiece(player: board.cells[idx], cellSize: size / 3)
                        }
                    }
                }
            }

            Canvas { ctx, sz in
                drawTTOLines(ctx: ctx, sz: sz, at: [1.0/3.0, 2.0/3.0], lineWidth: 1.5)
            }
            .allowsHitTesting(false)
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}

private struct ExtendedMiniBoardGrid: View {
    let board: SubBoard
    let size: CGFloat

    // Same correct mapping as SubBoardZoomView
    private let grid: [[(PosType, Int)]] = [
        [(.cell,0),  (.edge,9),  (.cell,1),  (.edge,3),  (.cell,2)],
        [(.edge,0),  (.intersection,0), (.edge,1),  (.intersection,1), (.edge,2)],
        [(.cell,3),  (.edge,10), (.cell,4),  (.edge,4),  (.cell,5)],
        [(.edge,6),  (.intersection,3), (.edge,7),  (.intersection,2), (.edge,8)],
        [(.cell,6),  (.edge,11), (.cell,7),  (.edge,5),  (.cell,8)],
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { col in
                            let (pt, pi) = grid[row][col]
                            MiniPiece(
                                player: board.occupant(posType: pt, posIndex: pi),
                                cellSize: size / 5
                            )
                        }
                    }
                }
            }

            Canvas { ctx, sz in
                drawTTOLines(ctx: ctx, sz: sz, at: [3.0/10.0, 7.0/10.0], lineWidth: 1.5)
            }
            .allowsHitTesting(false)
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}

private struct MiniPiece: View {
    let player: Player
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            if player != .empty {
                Circle()
                    .fill(AppTheme.playerColor(player))
                    .padding(cellSize * 0.12)
            } else {
                Circle()
                    .fill(Color(white: 0.5).opacity(0.18))
                    .padding(cellSize * 0.28)
            }
        }
        .frame(width: cellSize, height: cellSize)
    }
}

// Shared line-drawing helper (free function so both grid types can call it)
private func drawTTOLines(ctx: GraphicsContext, sz: CGSize, at positions: [Double], lineWidth: CGFloat) {
    let color = Color(white: 0.5)
    for t in positions {
        var h = Path()
        h.move(to: CGPoint(x: 0, y: sz.height * t))
        h.addLine(to: CGPoint(x: sz.width, y: sz.height * t))
        ctx.stroke(h, with: .color(color), lineWidth: lineWidth)

        var v = Path()
        v.move(to: CGPoint(x: sz.width * t, y: 0))
        v.addLine(to: CGPoint(x: sz.width * t, y: sz.height))
        ctx.stroke(v, with: .color(color), lineWidth: lineWidth)
    }
}
