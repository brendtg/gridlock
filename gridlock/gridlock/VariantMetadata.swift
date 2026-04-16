import Foundation

struct VariantInfo {
    let variant: GameVariant
    let displayName: String
    let subtitle: String
    let description: String
    let recommendedFor: String
    let isEnabled: Bool
    let hasBalanceWarning: Bool
    let badge: String?
}

enum VariantMetadata {
    static let all: [VariantInfo] = [
        VariantInfo(
            variant: .classic,
            displayName: "Classic",
            subtitle: "",
            description: "The original game. Each move sends your opponent to the matching sub-board. Simple to learn, sharp to master.",
            recommendedFor: "Everyone. Learn this first.",
            isEnabled: true,
            hasBalanceWarning: false,
            badge: nil
        ),
        VariantInfo(
            variant: .v1EdgeIntersection,
            displayName: "Extended Board",
            subtitle: "Adds edge & intersection positions",
            description: "Each sub-board now has 25 positions instead of 9. Edges and intersections are shared between boards and route your opponent to multiple possible boards.",
            recommendedFor: "Players who know Classic",
            isEnabled: true,
            hasBalanceWarning: false,
            badge: nil
        ),
        VariantInfo(
            variant: .v2MetaBlocking,
            displayName: "Extended + Blocking",
            subtitle: "Extended board with strategic blocking",
            description: "Extended Board rules, plus: placing on a shared edge blocks your opponent's long-win lines through that edge. Routing and defence become one action.",
            recommendedFor: "Advanced players",
            isEnabled: true,
            hasBalanceWarning: false,
            badge: nil
        ),
        VariantInfo(
            variant: .v1bBounce,
            displayName: "Extended + Bounce",
            subtitle: "Routing bounces off finished boards",
            description: "Extended Board rules. When routing sends your opponent to a finished board, they bounce to the nearest open board instead of choosing freely.",
            recommendedFor: "Intermediate players",
            isEnabled: false,
            hasBalanceWarning: false,
            badge: nil
        ),
        VariantInfo(
            variant: .v2bBounceBlocking,
            displayName: "Extended + Bounce + Blocking",
            subtitle: "",
            description: "Drop-in improvement over base V2. Bounce routing corrects a P1 routing advantage.",
            recommendedFor: "Advanced players",
            isEnabled: false,
            hasBalanceWarning: false,
            badge: nil
        ),
        VariantInfo(
            variant: .v1dTokenBudget,
            displayName: "Token Rush",
            subtitle: "Spend tokens for powerful moves",
            description: "Each player has 18 edge tokens and 6 intersection tokens for the whole game. Spend them wisely in the opening — once gone, you play cell-only, like Classic.",
            recommendedFor: "Strategy enthusiasts",
            isEnabled: true,
            hasBalanceWarning: false,
            badge: nil
        ),
        VariantInfo(
            variant: .v2dTokenBudgetBlocking,
            displayName: "Token Rush + Blocking",
            subtitle: "Token economy with meta-blocking — best balanced extended variant",
            description: "Token Rush rules combined with meta-blocking. The most balanced extended variant in simulation testing. Recommended starting point for experienced players.",
            recommendedFor: "Advanced players",
            isEnabled: true,
            hasBalanceWarning: false,
            badge: "Best Extended"
        ),
        VariantInfo(
            variant: .v1eBounceTokens,
            displayName: "Bounce + Token Rush",
            subtitle: "",
            description: "Token budget combined with bounce routing. Bounce prevents free-move gifts; token depletion forces a Classic-like endgame.",
            recommendedFor: "Experimental",
            isEnabled: false,
            hasBalanceWarning: false,
            badge: nil
        ),
        VariantInfo(
            variant: .v2eBounceTokensBlocking,
            displayName: "Full Experiment",
            subtitle: "Bounce + Tokens + Blocking (high draw rate — enable with care)",
            description: "All three rules: Bounce + Token Rush + Blocking. Closest to Classic's sharpness — but ~34% draw rate. House rule: suspend token limit when only one board remains.",
            recommendedFor: "Experimental",
            isEnabled: false,
            hasBalanceWarning: false,
            badge: "Experimental"
        ),
        VariantInfo(
            variant: .v1cSenderChooses,
            displayName: "Sender Chooses",
            subtitle: "",
            description: "You choose which board to route your opponent to. Large balance issues under strategic play.",
            recommendedFor: "Experimental",
            isEnabled: false,
            hasBalanceWarning: true,
            badge: nil
        ),
        VariantInfo(
            variant: .v2cSenderChoosesBlocking,
            displayName: "Sender Chooses + Blocking",
            subtitle: "",
            description: "Sender-chooses routing with meta-blocking. Balance warning: P1 wins ~54% under AI play.",
            recommendedFor: "Experimental",
            isEnabled: false,
            hasBalanceWarning: true,
            badge: nil
        ),
        VariantInfo(
            variant: .v1fSenderTokens,
            displayName: "Sender + Token Rush",
            subtitle: "",
            description: "Sender-chooses with token budget. Inherits balance issues.",
            recommendedFor: "Experimental",
            isEnabled: false,
            hasBalanceWarning: true,
            badge: nil
        ),
        VariantInfo(
            variant: .v2fSenderTokensBlocking,
            displayName: "Sender + Token Rush + Blocking",
            subtitle: "",
            description: "Sender-chooses with token budget and blocking. Inherits balance issues.",
            recommendedFor: "Experimental",
            isEnabled: false,
            hasBalanceWarning: true,
            badge: nil
        ),
    ]

    static func info(for variant: GameVariant) -> VariantInfo {
        all.first { $0.variant == variant }!
    }

    static var enabledVariants: [GameVariant] {
        all.filter(\.isEnabled).map(\.variant)
    }
}
