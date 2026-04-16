import SwiftUI

@MainActor
struct GameBoardView: View {
    @State private var vm: GameViewModel
    let router: AppRouter

    init(config: GameConfig, settings: SettingsStore, router: AppRouter) {
        _vm = State(initialValue: GameViewModel(config: config, settings: settings))
        self.router = router
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                Spacer(minLength: 0)

                // Meta board
                MetaBoardView(vm: vm)
                    .padding(.horizontal, 12)

                Spacer(minLength: 0)

                // Bottom bar
                bottomBar
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }

            // Routing animation overlay
            if vm.showRoutingAnimation {
                RoutingAnimationOverlay(
                    sourceBoard: vm.routingAnimationSource,
                    targetBoards: vm.routingAnimationTarget
                )
                .allowsHitTesting(false)
            }

            // AI thinking overlay
            if vm.isAIThinking {
                VStack {
                    Spacer()
                    AIThinkingIndicator()
                        .padding(.bottom, 80)
                }
                .allowsHitTesting(false)
            }

            // Pie rule offer
            if vm.showPieRuleOffer {
                PieRuleOfferView(
                    onAccept: { vm.acceptPieRule() },
                    onDecline: { vm.declinePieRule() }
                )
            }

            // Turn handoff (Pass & Play)
            if vm.showTurnHandoff {
                TurnHandoffView(vm: vm)
            }

            // Sub-board zoom
            if let zoomedIdx = vm.zoomedBoardIndex {
                SubBoardZoomView(boardIndex: zoomedIdx, vm: vm)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.7).combined(with: .opacity),
                        removal: .scale(scale: 0.7).combined(with: .opacity)
                    ))
            }
        }
        .navigationBarHidden(true)
        .onAppear { vm.triggerAIIfNeeded_public() }
        .onChange(of: vm.gameOverState) { _, finalState in
            if let s = finalState {
                router.push(.gameOver(finalState: s, config: vm.config))
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            // Back button
            Button(action: { router.pop() }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(8)
            }

            // P1 indicator
            PlayerIndicatorView(player: .p1, vm: vm, isActive: vm.state.currentPlayer == .p1 && !vm.state.isGameOver)
            Spacer()

            // Score
            ScoreView(state: vm.state)

            Spacer()
            // P2 indicator
            PlayerIndicatorView(player: .p2, vm: vm, isActive: vm.state.currentPlayer == .p2 && !vm.state.isGameOver)
        }
        .padding(.vertical, 8)
        .background(AppTheme.surface.opacity(0.8))
        .cornerRadius(12)
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            if vm.config.playMode != .online {
                Button(action: vm.undo) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.sfRounded(14))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppTheme.surface)
                        .cornerRadius(10)
                }
            }
            Spacer()
            // Token counter (token variants only)
            if vm.state.variant.hasTokenBudget {
                TokenCounterView(state: vm.state)
            }
            Spacer()
            Button(action: vm.resign) {
                Label("Resign", systemImage: "flag.fill")
                    .font(.sfRounded(14))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.surface)
                    .cornerRadius(10)
            }
        }
    }
}

private struct ScoreView: View {
    let state: GameState
    var p1Score: Int { state.metaStatus.filter { $0 == .wonP1 }.count }
    var p2Score: Int { state.metaStatus.filter { $0 == .wonP2 }.count }

    var body: some View {
        HStack(spacing: 10) {
            Text("\(p1Score)")
                .font(.sfRounded(22, weight: .bold))
                .foregroundColor(AppTheme.player1Color)
            Text("–")
                .font(.sfRounded(18))
                .foregroundColor(AppTheme.textSecondary)
            Text("\(p2Score)")
                .font(.sfRounded(22, weight: .bold))
                .foregroundColor(AppTheme.player2Color)
        }
    }
}

private struct PieRuleOfferView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Pie Rule")
                    .font(.sfRounded(24, weight: .bold))
                    .foregroundColor(.white)
                Text("Player 2: you may swap sides and take over the opening move, or play on.")
                    .font(.sfRounded(15))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                HStack(spacing: 16) {
                    Button(action: onDecline) {
                        Text("Play On")
                            .font(.sfRounded(16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.surface)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    Button(action: onAccept) {
                        Text("Swap Sides")
                            .font(.sfRounded(16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.secondary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding(28)
            .background(AppTheme.background)
            .cornerRadius(20)
            .padding(24)
        }
    }
}

private struct RoutingAnimationOverlay: View {
    let sourceBoard: Int?
    let targetBoards: Set<Int>
    @State private var opacity: Double = 0

    var body: some View {
        // Simplified: flash the target boards with a pulsing highlight
        // Full arc animation would require GeometryReader coordination with MetaBoardView
        Color.clear
            .onAppear { withAnimation(.easeIn(duration: 0.1)) { opacity = 1 } }
    }
}
