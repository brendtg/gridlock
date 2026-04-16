import SwiftUI
import GameKit

struct OnlineLobbyView: View {
    @State private var isAuthenticated = false
    @State private var isAuthenticating = false
    let router: AppRouter

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "network")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.primary)
                    .padding(.top, 32)

                Text("Play Online")
                    .font(.sfRounded(28, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                if !isAuthenticated {
                    VStack(spacing: 16) {
                        Text("Sign in to Game Center to play online with friends or random opponents.")
                            .font(.sfRounded(15))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: authenticate) {
                            HStack {
                                if isAuthenticating {
                                    ProgressView().tint(.white)
                                }
                                Text(isAuthenticating ? "Signing in..." : "Sign in with Game Center")
                                    .font(.sfRounded(16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .disabled(isAuthenticating)
                        .padding(.horizontal, 32)
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("Signed in as \(GKLocalPlayer.local.displayName)")
                            .font(.sfRounded(14))
                            .foregroundColor(AppTheme.textSecondary)

                        Button(action: startMatch) {
                            Label("New Match", systemImage: "plus.circle.fill")
                                .font(.sfRounded(16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(AppTheme.secondary)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 32)

                        Text("Game Center handles matchmaking, async turns, and push notifications. No account or server needed beyond Game Center.")
                            .font(.sfRounded(12))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { checkAuth() }
    }

    private func checkAuth() {
        isAuthenticated = GKLocalPlayer.local.isAuthenticated
    }

    private func authenticate() {
        isAuthenticating = true
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            isAuthenticating = false
            if let vc = viewController {
                // Present the Game Center auth VC
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(vc, animated: true)
                }
            } else if error == nil {
                isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
        }
    }

    private func startMatch() {
        // Push to variant picker then into a GK match
        router.push(.variantPicker(mode: .online))
    }
}
