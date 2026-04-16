import SwiftUI

struct PlayerIndicatorView: View {
    let player: Player
    let vm: GameViewModel
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.playerColor(player))
                .frame(width: 10, height: 10)
                .opacity(isActive ? 1 : 0.4)
            Text(vm.playerDisplayName(player))
                .font(.sfRounded(13, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? AppTheme.textPrimary : AppTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? AppTheme.playerColor(player).opacity(0.15) : Color.clear)
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}
