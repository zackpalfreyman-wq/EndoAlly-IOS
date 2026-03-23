import SwiftUI

struct ReportsView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm   = ReportsViewModel()
    @State private var selectedType: ReportType?
    @State private var generatedContent: String?
    @State private var generating: String?
    @State private var genError: String?
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmWhite.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reports")
                                .font(.custom("DMSans-SemiBold", size: 28))
                                .foregroundColor(.charcoal)
                            Text("Generate a report to share with your healthcare provider.")
                                .font(.custom("DMSans-Regular", size: 13))
                                .foregroundColor(.slateMid)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        if let err = genError {
                            Text(err)
                                .font(.custom("DMSans-Regular", size: 13))
                                .foregroundColor(.rose)
                                .padding(12)
                                .background(Color.roseLight)
                                .cornerRadius(8)
                                .padding(.horizontal, 16)
                        }

                        ForEach(reportTypes, id: \.id) { rt in
                            ReportTypeCard(
                                reportType: rt,
                                isGenerating: generating == rt.id
                            ) {
                                Task { await handleSelect(rt) }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showDetail) {
            if let rt = selectedType {
                ReportDetailView(
                    reportType: rt,
                    content: generatedContent,
                    profile: vm.profile,
                    symptoms: vm.symptoms,
                    medications: vm.medications,
                    birthControls: vm.birthControls,
                    treatments: vm.treatments,
                    therapies: vm.therapies,
                    familyHistory: vm.familyHistory
                ) {
                    showDetail = false
                    selectedType = nil
                    generatedContent = nil
                }
            }
        }
        .task {
            if let uid = auth.currentUser?.id.uuidString {
                await vm.load(userId: uid)
            }
        }
    }

    private func handleSelect(_ rt: ReportType) async {
        genError = nil
        generatedContent = nil

        if !rt.usesAI {
            selectedType = rt
            showDetail = true
            return
        }

        generating = rt.id
        do {
            let prompt = AnthropicService.shared.buildReportPrompt(
                type: rt.id,
                profile: vm.profile,
                symptoms: vm.symptoms,
                medications: vm.medications,
                birthControls: vm.birthControls,
                treatments: vm.treatments,
                therapies: vm.therapies,
                familyHistory: vm.familyHistory
            )
            let content = try await AnthropicService.shared.generateReport(prompt: prompt)
            generatedContent = content
            selectedType = rt
            showDetail = true
        } catch {
            genError = "Failed to generate report: \(error.localizedDescription)"
        }
        generating = nil
    }
}

// MARK: - Report Type Card
struct ReportTypeCard: View {
    let reportType: ReportType
    let isGenerating: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CardView {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(reportType.label)
                                .font(.custom("DMSans-SemiBold", size: 16))
                                .foregroundColor(.charcoal)
                            if reportType.usesAI {
                                Text("AI")
                                    .font(.custom("DMSans-Bold", size: 10))
                                    .foregroundColor(.rose)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.roseLight)
                                    .cornerRadius(4)
                            }
                        }
                        Text(reportType.description)
                            .font(.custom("DMSans-Regular", size: 13))
                            .foregroundColor(.slateMid)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    if isGenerating {
                        ProgressView().tint(.rose)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.slateMid)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isGenerating)
    }
}

// MARK: - View Model
@MainActor
class ReportsViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var symptoms: [Symptom] = []
    @Published var medications: [HistoryMedication] = []
    @Published var birthControls: [BirthControl] = []
    @Published var treatments: [Treatment] = []
    @Published var therapies: [Therapy] = []
    @Published var familyHistory: [FamilyHistory] = []

    func load(userId: String) async {
        async let pTask  = try? SupabaseService.shared.fetchProfile(userId: userId)
        async let sTask  = try? SupabaseService.shared.fetchSymptoms(userId: userId)
        async let mTask  = try? SupabaseService.shared.fetchMedications(userId: userId)
        async let bcTask = try? SupabaseService.shared.fetchBirthControl(userId: userId)
        async let tTask  = try? SupabaseService.shared.fetchTreatments(userId: userId)
        async let thTask = try? SupabaseService.shared.fetchTherapies(userId: userId)
        async let fhTask = try? SupabaseService.shared.fetchFamilyHistory(userId: userId)

        let (p, s, m, bc, t, th, fh) = await (pTask, sTask, mTask, bcTask, tTask, thTask, fhTask)
        profile = p
        symptoms = s ?? []
        medications = m ?? []
        birthControls = bc ?? []
        treatments = t ?? []
        therapies = th ?? []
        familyHistory = fh ?? []
    }
}
