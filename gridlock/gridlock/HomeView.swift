import SwiftUI

struct HomeView: View {
    @State private var vm: HomeViewModel

    init(router: AppRouter, settings: SettingsStore) {
        _vm = State(initialValue: HomeViewModel(router: router, settings: settings))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                // Logo
                VStack(spacing: 8) {
                    Text("GRIDLOCK")
                        .font(.sfRounded(48, weight: .black))
                        .foregroundColor(AppTheme.textPrimary)
                        .tracking(6)
                    Text("Ultimate Tic-Tac-Toe")
                        .font(.sfRounded(16, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                // CTAs
                VStack(spacing: 16) {
                    HomeButton(title: "Play vs Computer", icon: "cpu", isPrimary: true) {
                        vm.startVsComputer()
                    }
                    HomeButton(title: "Pass & Play", icon: "person.2.fill", isPrimary: false) {
                        vm.startPassAndPlay()
                    }
                    HomeButton(title: "Play Online", icon: "network", isPrimary: false) {
                        vm.startOnline()
                    }
                }
                .padding(.horizontal, 32)
                // Secondary actions
                HStack(spacing: 40) {
                    Button(action: vm.openHowToPlay) {
                        VStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.title2)
                            Text("How to Play")
                                .font(.sfRounded(12))
                        }
                        .foregroundColor(AppTheme.textSecondary)
                    }
                    Button(action: vm.openSettings) {
                        VStack(spacing: 4) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                            Text("Settings")
                                .font(.sfRounded(12))
                        }
                        .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct HomeButton: View {
    let title: String
    let icon: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.sfRounded(18, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isPrimary ? AppTheme.secondary : AppTheme.surface)
            .foregroundColor(AppTheme.textPrimary)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isPrimary ? Color.clear : AppTheme.primary.opacity(0.4), lineWidth: 1)
            )
        }
    }
}
