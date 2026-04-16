import SwiftUI

struct VariantPickerView: View {
    @State private var vm: VariantPickerViewModel

    init(router: AppRouter, mode: RouteMode, settings: SettingsStore) {
        _vm = State(initialValue: VariantPickerViewModel(router: router, mode: mode, settings: settings))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Variant")
                        .font(.sfRounded(28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Select the ruleset for this game")
                        .font(.sfRounded(14))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.rows) { row in
                            VariantRowView(row: row) {
                                vm.select(row.id)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }

                // Confirm button
                VStack {
                    Button(action: vm.confirm) {
                        Text("Continue")
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
                .background(AppTheme.background.opacity(0.95))
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct VariantRowView: View {
    let row: VariantRowItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(row.isSelected ? AppTheme.secondary : AppTheme.textSecondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if row.isSelected {
                        Circle()
                            .fill(AppTheme.secondary)
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(row.displayName)
                            .font(.sfRounded(16, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        if let badge = row.badge {
                            Text(badge)
                                .font(.sfRounded(10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.secondary)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        if row.hasBalanceWarning {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    if !row.subtitle.isEmpty {
                        Text(row.subtitle)
                            .font(.sfRounded(12))
                            .foregroundColor(AppTheme.secondary)
                    }
                    Text(row.description)
                        .font(.sfRounded(13))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Best for: \(row.recommendedFor)")
                        .font(.sfRounded(12, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                        .padding(.top, 2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(row.isSelected ? AppTheme.surface.opacity(1.2) : AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(row.isSelected ? AppTheme.secondary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
