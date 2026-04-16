import SwiftUI
import Observation

struct VariantRowItem: Identifiable {
    let id: GameVariant
    let displayName: String
    let subtitle: String
    let description: String
    let recommendedFor: String
    let hasBalanceWarning: Bool
    let badge: String?
    var isSelected: Bool
}

@Observable
final class VariantPickerViewModel {
    let router: AppRouter
    let mode: RouteMode
    let settings: SettingsStore
    var selectedVariant: GameVariant = .classic

    init(router: AppRouter, mode: RouteMode, settings: SettingsStore) {
        self.router = router
        self.mode = mode
        self.settings = settings
    }

    var rows: [VariantRowItem] {
        VariantMetadata.enabledVariants.map { v in
            let info = VariantMetadata.info(for: v)
            return VariantRowItem(
                id: v,
                displayName: info.displayName,
                subtitle: info.subtitle,
                description: info.description,
                recommendedFor: info.recommendedFor,
                hasBalanceWarning: info.hasBalanceWarning,
                badge: info.badge,
                isSelected: selectedVariant == v
            )
        }
    }

    func select(_ variant: GameVariant) {
        selectedVariant = variant
    }

    func confirm() {
        switch mode {
        case .vsComputer:
            router.push(.difficultyPicker(variant: selectedVariant))
        case .passAndPlay:
            let config = GameConfig.passAndPlay(
                variant: selectedVariant,
                p1Name: settings.player1Name,
                p2Name: settings.player2Name
            )
            router.push(.game(config: config))
        case .online:
            let config = GameConfig.online(variant: selectedVariant)
            router.push(.game(config: config))
        }
    }
}
