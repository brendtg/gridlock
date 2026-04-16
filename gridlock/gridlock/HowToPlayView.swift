import SwiftUI

struct HowToPlayView: View {
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 16) {
                    HelpCard(
                        title: "The Big Picture",
                        icon: "square.grid.3x3",
                        content: "The game is played on a 3×3 grid of small boards. To win, you need to win three small boards in a row — horizontally, vertically, or diagonally — just like regular tic-tac-toe, but one level up.\n\nEach small board is its own game of tic-tac-toe. Win the small board, and you claim that square on the big grid.",
                        diagram: nil
                    )
                    HelpCard(
                        title: "Routing: Where You Play Sends Your Opponent",
                        icon: "arrow.right.circle",
                        content: "In Classic, the cell you play in decides where your opponent must play next. Play in cell 5 of any board and your opponent is sent to board 5.\n\nEvery move is both a claim on the small board AND a directive to your opponent. You are always thinking two moves at once.\n\nIf the board your opponent would be sent to is already finished (won or full), they get a FREE MOVE and can play anywhere.",
                        diagram: nil
                    )
                    HelpCard(
                        title: "Extended Board: Edges & Intersections",
                        icon: "square.grid.4x3.fill",
                        content: "In Extended Board variants, each small board has 25 positions instead of 9.\n\nEDGE positions (E): sit on the line between two boards. Playing one routes your opponent to EITHER of the two boards that share that edge — they choose.\n\nINTERSECTION positions (I): sit at corners where four boards meet. Routes to any of THREE boards — opponent chooses.\n\nCELL positions: work exactly as in Classic.",
                        diagram: """
                        i ─ e ─ i ─ e ─ i
                        e   .   .   .   e
                        i   .   .   .   i
                        e   .   .   .   e
                        i ─ e ─ i ─ e ─ i
                        i=corner  e=edge  .=cell
                        """
                    )
                    HelpCard(
                        title: "Long Wins & Short Wins",
                        icon: "checkmark.seal",
                        content: "LONG WIN: Three cells in a row using only the inner cell positions. Traditional tic-tac-toe win.\n\nSHORT WIN: Three in a row where at least one piece is an edge or intersection position. Short wins CANNOT be blocked.\n\nPlaying edge/intersection positions gives your opponent routing choice — there is a real tradeoff.",
                        diagram: nil
                    )
                    HelpCard(
                        title: "Blocking: Stop the Long Win",
                        icon: "shield.fill",
                        content: "In Blocking variants, placing a piece on an edge position does two things:\n1. Routes your opponent (as normal)\n2. Blocks a specific long-win line in the board that edge borders\n\nBlocking only stops LONG wins. Short wins (lines involving edge or intersection pieces) cannot be blocked.",
                        diagram: nil
                    )
                    HelpCard(
                        title: "Token Rush: Spend Your Budget Wisely",
                        icon: "dollarsign.circle",
                        content: "Each player starts with 18 edge tokens and 6 intersection tokens.\n\nEvery time you play an edge position, you spend 1 edge token. Intersection positions cost 1 intersection token. Cell positions are always free.\n\nOnce your tokens run out, you play cells only — exactly like Classic. This creates a two-phase game: an expansive opening followed by a sharp Classic-like endgame.",
                        diagram: "Blue: E×14  I×5\nPink: E×18  I×6\n(counts turn red when ≤3 remain)"
                    )
                    HelpCard(
                        title: "Bounce Routing",
                        icon: "arrow.triangle.branch",
                        content: "In Bounce variants, if your move would send the opponent to a finished board, instead of a free move they are redirected to the NEAREST unfinished board (by grid distance).\n\nThis eliminates 'routing gifts' and tightens the endgame — you always land somewhere specific.",
                        diagram: nil
                    )
                    HelpCard(
                        title: "Pie Rule",
                        icon: "arrow.left.arrow.right",
                        content: "After Player 1 makes their first move, Player 2 can choose to SWAP SIDES — taking over as 'Player 1' and giving the opening move to their opponent.\n\nIf the opening was too strong, Player 2 will swap. This encourages balanced opening moves.\n\nOptional — toggle in game setup.",
                        diagram: nil
                    )
                }
                .padding()
            }
        }
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct HelpCard: View {
    let title: String
    let icon: String
    let content: String
    let diagram: String?

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3)) { expanded.toggle() } }) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(AppTheme.secondary)
                        .frame(width: 28)
                    Text(title)
                        .font(.sfRounded(16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(content)
                        .font(.sfRounded(14))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let diagram = diagram {
                        Text(diagram)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(AppTheme.primary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.background)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .background(AppTheme.surface)
        .cornerRadius(14)
    }
}
