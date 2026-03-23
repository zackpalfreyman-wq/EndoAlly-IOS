import SwiftUI

struct SymptomLogView: View {
    let userId: String
    @StateObject private var vm = SymptomLogViewModel()
    @State private var showPicker = false
    @State private var profile: Profile?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmWhite.ignoresSafeArea()
                if vm.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            if vm.symptoms.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "list.bullet.clipboard")
                                        .font(.system(size: 40))
                                        .foregroundColor(.slateMid)
                                    Text("No symptoms logged yet.")
                                        .font(.custom("DMSans-Regular", size: 14))
                                        .foregroundColor(.slateMid)
                                }
                                .padding(.top, 60)
                            } else {
                                ForEach(vm.symptoms) { symptom in
                                    SymptomRowView(symptom: symptom) {
                                        Task { await vm.delete(symptom) }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }

                VStack {
                    Spacer()
                    Button(action: { showPicker = true }) {
                        Text("+ Log a symptom")
                            .font(.custom("DMSans-Bold", size: 15))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.rose)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Symptom Log")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showPicker) {
            if let p = profile {
                SymptomPickerSheet(profile: p) { saved in
                    vm.symptoms.insert(saved, at: 0)
                    showPicker = false
                }
            }
        }
        .task {
            await vm.load(userId: userId)
            profile = try? await SupabaseService.shared.fetchProfile(userId: userId)
        }
    }
}

@MainActor
class SymptomLogViewModel: ObservableObject {
    @Published var symptoms: [Symptom] = []
    @Published var isLoading = true

    func load(userId: String) async {
        isLoading = true
        symptoms = (try? await SupabaseService.shared.fetchSymptoms(userId: userId)) ?? []
        isLoading = false
    }

    func delete(_ symptom: Symptom) async {
        try? await SupabaseService.shared.deleteSymptom(id: symptom.id)
        symptoms.removeAll { $0.id == symptom.id }
    }
}
