import SwiftUI

struct GameOverView: View {
    @State private var vm: GameOverViewModel
    @State private var confettiCounter = 0

    init(finalState: GameState, config: GameConfig, router: AppRouter) {
        _vm = State(initialValue: GameOverViewModel(finalState: finalState, config: config, router: router))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                // Winner announcement
                VStack(spacing: 12) {
                    if vm.isDraw {
                        Text("Draw!")
                            .font(.sfRounded(52, weight: .black))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("Well played by both sides")
                            .font(.sfRounded(16))
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        let winnerColor = vm.finalState.winner == .p1 ? AppTheme.player1Color : AppTheme.player2Color
                        Text(vm.winnerName)
                            .font(.sfRounded(40, weight: .black))
                            .foregroundColor(winnerColor)
                        Text("wins the game!")
                            .font(.sfRounded(24, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }

                // Mini meta-board summary
                GameOverBoardSummary(state: vm.finalState)
                    .frame(width: 180, height: 180)

                Spacer()

                // Actions
                VStack(spacing: 14) {
                    Button(action: vm.playAgain) {
                        Label("Play Again", systemImage: "arrow.clockwise")
                            .font(.sfRounded(17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppTheme.secondary)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    Button(action: vm.mainMenu) {
                        Label("Main Menu", systemImage: "house.fill")
                            .font(.sfRounded(17, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppTheme.surface)
                            .foregroundColor(AppTheme.textPrimary)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct GameOverBoardSummary: View {
    let state: GameState

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { col in
                        let idx = row * 3 + col
                        BoardSummaryCell(status: state.metaStatus[idx])
                    }
                }
            }
        }
    }
}

private struct BoardSummaryCell: View {
    let status: BoardStatus

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(cellColor)
            if status != .active {
                Text(status == .wonP1 ? "○" : (status == .wonP2 ? "✕" : ""))
                    .font(.sfRounded(22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 54, height: 54)
    }

    var cellColor: Color {
        switch status {
        case .wonP1: return AppTheme.player1Color
        case .wonP2: return AppTheme.player2Color
        case .drawn:  return AppTheme.drawnBoard
        case .active: return AppTheme.surface
        }
    }
}
