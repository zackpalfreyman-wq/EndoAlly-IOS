import SwiftUI

struct LoginView: View {
    let onSwitch: () -> Void

    @StateObject private var auth = AuthService.shared
    @State private var email    = ""
    @State private var password = ""
    @State private var loading  = false
    @State private var error: String?

    var body: some View {
        ZStack {
            Color.warmWhite.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    HStack(spacing: 0) {
                        Text("Endo")
                            .font(.custom("DMSans-Regular", size: 32))
                            .foregroundColor(.charcoal)
                        Text("Ally")
                            .font(.custom("DMSans-Bold", size: 32))
                            .foregroundColor(.rose)
                    }
                    .padding(.top, 48)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome back")
                            .font(.custom("DMSans-SemiBold", size: 26))
                            .foregroundColor(.charcoal)
                        Text("Sign in to your account")
                            .font(.custom("DMSans-Regular", size: 14))
                            .foregroundColor(.slateMid)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.custom("DMSans-Medium", size: 13))
                                .foregroundColor(.charcoal)
                            TextField("your@email.com", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.custom("DMSans-Medium", size: 13))
                                .foregroundColor(.charcoal)
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                        }
                    }

                    if let error = error {
                        Text(error)
                            .font(.custom("DMSans-Regular", size: 13))
                            .foregroundColor(.rose)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.roseLight)
                            .cornerRadius(8)
                    }

                    Button(action: handleLogin) {
                        HStack {
                            if loading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign in")
                                    .font(.custom("DMSans-Bold", size: 15))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.rose)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(loading)
                    .opacity(loading ? 0.7 : 1)

                    Button(action: onSwitch) {
                        Text("Don't have an account? ")
                            .foregroundColor(.slateMid)
                        + Text("Sign up")
                            .foregroundColor(.rose)
                            .bold()
                    }
                    .font(.custom("DMSans-Regular", size: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func handleLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter your email and password."
            return
        }
        loading = true
        error = nil
        Task {
            do {
                try await auth.signIn(email: email.lowercased().trimmingCharacters(in: .whitespaces), password: password)
            } catch {
                self.error = error.localizedDescription
            }
            loading = false
        }
    }
}
