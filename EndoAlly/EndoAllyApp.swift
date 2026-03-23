import SwiftUI

@main
struct EndoAllyApp: App {
    @StateObject private var auth = AuthService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @StateObject private var auth = AuthService.shared
    @State private var profileLoaded = false
    @State private var profileExists = false
    @State private var checkingProfile = false

    var body: some View {
        Group {
            if auth.isLoading {
                SplashView()
            } else if let user = auth.currentUser {
                if checkingProfile {
                    SplashView()
                } else if profileExists {
                    MainTabView()
                } else {
                    OnboardingView(userId: user.id.uuidString) { _ in
                        profileExists = true
                    }
                }
            } else {
                AuthView()
            }
        }
        .onAppear {
            auth.startListening()
        }
        .onChange(of: auth.currentUser) { _, user in
            if let user = user {
                Task { await checkProfile(userId: user.id.uuidString) }
            } else {
                profileExists = false
                profileLoaded = false
            }
        }
        .task {
            if let user = auth.currentUser {
                await checkProfile(userId: user.id.uuidString)
            }
        }
    }

    private func checkProfile(userId: String) async {
        checkingProfile = true
        do {
            let p = try await SupabaseService.shared.fetchProfile(userId: userId)
            profileExists = p.name != nil && !p.name!.isEmpty
        } catch {
            profileExists = false
        }
        checkingProfile = false
        profileLoaded   = true
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.warmWhite.ignoresSafeArea()
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    Text("Endo")
                        .font(.custom("DMSans-Regular", size: 40))
                        .foregroundColor(.charcoal)
                    Text("Ally")
                        .font(.custom("DMSans-Bold", size: 40))
                        .foregroundColor(.rose)
                }
                ProgressView()
                    .tint(.rose)
                    .scaleEffect(0.8)
            }
        }
    }
}
