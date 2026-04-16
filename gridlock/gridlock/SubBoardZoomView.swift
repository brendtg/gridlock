import SwiftUI

struct SubBoardZoomView: View {
    let boardIndex: Int
    let vm: GameViewModel

    private var board: SubBoard { vm.state.boards[boardIndex] }
    private var isExtended: Bool { vm.state.variant.isExtended }

    var body: some View {
        ZStack {
            // Blurred backdrop
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { vm.dismissZoom() }

            VStack(spacing: 0) {
                // Board header
                HStack {
                    Text("Board \(boardIndex + 1)")
                        .font(.sfRounded(18, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button(action: vm.dismissZoom) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // Board grid
                ZoomedBoardGrid(boardIndex: boardIndex, vm: vm, isExtended: isExtended)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)

                // Confirm / Cancel bar
                if vm.settings.showConfirmButton, let pending = vm.pendingMove, pending.boardIndex == boardIndex {
                    ConfirmBar(vm: vm)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }

                Spacer(minLength: 20)
            }
            .background(AppTheme.background.cornerRadius(20))
            .padding(.horizontal, 16)
            .padding(.vertical, 60)
        }
        .animation(AnimationConstants.zoomSpring, value: vm.zoomedBoardIndex)
    }
}

private struct ZoomedBoardGrid: View {
    let boardIndex: Int
    let vm: GameViewModel
    let isExtended: Bool

    private var board: SubBoard { vm.state.boards[boardIndex] }

    var body: some View {
        if isExtended {
            Extended5x5BoardView(boardIndex: boardIndex, vm: vm)
        } else {
            Classic3x3BoardView(boardIndex: boardIndex, vm: vm)
        }
    }
}

// MARK: - Classic 3x3

private struct Classic3x3BoardView: View {
    let boardIndex: Int
    let vm: GameViewModel
    private var board: SubBoard { vm.state.boards[boardIndex] }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { col in
                        let idx = row * 3 + col
                        PositionButton(
                            posType: .cell,
                            posIndex: idx,
                            boardIndex: boardIndex,
                            player: board.cells[idx],
                            isPending: isPending(posType: .cell, posIndex: idx),
                            vm: vm
                        )
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func isPending(posType: PosType, posIndex: Int) -> Bool {
        guard let p = vm.pendingMove else { return false }
        return p.boardIndex == boardIndex && p.posType == posType && p.posIndex == posIndex
    }
}

// MARK: - Extended 5x5

private struct Extended5x5BoardView: View {
    let boardIndex: Int
    let vm: GameViewModel
    private var board: SubBoard { vm.state.boards[boardIndex] }

    // 5x5 grid layout:
    // (0,0)=I[0]  (0,1)=E[0]  (0,2)=I[1]  (0,3)=E[1]  (0,4)=I[2] -- wait, spec says:
    // i e i e i   (top row: TL, top0, top_mid, top1... hmm)
    // let's use: row0: TL(I0), top0(E0), top1(E1), top2(E2), TR(I1)... no.
    // From SubBoard.swift definition:
    //   edges[0..2] = top0,top1,top2; edges[3..5]=right0,1,2; edges[6..8]=bot0,1,2; edges[9..11]=left0,1,2
    //   intersections[0]=TL, [1]=TR, [2]=BR, [3]=BL
    // 5x5 grid mapping:
    // (0,0)=I0=TL  (0,1)=E0=top0  (0,2)=I1=TR  ... wait TR should be at (0,4)
    // Let's do it properly:
    // Row 0: I[0]=TL, E[top0]=0, E[top1]=1, E[top2]=2, I[1]=TR  (but top has 3 edges between TL and TR)
    // Hmm, spec says "4 sides x 3 positions each = 12 edges" but the 5x5 grid only has 3 positions on each side
    // between corners. So: 5x5 = 25 positions, inner 3x3 = 9 cells, border = 16 positions (4 corners + 12 edges)
    // 4 corners = intersections[0..3]
    // 12 edges: top(3) + right(3) + bottom(3) + left(3)
    // Row 0: I[0], E[top0], E[top1], E[top2], I[1]
    // Row 1: E[left0], C[0], C[1], C[2], E[right0]
    // Row 2: E[left1], C[3], C[4], C[5], E[right1]
    // Row 3: E[left2], C[6], C[7], C[8], E[right2]
    // Row 4: I[3], E[bot0], E[bot1], E[bot2], I[2]

    struct GridPos {
        let posType: PosType
        let posIndex: Int
    }

    var gridPositions: [[GridPos]] {
        [
            [GridPos(posType: .intersection, posIndex: 0),
             GridPos(posType: .edge, posIndex: 0),
             GridPos(posType: .edge, posIndex: 1),
             GridPos(posType: .edge, posIndex: 2),
             GridPos(posType: .intersection, posIndex: 1)],
            [GridPos(posType: .edge, posIndex: 9),
             GridPos(posType: .cell, posIndex: 0),
             GridPos(posType: .cell, posIndex: 1),
             GridPos(posType: .cell, posIndex: 2),
             GridPos(posType: .edge, posIndex: 3)],
            [GridPos(posType: .edge, posIndex: 10),
             GridPos(posType: .cell, posIndex: 3),
             GridPos(posType: .cell, posIndex: 4),
             GridPos(posType: .cell, posIndex: 5),
             GridPos(posType: .edge, posIndex: 4)],
            [GridPos(posType: .edge, posIndex: 11),
             GridPos(posType: .cell, posIndex: 6),
             GridPos(posType: .cell, posIndex: 7),
             GridPos(posType: .cell, posIndex: 8),
             GridPos(posType: .edge, posIndex: 5)],
            [GridPos(posType: .intersection, posIndex: 3),
             GridPos(posType: .edge, posIndex: 6),
             GridPos(posType: .edge, posIndex: 7),
             GridPos(posType: .edge, posIndex: 8),
             GridPos(posType: .intersection, posIndex: 2)],
        ]
    }

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { col in
                        let gp = gridPositions[row][col]
                        let player = board.occupant(posType: gp.posType, posIndex: gp.posIndex)
                        PositionButton(
                            posType: gp.posType,
                            posIndex: gp.posIndex,
                            boardIndex: boardIndex,
                            player: player,
                            isPending: isPending(gp),
                            vm: vm
                        )
                        .frame(maxWidth: .infinity)
                        .aspectRatio(posAspect(gp.posType), contentMode: .fit)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func posAspect(_ pt: PosType) -> CGFloat {
        switch pt {
        case .cell: return 1.0
        case .edge: return 0.6
        case .intersection: return 0.6
        }
    }

    private func isPending(_ gp: GridPos) -> Bool {
        guard let p = vm.pendingMove else { return false }
        return p.boardIndex == boardIndex && p.posType == gp.posType && p.posIndex == gp.posIndex
    }
}

// MARK: - Position Button

private struct PositionButton: View {
    let posType: PosType
    let posIndex: Int
    let boardIndex: Int
    let player: Player
    let isPending: Bool
    let vm: GameViewModel

    var body: some View {
        Button(action: {
            vm.tapPosition(boardIndex: boardIndex, posType: posType, posIndex: posIndex)
        }) {
            ZStack {
                positionBackground
                if player != .empty {
                    Text(player.symbol)
                        .font(.sfRounded(fontSize, weight: .bold))
                        .foregroundColor(AppTheme.playerColor(player))
                } else if isPending {
                    Circle()
                        .fill(AppTheme.secondary.opacity(0.6))
                        .padding(4)
                }
                if player == .empty && !isPending && posType != .cell {
                    Text(posType == .edge ? "E" : "I")
                        .font(.sfRounded(9, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(player != .empty)
    }

    private var fontSize: CGFloat {
        switch posType {
        case .cell: return 22
        case .edge, .intersection: return 16
        }
    }

    @ViewBuilder
    private var positionBackground: some View {
        let color: Color = player != .empty ? AppTheme.playerColor(player).opacity(0.15) :
                           (isPending ? AppTheme.secondary.opacity(0.2) : AppTheme.surface)
        switch posType {
        case .cell:
            RoundedRectangle(cornerRadius: 8).fill(color)
        case .edge:
            RoundedRectangle(cornerRadius: 6).fill(color)
        case .intersection:
            RoundedRectangle(cornerRadius: 10).fill(color)
                .rotationEffect(.degrees(45))
                .scaleEffect(0.7)
                .background(Color.clear)
        }
    }
}

// MARK: - Confirm Bar

struct ConfirmBar: View {
    let vm: GameViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button(action: vm.cancelPendingMove) {
                Text("Cancel")
                    .font(.sfRounded(16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.surface)
                    .foregroundColor(AppTheme.textSecondary)
                    .cornerRadius(12)
            }
            Button(action: vm.confirmMove) {
                Text("Confirm Move")
                    .font(.sfRounded(16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.secondary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
}
