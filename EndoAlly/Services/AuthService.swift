import Foundation
import Supabase

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isLoading: Bool = true

    private let client = SupabaseService.shared.client

    private init() {}

    func startListening() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                switch event {
                case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                    self.currentUser = session?.user
                case .signedOut, .passwordRecovery, .userDeleted:
                    self.currentUser = nil
                default:
                    break
                }
                self.isLoading = false
            }
        }
    }

    func signUp(email: String, password: String) async throws {
        let session = try await client.auth.signUp(email: email, password: password)
        self.currentUser = session.user
    }

    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        self.currentUser = session.user
    }

    func signOut() async throws {
        try await client.auth.signOut()
        self.currentUser = nil
    }

    func deleteAccount() async throws {
        // Delete all data first, then delete the auth user via Supabase admin or edge function.
        // For client-side: sign out. Full deletion requires a backend/edge function call.
        if let uid = currentUser?.id.uuidString {
            try await SupabaseService.shared.clearAllData(userId: uid)
        }
        // Sign out — a proper delete-account endpoint is needed for full auth user deletion.
        try await client.auth.signOut()
        self.currentUser = nil
    }
}
