import SwiftUI

struct HistoryView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm   = HistoryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmWhite.ignoresSafeArea()
                if vm.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Health History")
                                    .font(.custom("DMSans-SemiBold", size: 28))
                                    .foregroundColor(.charcoal)
                                Text("Your history is used to populate reports and the symptom logger.")
                                    .font(.custom("DMSans-Regular", size: 13))
                                    .foregroundColor(.slateMid)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            Divider().padding(.horizontal, 16)

                            HistoryFormViews(vm: vm)
                                .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            if let uid = auth.currentUser?.id.uuidString {
                await vm.load(userId: uid)
            }
        }
    }
}

// MARK: - View Model
@MainActor
class HistoryViewModel: ObservableObject {
    @Published var familyHistory: [FamilyHistory]    = []
    @Published var medications: [HistoryMedication]  = []
    @Published var birthControls: [BirthControl]     = []
    @Published var treatments: [Treatment]           = []
    @Published var therapies: [Therapy]              = []
    @Published var isLoading = true
    var userId: String = ""

    let db = SupabaseService.shared

    func load(userId: String) async {
        self.userId = userId
        isLoading = true
        async let fTask  = try? db.fetchFamilyHistory(userId: userId)
        async let mTask  = try? db.fetchMedications(userId: userId)
        async let bcTask = try? db.fetchBirthControl(userId: userId)
        async let tTask  = try? db.fetchTreatments(userId: userId)
        async let thTask = try? db.fetchTherapies(userId: userId)
        let (f, m, bc, t, th) = await (fTask, mTask, bcTask, tTask, thTask)
        familyHistory = f ?? []
        medications   = m ?? []
        birthControls = bc ?? []
        treatments    = t ?? []
        therapies     = th ?? []
        isLoading = false
    }
}
