import SwiftUI

struct DifficultyPickerView: View {
    @State private var vm: DifficultyPickerViewModel

    init(router: AppRouter, variant: GameVariant, settings: SettingsStore) {
        _vm = State(initialValue: DifficultyPickerViewModel(router: router, variant: variant, settings: settings))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Choose Difficulty")
                        .font(.sfRounded(28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(VariantMetadata.info(for: vm.variant).displayName)
                        .font(.sfRounded(14))
                        .foregroundColor(AppTheme.secondary)
                }
                .padding(.top, 16)

                // Three difficulty cards
                HStack(spacing: 12) {
                    ForEach(vm.cards) { card in
                        DifficultyCardView(card: card) {
                            vm.select(card.id)
                        }
                    }
                }
                .padding(.horizontal)

                // Side picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Play as")
                        .font(.sfRounded(14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    HStack(spacing: 12) {
                        SidePillButton(label: "Blue (First)", color: AppTheme.player1Color,
                                       isSelected: vm.selectedSide == .p1) {
                            vm.selectedSide = .p1
                        }
                        SidePillButton(label: "Pink (Second)", color: AppTheme.player2Color,
                                       isSelected: vm.selectedSide == .p2) {
                            vm.selectedSide = .p2
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button(action: vm.start) {
                    Text("Start Game")
                        .font(.sfRounded(18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.secondary)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct DifficultyCardView: View {
    let card: DifficultyCardItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: card.avatarSystemImage)
                    .font(.system(size: 36))
                    .foregroundColor(card.isSelected ? AppTheme.secondary : AppTheme.textSecondary)
                Text(card.displayName)
                    .font(.sfRounded(15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(card.thinkTimeLabel)
                    .font(.sfRounded(11))
                    .foregroundColor(AppTheme.textSecondary)
                Text(card.description)
                    .font(.sfRounded(11))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(AppTheme.surface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(card.isSelected ? AppTheme.secondary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SidePillButton: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(label).font(.sfRounded(13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.2) : AppTheme.surface)
            .foregroundColor(isSelected ? color : AppTheme.textSecondary)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? color : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
