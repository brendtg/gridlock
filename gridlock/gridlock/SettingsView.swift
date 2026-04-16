import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            List {
                Section("Players") {
                    settingsRow {
                        HStack {
                            Label("Player 1 Name", systemImage: "circle")
                                .foregroundColor(AppTheme.player1Color)
                            Spacer()
                            TextField("Player 1", text: $settings.player1Name)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    settingsRow {
                        HStack {
                            Label("Player 2 Name", systemImage: "xmark")
                                .foregroundColor(AppTheme.player2Color)
                            Spacer()
                            TextField("Player 2", text: $settings.player2Name)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }

                Section("Gameplay") {
                    settingsToggle("Sound Effects", icon: "speaker.wave.2.fill", binding: $settings.soundEffectsEnabled)
                    settingsToggle("Haptics", icon: "iphone.radiowaves.left.and.right", binding: $settings.hapticsEnabled)
                    settingsToggle("Confirm Button", icon: "checkmark.circle.fill", binding: $settings.showConfirmButton)
                    settingsToggle("Routing Animation", icon: "arrow.right.circle.fill", binding: $settings.showRoutingAnimation)
                    settingsToggle("Auto-Zoom Active Board", icon: "arrow.up.left.and.arrow.down.right", binding: $settings.autoZoom)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .listRowBackground(AppTheme.surface)
            .foregroundColor(AppTheme.textPrimary)
    }

    private func settingsToggle(_ title: String, icon: String, binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Label(title, systemImage: icon)
                .foregroundColor(AppTheme.textPrimary)
        }
        .tint(AppTheme.secondary)
        .listRowBackground(AppTheme.surface)
    }
}
