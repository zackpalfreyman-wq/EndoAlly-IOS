import SwiftUI

struct AuthView: View {
    @State private var showLogin = false

    var body: some View {
        if showLogin {
            LoginView(onSwitch: { showLogin = false })
        } else {
            SignUpView(onSwitch: { showLogin = true })
        }
    }
}
