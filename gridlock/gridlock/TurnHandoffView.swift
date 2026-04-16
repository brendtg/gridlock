import SwiftUI

struct TurnHandoffView: View {
    let vm: GameViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 48))
                    .foregroundColor(vm.currentPlayerColor)
                VStack(spacing: 8) {
                    Text("\(vm.currentPlayerName)'s turn")
                        .font(.sfRounded(32, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Hand the phone over")
                        .font(.sfRounded(16))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Button(action: vm.revealBoard) {
                    Text("I'm Ready")
                        .font(.sfRounded(18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(vm.currentPlayerColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
