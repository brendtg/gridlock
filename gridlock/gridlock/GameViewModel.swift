import SwiftUI
import Observation

@Observable
@MainActor
final class GameViewModel {
    private(set) var state: GameState
    let config: GameConfig
    let settings: SettingsStore

    // UI state
    var zoomedBoardIndex: Int? = nil
    var pendingMove: Move? = nil
    var isAIThinking: Bool = false
    var routingAnimationSource: Int? = nil
    var routingAnimationTarget: Set<Int> = []
    var showRoutingAnimation: Bool = false
    var showTurnHandoff: Bool = false
    var gameOverState: GameState? = nil

    // Undo stack
    private var undoStack: [GameState] = []

    init(config: GameConfig, settings: SettingsStore) {
        self.config = config
        self.settings = settings
        self.state = GameState.initial(variant: config.variant)
    }

    // MARK: - Board Interaction

    func tapSubBoard(_ index: Int) {
        guard !state.isGameOver else { return }
        let legalBoards = state.activeBoardsForCurrentPlayer
        guard legalBoards.contains(index) || legalBoards.isEmpty || state.activeBoards.isEmpty else { return }
        // Can only zoom into active boards
        guard state.metaStatus[index] == .active else { return }
        // For a board that's in the legal set or any board if free move
        let canPlay = state.activeBoardsForCurrentPlayer.contains(index) ||
                      state.activeBoardsForCurrentPlayer.isEmpty
        guard canPlay else { return }
        zoomedBoardIndex = index
    }

    func tapPosition(boardIndex: Int, posType: PosType, posIndex: Int) {
        guard !state.isGameOver else { return }
        guard !isAIThinking else { return }
        // Only human's turn
        if config.playMode == .vsComputer && state.currentPlayer != config.playerSide { return }
        // Verify the board is active and position is empty
        guard state.metaStatus[boardIndex] == .active else { return }
        let board = state.boards[boardIndex]
        guard board.occupant(posType: posType, posIndex: posIndex) == .empty else { return }
        // Verify legal
        let legalMoves = GameEngine.legalMoves(in: state)
        let m = Move(boardIndex: boardIndex, posType: posType, posIndex: posIndex)
        guard legalMoves.contains(where: { $0.boardIndex == m.boardIndex && $0.posType == m.posType && $0.posIndex == m.posIndex }) else { return }
        pendingMove = m
        if !settings.showConfirmButton {
            confirmMove()
        }
    }

    func confirmMove() {
        guard let move = pendingMove else { return }
        pendingMove = nil
        applyHumanMove(move)
    }

    func cancelPendingMove() {
        pendingMove = nil
    }

    func dismissZoom() {
        zoomedBoardIndex = nil
        pendingMove = nil
    }

    // MARK: - Undo / Resign

    func undo() {
        guard !undoStack.isEmpty else { return }
        // In vsComputer mode, undo two moves (AI + human)
        if config.playMode == .vsComputer && undoStack.count >= 2 {
            undoStack.removeLast()
            state = undoStack.removeLast()
        } else {
            state = undoStack.removeLast()
        }
        pendingMove = nil
        isAIThinking = false
    }

    func resign() {
        var s = state
        s.isGameOver = true
        s.winner = s.currentPlayer.opponent
        state = s
        handleGameOver()
    }

    // MARK: - Private

    private func applyHumanMove(_ move: Move) {
        undoStack.append(state)
        HapticService.confirmMove(settings: settings)
        SoundService.playMove(settings: settings)
        state = GameEngine.apply(move, to: state)

        // Show routing animation
        if settings.showRoutingAnimation {
            routingAnimationSource = move.boardIndex
            routingAnimationTarget = state.activeBoards.isEmpty
                ? Set((0..<9).filter { state.metaStatus[$0] == .active })
                : state.activeBoards
            showRoutingAnimation = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(AnimationConstants.routingDuration * 1_000_000_000))
                showRoutingAnimation = false
            }
        }

        // Close zoom
        zoomedBoardIndex = nil

        if state.isGameOver {
            handleGameOver()
            return
        }

        // Pass & play handoff
        if config.playMode == .passAndPlay {
            showTurnHandoff = true
            return
        }

        triggerAIIfNeeded()
    }

    private func triggerAIIfNeeded() {
        guard config.playMode == .vsComputer else { return }
        guard state.currentPlayer != config.playerSide else { return }
        guard !state.isGameOver else { return }
        isAIThinking = true
        Task { @MainActor in
            let move = await AIPlayer.shared.bestMove(for: state, difficulty: config.difficulty)
            guard !state.isGameOver else { isAIThinking = false; return }
            isAIThinking = false
            undoStack.append(state)
            SoundService.playMove(settings: settings)
            state = GameEngine.apply(move, to: state)
            zoomedBoardIndex = nil

            if settings.showRoutingAnimation {
                routingAnimationSource = move.boardIndex
                routingAnimationTarget = state.activeBoards.isEmpty
                    ? Set((0..<9).filter { state.metaStatus[$0] == .active })
                    : state.activeBoards
                showRoutingAnimation = true
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(AnimationConstants.routingDuration * 1_000_000_000))
                    showRoutingAnimation = false
                }
            }

            if state.isGameOver { handleGameOver() }
        }
    }

    func triggerAIIfNeeded_public() {
        triggerAIIfNeeded()
    }

    private func handleGameOver() {
        gameOverState = state
        if state.winner != .empty {
            HapticService.gameOver(win: true, settings: settings)
            SoundService.playWin(settings: settings)
        } else {
            SoundService.playDraw(settings: settings)
        }
    }

    func revealBoard() {
        showTurnHandoff = false
        triggerAIIfNeeded()
    }

    // MARK: - Display helpers

    func playerDisplayName(_ player: Player) -> String {
        if config.playMode == .vsComputer {
            if player == config.playerSide { return "You" }
            return config.difficulty.avatarName
        }
        return player == .p1 ? config.player1Name : config.player2Name
    }

    var currentPlayerName: String { playerDisplayName(state.currentPlayer) }
    var currentPlayerColor: Color { AppTheme.playerColor(state.currentPlayer) }

    /// Boards the opponent will be routed to if the pending move is confirmed.
    var pendingMoveTargets: Set<Int> {
        guard let move = pendingMove else { return [] }
        let next = GameEngine.apply(move, to: state)
        return next.activeBoards.isEmpty
            ? Set((0..<9).filter { next.metaStatus[$0] == .active })
            : next.activeBoards
    }
}
