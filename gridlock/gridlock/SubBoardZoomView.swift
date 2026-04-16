import SwiftUI

@MainActor
struct SubBoardZoomView: View {
    let boardIndex: Int
    let vm: GameViewModel

    private var isExtended: Bool { vm.state.variant.isExtended }

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { vm.dismissZoom() }

            VStack(spacing: 16) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: vm.dismissZoom) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Sub-board grid
                if isExtended {
                    Extended5x5BoardView(boardIndex: boardIndex, vm: vm)
                        .padding(.horizontal, 24)
                } else {
                    Classic3x3BoardView(boardIndex: boardIndex, vm: vm)
                        .padding(.horizontal, 24)
                }

                // Confirm / Cancel bar
                if vm.settings.showConfirmButton,
                   let pending = vm.pendingMove,
                   pending.boardIndex == boardIndex {
                    ConfirmBar(vm: vm)
                        .padding(.horizontal, 24)
                }

                // Meta-board context
                MetaBoardView(vm: vm)
                    .frame(width: 160, height: 160)
                    .allowsHitTesting(false)

                Spacer(minLength: 16)
            }
            .background(AppTheme.background.cornerRadius(20))
            .padding(.horizontal, 16)
            .padding(.vertical, 60)
        }
        .animation(AnimationConstants.zoomSpring, value: vm.zoomedBoardIndex)
    }
}

// MARK: - Classic 3x3

@MainActor
private struct Classic3x3BoardView: View {
    let boardIndex: Int
    let vm: GameViewModel

    private var board: SubBoard { vm.state.boards[boardIndex] }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack(alignment: .topLeading) {
                // Grid of buttons (spacing 0 so Canvas coords map cleanly)
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: 0) {
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
                                .frame(width: size / 3, height: size / 3)
                            }
                        }
                    }
                }

                // Tic-tac-toe dividing lines
                Canvas { ctx, sz in
                    let lw: CGFloat = 3
                    let color = Color(white: 0.55)
                    for t in [1.0 / 3.0, 2.0 / 3.0] {
                        var h = Path()
                        h.move(to: CGPoint(x: 0, y: sz.height * t))
                        h.addLine(to: CGPoint(x: sz.width, y: sz.height * t))
                        ctx.stroke(h, with: .color(color), lineWidth: lw)

                        var v = Path()
                        v.move(to: CGPoint(x: sz.width * t, y: 0))
                        v.addLine(to: CGPoint(x: sz.width * t, y: sz.height))
                        ctx.stroke(v, with: .color(color), lineWidth: lw)
                    }
                }
                .allowsHitTesting(false)
                .frame(width: size, height: size)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func isPending(posType: PosType, posIndex: Int) -> Bool {
        guard let p = vm.pendingMove else { return false }
        return p.boardIndex == boardIndex && p.posType == posType && p.posIndex == posIndex
    }
}

// MARK: - Extended 5x5

@MainActor
private struct Extended5x5BoardView: View {
    let boardIndex: Int
    let vm: GameViewModel

    private var board: SubBoard { vm.state.boards[boardIndex] }

    // Correct 5x5 grid mapping:
    // Cells sit at classic TTO positions (even rows/cols).
    // Edges sit ON the dividing lines between adjacent cells (mixed even/odd).
    // Intersections sit where the two dividing lines cross (odd rows/cols).
    //
    //        col0      col1          col2      col3          col4
    // row0:  C[0]      E[9]=left0    C[1]      E[3]=right0   C[2]
    // row1:  E[0]=top0 I[0]=TL       E[1]=top1 I[1]=TR       E[2]=top2
    // row2:  C[3]      E[10]=left1   C[4]      E[4]=right1   C[5]
    // row3:  E[6]=bot0 I[3]=BL       E[7]=bot1 I[2]=BR       E[8]=bot2
    // row4:  C[6]      E[11]=left2   C[7]      E[5]=right2   C[8]
    private let gridPositions: [[(PosType, Int)]] = [
        [(.cell,0),          (.edge,9),           (.cell,1),  (.edge,3),           (.cell,2)],
        [(.edge,0),          (.intersection,0),   (.edge,1),  (.intersection,1),   (.edge,2)],
        [(.cell,3),          (.edge,10),          (.cell,4),  (.edge,4),           (.cell,5)],
        [(.edge,6),          (.intersection,3),   (.edge,7),  (.intersection,2),   (.edge,8)],
        [(.cell,6),          (.edge,11),          (.cell,7),  (.edge,5),           (.cell,8)],
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack(alignment: .topLeading) {
                // Uniform 5x5 grid — spacing 0 keeps line math clean
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<5, id: \.self) { col in
                                let (pt, pi) = gridPositions[row][col]
                                let player = board.occupant(posType: pt, posIndex: pi)
                                PositionButton(
                                    posType: pt,
                                    posIndex: pi,
                                    boardIndex: boardIndex,
                                    player: player,
                                    isPending: isPending(posType: pt, posIndex: pi),
                                    vm: vm
                                )
                                .frame(width: size / 5, height: size / 5)
                            }
                        }
                    }
                }

                // Lines run through the centers of rows/cols 1 and 3 in the 5x5 grid.
                // With cell size = sz/5, those centers are at 1.5*(sz/5) = 3sz/10 and 3.5*(sz/5) = 7sz/10.
                Canvas { ctx, sz in
                    let lw: CGFloat = 3
                    let color = Color(white: 0.55)
                    for t in [3.0 / 10.0, 7.0 / 10.0] {
                        var h = Path()
                        h.move(to: CGPoint(x: 0, y: sz.height * t))
                        h.addLine(to: CGPoint(x: sz.width, y: sz.height * t))
                        ctx.stroke(h, with: .color(color), lineWidth: lw)

                        var v = Path()
                        v.move(to: CGPoint(x: sz.width * t, y: 0))
                        v.addLine(to: CGPoint(x: sz.width * t, y: sz.height))
                        ctx.stroke(v, with: .color(color), lineWidth: lw)
                    }
                }
                .allowsHitTesting(false)
                .frame(width: size, height: size)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func isPending(posType: PosType, posIndex: Int) -> Bool {
        guard let p = vm.pendingMove else { return false }
        return p.boardIndex == boardIndex && p.posType == posType && p.posIndex == posIndex
    }
}

// MARK: - Position Button

@MainActor
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
            GeometryReader { geo in
                let s = min(geo.size.width, geo.size.height)
                ZStack {
                    if player != .empty {
                        Circle()
                            .fill(AppTheme.playerColor(player))
                            .frame(width: s * 0.72, height: s * 0.72)
                    } else if isPending {
                        Circle()
                            .fill(AppTheme.playerColor(vm.state.currentPlayer).opacity(0.6))
                            .frame(width: s * 0.60, height: s * 0.60)
                    } else {
                        Circle()
                            .fill(AppTheme.textSecondary.opacity(0.18))
                            .frame(width: s * 0.36, height: s * 0.36)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Confirm Bar

@MainActor
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
