import SwiftUI

struct ProfileView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm   = ProfileViewModel()
    @State private var showEditProfile   = false
    @State private var showClearConfirm  = false
    @State private var showDeleteConfirm = false
    @State private var clearing  = false
    @State private var deleting  = false
    @State private var actionError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmWhite.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // About card
                        SageCardView {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel(text: "About EndoAlly", color: .sage)
                                Text("In Australia, the average time from first symptoms to diagnosis of Endometriosis is 6.4 years. EndoAlly aims to help reduce that delay, by giving you the tools to track your symptoms, and communicate them to your doctor.")
                                    .font(.custom("DMSans-Regular", size: 13))
                                    .foregroundColor(.charcoal)
                                    .lineSpacing(4)
                                Text("EndoAlly is a prototype health companion. It is not a medical device.")
                                    .font(.custom("DMSans-Regular", size: 12))
                                    .foregroundColor(.slateMid)
                                    .italic()
                            }
                        }
                        .padding(.horizontal, 16)

                        // Profile card
                        if let profile = vm.profile {
                            CardView {
                                VStack(spacing: 16) {
                                    HStack(spacing: 14) {
                                        Text(profile.emoji)
                                            .font(.system(size: 44))
                                            .frame(width: 64, height: 64)
                                            .background(Color.warmWhite)
                                            .cornerRadius(32)
                                            .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.appBorder, lineWidth: 1))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(profile.name ?? "Your Name")
                                                .font(.custom("DMSans-SemiBold", size: 20))
                                                .foregroundColor(.charcoal)
                                            if let age = profile.age {
                                                Text("Age \(age)")
                                                    .font(.custom("DMSans-Regular", size: 14))
                                                    .foregroundColor(.slateMid)
                                            }
                                        }
                                        Spacer()
                                        Button(action: { showEditProfile = true }) {
                                            Text("Edit")
                                                .font(.custom("DMSans-SemiBold", size: 13))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.warmWhite)
                                                .foregroundColor(.slateMid)
                                                .cornerRadius(8)
                                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                                        }
                                    }

                                    Divider()

                                    HStack(spacing: 0) {
                                        StatBlock(value: "\(vm.checkInCount)", label: "Check-ins")
                                        Divider().frame(height: 40)
                                        StatBlock(value: "\(profile.cycleLength ?? 28)", label: "Cycle days")
                                        Divider().frame(height: 40)
                                        StatBlock(value: "\(profile.periodLength ?? 5)", label: "Period days")
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Resources
                        CardView {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Resources & Support")
                                    .font(.custom("DMSans-SemiBold", size: 20))
                                    .foregroundColor(.charcoal)
                                    .padding(.bottom, 12)

                                ForEach(resources, id: \.label) { r in
                                    Link(destination: URL(string: r.url)!) {
                                        HStack {
                                            Text(r.label)
                                                .font(.custom("DMSans-Medium", size: 14))
                                                .foregroundColor(.charcoal)
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .foregroundColor(.slateMid)
                                                .font(.system(size: 12))
                                        }
                                        .padding(.vertical, 11)
                                        .overlay(Divider(), alignment: .bottom)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("CRISIS & EMERGENCY SUPPORT")
                                        .font(.custom("DMSans-Bold", size: 10).leading(.tight))
                                        .tracking(0.8)
                                        .foregroundColor(.slateMid)
                                        .padding(.top, 14)
                                    Text("Emergency — 000")
                                        .font(.custom("DMSans-Medium", size: 13))
                                        .foregroundColor(.charcoal)
                                    Text("Beyond Blue — 1300 22 4636")
                                        .font(.custom("DMSans-Medium", size: 13))
                                        .foregroundColor(.charcoal)
                                    Text("Lifeline — 13 11 14")
                                        .font(.custom("DMSans-Medium", size: 13))
                                        .foregroundColor(.charcoal)
                                }
                                .padding(12)
                                .background(Color.warmWhite)
                                .cornerRadius(10)
                                .padding(.top, 6)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Settings
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Settings")
                                    .font(.custom("DMSans-SemiBold", size: 20))
                                    .foregroundColor(.charcoal)

                                Button(action: { Task { try? await auth.signOut() } }) {
                                    Text("Sign out")
                                        .font(.custom("DMSans-SemiBold", size: 14))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.warmWhite)
                                        .foregroundColor(.charcoal)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                                }

                                if showClearConfirm {
                                    ConfirmBox(
                                        message: "This will permanently delete all your symptoms, check-ins, and health history. Your profile will be kept. This cannot be undone.",
                                        confirmLabel: clearing ? "Clearing…" : "Yes, clear all data",
                                        isLoading: clearing,
                                        onCancel: { showClearConfirm = false }
                                    ) {
                                        Task { await clearData() }
                                    }
                                } else {
                                    DangerButton(label: "Clear all my data") { showClearConfirm = true }
                                }

                                if showDeleteConfirm {
                                    ConfirmBox(
                                        message: "This will permanently delete your account and all your data. You can sign back up with the same email at any time.",
                                        confirmLabel: deleting ? "Deleting…" : "Yes, delete account",
                                        isLoading: deleting,
                                        onCancel: { showDeleteConfirm = false; actionError = nil }
                                    ) {
                                        Task { await deleteAccount() }
                                    }
                                } else {
                                    DangerButton(label: "Delete account") { showDeleteConfirm = true; actionError = nil }
                                }

                                if let err = actionError {
                                    Text(err)
                                        .font(.custom("DMSans-Regular", size: 12))
                                        .foregroundColor(.rose)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        Text("EndoAlly — Prototype · Version 2.0 · March 2026")
                            .font(.custom("DMSans-Regular", size: 11))
                            .foregroundColor(.slateMid)
                            .padding(.bottom, 20)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showEditProfile) {
            if let p = vm.profile {
                EditProfileView(profile: p) { updated in
                    vm.profile = updated
                    showEditProfile = false
                }
            }
        }
        .task {
            if let uid = auth.currentUser?.id.uuidString {
                await vm.load(userId: uid)
            }
        }
    }

    private func clearData() async {
        clearing = true
        if let uid = auth.currentUser?.id.uuidString {
            try? await SupabaseService.shared.clearAllData(userId: uid)
        }
        clearing = false
        showClearConfirm = false
    }

    private func deleteAccount() async {
        deleting = true
        do {
            try await auth.deleteAccount()
        } catch {
            actionError = "Something went wrong. Please try again."
        }
        deleting = false
        showDeleteConfirm = false
    }
}

// MARK: - Sub-views
struct StatBlock: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.custom("DMSans-Bold", size: 20)).foregroundColor(.charcoal)
            Text(label).font(.custom("DMSans-Regular", size: 11)).foregroundColor(.slateMid)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DangerButton: View {
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom("DMSans-Bold", size: 14))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.warmWhite)
                .foregroundColor(.rose)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct ConfirmBox: View {
    let message: String
    let confirmLabel: String
    let isLoading: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.custom("DMSans-Regular", size: 13))
                .foregroundColor(.rose)
                .lineSpacing(3)
            HStack(spacing: 8) {
                Button("Cancel", action: onCancel)
                    .font(.custom("DMSans-SemiBold", size: 13))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Color.warmWhite)
                    .foregroundColor(.slateMid)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                Spacer()
                Button(action: onConfirm) {
                    Text(isLoading ? confirmLabel : confirmLabel)
                        .font(.custom("DMSans-Bold", size: 13))
                }
                .disabled(isLoading)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color.rose)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color.roseLight)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
    }
}

// MARK: - Resources
private let resources: [(label: String, url: String)] = [
    (label: "Endometriosis Australia",        url: "https://endometriosisaustralia.org"),
    (label: "Jean Hailes for Women's Health", url: "https://jeanhailes.org.au/health-a-z/endometriosis"),
    (label: "RANZCOG Guidelines",             url: "https://ranzcog.edu.au"),
    (label: "healthdirect Australia",         url: "https://healthdirect.gov.au/endometriosis"),
    (label: "Pelvic Pain Foundation AU",      url: "https://www.pelvicpain.org.au/"),
]

// MARK: - View Model
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var checkInCount: Int = 0

    func load(userId: String) async {
        async let pTask  = try? SupabaseService.shared.fetchProfile(userId: userId)
        async let ciTask = try? SupabaseService.shared.fetchCheckIns(userId: userId)
        let (p, checkins) = await (pTask, ciTask)
        profile = p
        checkInCount = checkins?.count ?? 0
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    let profile: Profile
    let onSave: (Profile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var age: String
    @State private var cycleLength: String
    @State private var periodLength: String
    @State private var lastPeriodStart: String
    @State private var emoji: String
    @State private var cycleDontKnow: Bool
    @State private var periodDontKnow: Bool
    @State private var lastPeriodDontKnow: Bool
    @State private var saving = false
    @State private var error: String?

    private let emojis = ["👤","👩","🌸","🌹","❤️","💜","🌞","⭐","🌈","🌙","🦋","🐈","🐱","🍎","🍓","🍫","🌺","🐦","🦜","🐇","🐴","🐩","🦊","🐝"]

    init(profile: Profile, onSave: @escaping (Profile) -> Void) {
        self.profile = profile
        self.onSave  = onSave
        _name              = State(initialValue: profile.name ?? "")
        _age               = State(initialValue: profile.age.map { String($0) } ?? "")
        _cycleLength       = State(initialValue: String(profile.cycleLength ?? 28))
        _periodLength      = State(initialValue: String(profile.periodLength ?? 5))
        _lastPeriodStart   = State(initialValue: profile.lastPeriodStart ?? "")
        _emoji             = State(initialValue: profile.emoji)
        _cycleDontKnow     = State(initialValue: profile.cycleLength == nil)
        _periodDontKnow    = State(initialValue: profile.periodLength == nil)
        _lastPeriodDontKnow = State(initialValue: profile.lastPeriodStart == nil)
    }

    var body: some View {
        NavigationStack {
            ZStack { Color.warmWhite.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Emoji picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Profile emoji")
                                .font(.custom("DMSans-Medium", size: 13))
                                .foregroundColor(.charcoal)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                                ForEach(emojis, id: \.self) { e in
                                    Button(action: { emoji = e }) {
                                        Text(e).font(.system(size: 24))
                                            .frame(width: 40, height: 40)
                                            .background(emoji == e ? Color.roseLight : Color.warmWhite)
                                            .cornerRadius(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(emoji == e ? Color.rose : Color.appBorder, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        ProfileTextField(label: "Your name", value: $name, placeholder: "First name")
                        ProfileTextField(label: "Age", value: $age, placeholder: "e.g. 28", keyboardType: .numberPad)

                        ProfileNumberField(label: "Cycle length (days)", value: $cycleLength, dontKnow: $cycleDontKnow, defaultVal: "28", range: 21...45)
                        ProfileNumberField(label: "Period length (days)", value: $periodLength, dontKnow: $periodDontKnow, defaultVal: "5", range: 1...10)

                        // Last period start date
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Last period start date")
                                .font(.custom("DMSans-Medium", size: 13))
                                .foregroundColor(.charcoal)
                            if !lastPeriodDontKnow {
                                TextField("YYYY-MM-DD", text: $lastPeriodStart)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                            }
                            Toggle("I don't know", isOn: $lastPeriodDontKnow).tint(.rose)
                                .font(.custom("DMSans-Regular", size: 12))
                                .foregroundColor(.slateMid)
                        }

                        if let err = error {
                            Text(err).font(.custom("DMSans-Regular", size: 13)).foregroundColor(.rose)
                        }

                        Button(action: { Task { await handleSave() } }) {
                            HStack {
                                if saving { ProgressView().tint(.white) }
                                else { Text("Save changes").font(.custom("DMSans-Bold", size: 15)) }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.rose)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(saving)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.rose)
                }
            }
        }
    }

    private func handleSave() async {
        saving = true
        error  = nil
        let upsert = ProfileUpsert(
            id: profile.id,
            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? nil : name.trimmingCharacters(in: .whitespaces),
            age: Int(age),
            cycleLength: cycleDontKnow ? nil : Int(cycleLength),
            periodLength: periodDontKnow ? nil : Int(periodLength),
            lastPeriodStart: lastPeriodDontKnow ? nil : (lastPeriodStart.isEmpty ? nil : lastPeriodStart),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        do {
            let saved = try await SupabaseService.shared.upsertProfile(upsert)
            onSave(saved)
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}

// MARK: - Onboarding Profile View (first-time setup)
struct OnboardingView: View {
    let userId: String
    let onComplete: (Profile) -> Void

    @State private var step: OnboardingStep = .consent
    @State private var consentHealth = false
    @State private var consentAI     = false
    @State private var consentTerms  = false

    @State private var name = ""
    @State private var age  = ""
    @State private var cycleLength       = "28"
    @State private var periodLength      = "5"
    @State private var lastPeriodStart   = ""
    @State private var cycleDontKnow     = false
    @State private var periodDontKnow    = false
    @State private var lastPeriodDontKnow = false
    @State private var loading = false
    @State private var error: String?

    enum OnboardingStep { case consent, profile }

    private var allConsented: Bool { consentHealth && consentAI && consentTerms }

    var body: some View {
        ZStack {
            Color.warmWhite.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 0) {
                        Text("Endo").font(.custom("DMSans-Regular", size: 32)).foregroundColor(.charcoal)
                        Text("Ally").font(.custom("DMSans-Bold", size: 32)).foregroundColor(.rose)
                    }
                    .padding(.top, 40)

                    if step == .consent {
                        consentStep
                    } else {
                        profileSetupStep
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var consentStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Before we begin")
                    .font(.custom("DMSans-SemiBold", size: 26))
                    .foregroundColor(.charcoal)
                Text("EndoAlly collects health information to help you track your cycle and symptoms. Please read and agree to the following before continuing.")
                    .font(.custom("DMSans-Regular", size: 14))
                    .foregroundColor(.slateMid)
                    .lineSpacing(4)
            }

            VStack(spacing: 12) {
                ConsentRow(checked: $consentHealth,
                    title: "Health information",
                    body: "I consent to EndoAlly collecting and storing my menstrual cycle data, symptoms, and health history. I understand this is sensitive health information and will be stored securely in Australia.")

                ConsentRow(checked: $consentAI,
                    title: "AI processing",
                    body: "I understand that when I use the AI chat or generate reports, my symptom data is sent to Anthropic (USA) for processing. Anthropic does not use this data for training. No data is shared for advertising.")

                ConsentRow(checked: $consentTerms,
                    title: "Terms & Privacy",
                    body: "I have read and agree to the Terms and Conditions and Privacy Policy. I understand I can delete my account and all data at any time.")
            }

            Text("By continuing you confirm you are 18 years of age or older.")
                .font(.custom("DMSans-Regular", size: 12))
                .foregroundColor(.slateMid)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button(action: { step = .profile }) {
                Text("I agree — continue →")
                    .font(.custom("DMSans-Bold", size: 15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(allConsented ? Color.rose : Color.appBorder)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!allConsented)
        }
    }

    private var profileSetupStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome — let's get set up")
                    .font(.custom("DMSans-SemiBold", size: 26))
                    .foregroundColor(.charcoal)
                Text("This information helps personalise your cycle tracking. You can change it anytime from your profile.")
                    .font(.custom("DMSans-Regular", size: 14))
                    .foregroundColor(.slateMid)
            }

            ProfileTextField(label: "Your name", value: $name, placeholder: "First name")
            ProfileTextField(label: "Age", value: $age, placeholder: "e.g. 28", keyboardType: .numberPad)
            ProfileNumberField(label: "Cycle length (days)", value: $cycleLength, dontKnow: $cycleDontKnow, defaultVal: "28", range: 21...45)
            ProfileNumberField(label: "Period length (days)", value: $periodLength, dontKnow: $periodDontKnow, defaultVal: "5", range: 1...10)

            VStack(alignment: .leading, spacing: 6) {
                Text("When did your last period start?")
                    .font(.custom("DMSans-Medium", size: 13))
                    .foregroundColor(.charcoal)
                if !lastPeriodDontKnow {
                    TextField("YYYY-MM-DD", text: $lastPeriodStart)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                }
                Toggle("I don't know", isOn: $lastPeriodDontKnow).tint(.rose)
                    .font(.custom("DMSans-Regular", size: 12))
                    .foregroundColor(.slateMid)
                Text("This allows your cycle ring to show the correct phase.")
                    .font(.custom("DMSans-Regular", size: 11))
                    .foregroundColor(.slateMid)
            }

            if let err = error {
                Text(err).font(.custom("DMSans-Regular", size: 13)).foregroundColor(.rose)
                    .padding(12).background(Color.roseLight).cornerRadius(8)
            }

            HStack(spacing: 10) {
                Image(systemName: "lock.fill").foregroundColor(.sage)
                Text("Your data is stored privately in your account. It is never shared and never used for advertising. You can delete everything from your Profile at any time.")
                    .font(.custom("DMSans-Regular", size: 13))
                    .foregroundColor(.slateMid)
            }
            .padding(14)
            .background(Color.sageLight)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))

            Button(action: { Task { await handleSubmit() } }) {
                HStack {
                    if loading { ProgressView().tint(.white) }
                    else { Text("Get started →").font(.custom("DMSans-Bold", size: 15)) }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.rose)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(loading)
        }
    }

    private func handleSubmit() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { error = "Please enter your name."; return }
        loading = true; error = nil
        let upsert = ProfileUpsert(
            id: userId,
            name: name.trimmingCharacters(in: .whitespaces),
            age: Int(age),
            cycleLength: cycleDontKnow ? nil : (Int(cycleLength) ?? 28),
            periodLength: periodDontKnow ? nil : (Int(periodLength) ?? 5),
            lastPeriodStart: lastPeriodDontKnow ? nil : (lastPeriodStart.isEmpty ? nil : lastPeriodStart),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        do {
            let saved = try await SupabaseService.shared.upsertProfile(upsert)
            onComplete(saved)
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

// MARK: - Consent Row
struct ConsentRow: View {
    @Binding var checked: Bool
    let title: String
    let body: String

    var body: some View {
        Button(action: { checked.toggle() }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(checked ? .rose : .slateMid)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("DMSans-SemiBold", size: 14))
                        .foregroundColor(.charcoal)
                    Text(body)
                        .font(.custom("DMSans-Regular", size: 13))
                        .foregroundColor(.charcoal)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(3)
                }
            }
            .padding(14)
            .background(Color.warmWhite)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(checked ? Color.rose : Color.appBorder, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Form field helpers
struct ProfileTextField: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.custom("DMSans-Medium", size: 13)).foregroundColor(.charcoal)
            TextField(placeholder, text: $value)
                .keyboardType(keyboardType)
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
        }
    }
}

struct ProfileNumberField: View {
    let label: String
    @Binding var value: String
    @Binding var dontKnow: Bool
    let defaultVal: String
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.custom("DMSans-Medium", size: 13)).foregroundColor(.charcoal)
            TextField(defaultVal, text: $value)
                .keyboardType(.numberPad)
                .disabled(dontKnow)
                .opacity(dontKnow ? 0.5 : 1)
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
            Toggle("I don't know — use default (\(defaultVal))", isOn: $dontKnow).tint(.rose)
                .font(.custom("DMSans-Regular", size: 12))
                .foregroundColor(.slateMid)
        }
    }
}
