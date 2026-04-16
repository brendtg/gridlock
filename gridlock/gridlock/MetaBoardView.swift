import SwiftUI

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
                            CompactSubBoardView(
                                boardIndex: idx,
                                vm: vm
                            )
                            .frame(width: boardSize, height: boardSize)
                            .onTapGesture {
                                vm.tapSubBoard(idx)
                            }
                        }
                    }
                }
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct CompactSubBoardView: View {
    let boardIndex: Int
    let vm: GameViewModel

    private var board: SubBoard { vm.state.boards[boardIndex] }
    private var status: BoardStatus { vm.state.metaStatus[boardIndex] }
    private var isActive: Bool {
        if vm.state.isGameOver { return false }
        let legalBoards = vm.state.activeBoardsForCurrentPlayer
        return legalBoards.isEmpty || legalBoards.contains(boardIndex)
    }
    private var isFreeMoveActive: Bool {
        vm.state.activeBoards.isEmpty && status == .active
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.surface)

            // Won/Drawn overlay
            if status == .wonP1 || status == .wonP2 {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.wonBoardColor(status.winner))
                Text(status.winner.symbol)
                    .font(.sfRounded(28, weight: .bold))
                    .foregroundColor(.white)
            } else if status == .drawn {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.drawnBoard)
                Text("–")
                    .font(.sfRounded(24, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
            } else {
                // Show mini cell grid for classic
                MiniCellGrid(board: board)
                    .padding(4)
            }

            // Active board ring
            if isActive && status == .active {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFreeMoveActive ? AppTheme.activeBoardHighlight.opacity(0.5) : AppTheme.activeBoardHighlight,
                            lineWidth: isFreeMoveActive ? 2 : 3)
            }
        }
    }
}

private struct MiniCellGrid: View {
    let board: SubBoard

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { col in
                        let idx = row * 3 + col
                        let player = board.cells[idx]
                        Circle()
                            .fill(player == .empty ? AppTheme.textSecondary.opacity(0.15) :
                                  (player == .p1 ? AppTheme.player1Color : AppTheme.player2Color))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }
}
