import SwiftUI

struct SignUpView: View {
    let onSwitch: () -> Void

    @StateObject private var auth = AuthService.shared
    @State private var email    = ""
    @State private var password = ""
    @State private var confirm  = ""
    @State private var loading  = false
    @State private var error: String?
    @State private var success  = false

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
                        Text("Create your account")
                            .font(.custom("DMSans-SemiBold", size: 26))
                            .foregroundColor(.charcoal)
                        Text("Track your symptoms and cycle")
                            .font(.custom("DMSans-Regular", size: 14))
                            .foregroundColor(.slateMid)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if success {
                        VStack(spacing: 10) {
                            Text("Check your email")
                                .font(.custom("DMSans-SemiBold", size: 18))
                                .foregroundColor(.charcoal)
                            Text("We sent a confirmation link to \(email). Click it, then sign in.")
                                .font(.custom("DMSans-Regular", size: 14))
                                .foregroundColor(.slateMid)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .background(Color.sageLight)
                        .cornerRadius(10)

                        Button(action: onSwitch) {
                            Text("Go to sign in")
                                .font(.custom("DMSans-Bold", size: 15))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.rose)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
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
                                SecureField("At least 8 characters", text: $password)
                                    .textContentType(.newPassword)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm password")
                                    .font(.custom("DMSans-Medium", size: 13))
                                    .foregroundColor(.charcoal)
                                SecureField("Repeat password", text: $confirm)
                                    .textContentType(.newPassword)
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

                        Button(action: handleSignUp) {
                            HStack {
                                if loading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create account")
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
                            Text("Already have an account? ")
                                .foregroundColor(.slateMid)
                            + Text("Sign in")
                                .foregroundColor(.rose)
                                .bold()
                        }
                        .font(.custom("DMSans-Regular", size: 14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func handleSignUp() {
        error = nil
        guard !email.isEmpty else { error = "Please enter your email."; return }
        guard password.count >= 8 else { error = "Password must be at least 8 characters."; return }
        guard password == confirm else { error = "Passwords do not match."; return }

        loading = true
        Task {
            do {
                try await auth.signUp(
                    email: email.lowercased().trimmingCharacters(in: .whitespaces),
                    password: password
                )
                success = true
            } catch {
                self.error = error.localizedDescription
            }
            loading = false
        }
    }
}
