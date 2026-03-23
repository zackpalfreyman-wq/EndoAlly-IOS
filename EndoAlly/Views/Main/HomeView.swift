import SwiftUI

struct HomeView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm   = HomeViewModel()
    @State private var showCheckInSheet = false
    @State private var showSymptomLogger = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.warmWhite.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Greeting
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Hello, \(vm.profile?.name?.components(separatedBy: " ").first ?? "there") \(vm.profile?.emoji ?? "👤")")
                                    .font(.custom("DMSans-SemiBold", size: 28))
                                    .foregroundColor(.charcoal)
                                Spacer()
                            }
                            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                                .font(.custom("DMSans-Regular", size: 13))
                                .foregroundColor(.slateMid)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        // Check-in card
                        if let existing = vm.todayCheckIn {
                            CompletedCheckInCard(checkIn: existing) {
                                showCheckInSheet = true
                            } onDelete: {
                                Task { await vm.deleteCheckIn(existing) }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Cycle ring
                        if let cycleInfo = vm.cycleInfo {
                            CycleRingView(cycleInfo: cycleInfo)
                                .padding(.horizontal, 16)
                        } else {
                            CardView {
                                Text("Continue logging your cycle to unlock the cycle tracker, or update your cycle information in Profile.")
                                    .font(.custom("DMSans-Regular", size: 14))
                                    .foregroundColor(.slateMid)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 8)
                            }
                            .padding(.horizontal, 16)
                        }

                        // Symptom log card
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabel(text: "Symptom Log")

                                Button(action: { showSymptomLogger = true }) {
                                    Text("+ Log a symptom")
                                        .font(.custom("DMSans-Bold", size: 14))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.rose)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                if vm.recentSymptoms.isEmpty {
                                    Text("No symptoms logged yet. Use the button above to log your first.")
                                        .font(.custom("DMSans-Regular", size: 13))
                                        .foregroundColor(.slateMid)
                                        .padding(.top, 4)
                                } else {
                                    ForEach(vm.recentSymptoms.prefix(5)) { symptom in
                                        SymptomRowView(symptom: symptom) {
                                            Task { await vm.deleteSymptom(symptom) }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, vm.todayCheckIn == nil ? 80 : 20)
                    }
                }

                // Floating check-in prompt
                if vm.todayCheckIn == nil {
                    CheckInPromptBar {
                        showCheckInSheet = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCheckInSheet) {
            CheckInView(
                profile: vm.profile ?? Profile(id: ""),
                existing: vm.todayCheckIn
            ) { saved in
                vm.todayCheckIn = saved
                showCheckInSheet = false
            } onDelete: {
                vm.todayCheckIn = nil
                showCheckInSheet = false
            }
        }
        .sheet(isPresented: $showSymptomLogger) {
            if let profile = vm.profile {
                SymptomPickerSheet(profile: profile) { saved in
                    vm.recentSymptoms.insert(saved, at: 0)
                    showSymptomLogger = false
                }
            }
        }
        .task {
            if let uid = auth.currentUser?.id.uuidString {
                await vm.load(userId: uid)
            }
        }
        .onChange(of: auth.currentUser) { _, user in
            if let uid = user?.id.uuidString {
                Task { await vm.load(userId: uid) }
            }
        }
    }
}

// MARK: - Completed check-in card
struct CompletedCheckInCard: View {
    let checkIn: CheckIn
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SageCardView {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(Color.sage)
                    .frame(width: 36, height: 36)
                    .overlay(Text("✓").font(.system(size: 18, weight: .bold)).foregroundColor(.white))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily check-in complete")
                        .font(.custom("DMSans-Bold", size: 15))
                        .foregroundColor(.charcoal)
                    Text(checkInSummary)
                        .font(.custom("DMSans-Regular", size: 12))
                        .foregroundColor(.slateMid)
                        .lineLimit(2)
                }

                Spacer()

                HStack(spacing: 6) {
                    Button("Edit", action: onEdit)
                        .font(.custom("DMSans-SemiBold", size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.06))
                        .foregroundColor(.slateMid)
                        .cornerRadius(6)
                    Button("Delete", action: onDelete)
                        .font(.custom("DMSans-SemiBold", size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.06))
                        .foregroundColor(.rose)
                        .cornerRadius(6)
                }
            }
        }
    }

    private var checkInSummary: String {
        var parts: [String] = []
        if let flow = checkIn.flow { parts.append("Flow: \(flow.capitalized)") }
        if let pain = checkIn.painLevel { parts.append("Pain: \(pain)/5") }
        if let moods = checkIn.mood, !moods.isEmpty {
            parts.append("Mood: \(moods.map { $0.capitalized }.joined(separator: ", "))")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Prompt bar
struct CheckInPromptBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.rose)
                    .frame(width: 12, height: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily check-in")
                        .font(.custom("DMSans-Bold", size: 14))
                        .foregroundColor(.charcoal)
                    Text("Tap to complete today's entry")
                        .font(.custom("DMSans-Regular", size: 12))
                        .foregroundColor(.slateMid)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.roseLight)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.rose, lineWidth: 1.5))
            .shadow(color: Color.rose.opacity(0.22), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Model
@MainActor
class HomeViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var todayCheckIn: CheckIn?
    @Published var allCheckIns: [CheckIn] = []
    @Published var recentSymptoms: [Symptom] = []
    @Published var cycleInfo: CycleInfo?

    private let db = SupabaseService.shared

    func load(userId: String) async {
        async let profileTask   = try? db.fetchProfile(userId: userId)
        async let checkInsTask  = try? db.fetchCheckIns(userId: userId)
        async let symptomsTask  = try? db.fetchSymptoms(userId: userId)

        let (p, checkins, symptoms) = await (profileTask, checkInsTask, symptomsTask)

        self.profile        = p
        self.allCheckIns    = checkins ?? []
        self.recentSymptoms = Array((symptoms ?? []).prefix(20))

        let today = todayString()
        self.todayCheckIn = allCheckIns.first(where: { $0.date == today })

        if let profile = p {
            self.cycleInfo = getSmartCycleInfo(
                checkins: allCheckIns.map { ($0.date, $0.flow ?? "none") },
                profile: profile
            )
        }
    }

    func deleteCheckIn(_ checkIn: CheckIn) async {
        try? await db.deleteCheckIn(id: checkIn.id)
        self.todayCheckIn = nil
    }

    func deleteSymptom(_ symptom: Symptom) async {
        try? await db.deleteSymptom(id: symptom.id)
        self.recentSymptoms.removeAll { $0.id == symptom.id }
    }
}
