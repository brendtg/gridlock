import SwiftUI

struct TokenCounterView: View {
    let state: GameState

    var body: some View {
        HStack(spacing: 12) {
            tokenRow(label: "E", count: state.p1Tokens.edgeTokens, iCount: state.p1Tokens.intersectionTokens, color: AppTheme.player1Color)
            Divider().frame(height: 24).background(AppTheme.textSecondary.opacity(0.3))
            tokenRow(label: "E", count: state.p2Tokens.edgeTokens, iCount: state.p2Tokens.intersectionTokens, color: AppTheme.player2Color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.surface)
        .cornerRadius(10)
    }

    private func tokenRow(label: String, count: Int, iCount: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            tokenPill(letter: "E", count: count, color: color)
            tokenPill(letter: "I", count: iCount, color: color)
        }
    }

    private func tokenPill(letter: String, count: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(letter)
                .font(.sfRounded(11, weight: .bold))
            Text("×\(count)")
                .font(.sfRounded(11, weight: .medium))
        }
        .foregroundColor(count <= 3 ? .red : color)
        .opacity(count <= 0 ? 0.3 : 1)
    }
}
