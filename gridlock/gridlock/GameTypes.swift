import Foundation

enum Player: Int, Codable, Equatable {
    case empty = 0, p1 = 1, p2 = 2
    var opponent: Player {
        switch self { case .p1: return .p2; case .p2: return .p1; case .empty: return .empty }
    }
    var symbol: String { self == .p1 ? "○" : "✕" }
}

enum PosType: Int, Codable, Hashable {
    case cell, edge, intersection
}

enum BoardStatus: Int, Codable, Equatable {
    case active, wonP1, wonP2, drawn
    var winner: Player {
        switch self { case .wonP1: return .p1; case .wonP2: return .p2; default: return .empty }
    }
    var isDecided: Bool { self != .active }
}

enum GameVariant: String, Codable, CaseIterable, Hashable {
    case classic
    case v1EdgeIntersection
    case v2MetaBlocking
    case v1bBounce
    case v2bBounceBlocking
    case v1dTokenBudget
    case v2dTokenBudgetBlocking
    case v1eBounceTokens
    case v2eBounceTokensBlocking
    case v1cSenderChooses
    case v2cSenderChoosesBlocking
    case v1fSenderTokens
    case v2fSenderTokensBlocking

    var isExtended: Bool { self != .classic }
    var hasBlocking: Bool {
        [.v2MetaBlocking, .v2bBounceBlocking, .v2dTokenBudgetBlocking,
         .v2eBounceTokensBlocking, .v2cSenderChoosesBlocking, .v2fSenderTokensBlocking].contains(self)
    }
    var hasBounce: Bool {
        [.v1bBounce, .v2bBounceBlocking, .v1eBounceTokens, .v2eBounceTokensBlocking].contains(self)
    }
    var hasTokenBudget: Bool {
        [.v1dTokenBudget, .v2dTokenBudgetBlocking, .v1eBounceTokens,
         .v2eBounceTokensBlocking, .v1fSenderTokens, .v2fSenderTokensBlocking].contains(self)
    }
    var hasSenderChooses: Bool {
        [.v1cSenderChooses, .v2cSenderChoosesBlocking, .v1fSenderTokens, .v2fSenderTokensBlocking].contains(self)
    }
    var isEnabled: Bool {
        switch self {
        case .classic, .v1EdgeIntersection, .v2MetaBlocking, .v1dTokenBudget, .v2dTokenBudgetBlocking: return true
        default: return false
        }
    }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy, medium, hard
    var displayName: String { rawValue.capitalized }
    var avatarName: String {
        switch self { case .easy: return "Pixel"; case .medium: return "Nova"; case .hard: return "Apex" }
    }
    var description: String {
        switch self {
        case .easy: return "Picks a random legal move every turn."
        case .medium: return "Thinks ahead a bit. Will make reasonable moves but misses tactics."
        case .hard: return "Strong play. Will punish routing mistakes and exploit weak boards."
        }
    }
    var thinkTimeLabel: String {
        switch self { case .easy: return "Instant"; case .medium: return "~1s"; case .hard: return "~3s" }
    }
}

enum PlayMode {
    case vsComputer(side: Player, difficulty: Difficulty)
    case passAndPlay
    case online
}

struct TokenBudget: Codable, Equatable {
    var edgeTokens: Int
    var intersectionTokens: Int
    static let initial = TokenBudget(edgeTokens: 18, intersectionTokens: 6)
    var hasEdgeTokens: Bool { edgeTokens > 0 }
    var hasIntersectionTokens: Bool { intersectionTokens > 0 }
    var isDepletedEdge: Bool { edgeTokens <= 0 }
    var isDepletedIntersection: Bool { intersectionTokens <= 0 }
    var isFullyDepleted: Bool { edgeTokens <= 0 && intersectionTokens <= 0 }
}
