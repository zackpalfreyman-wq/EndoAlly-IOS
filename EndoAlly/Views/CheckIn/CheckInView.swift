import SwiftUI

struct CheckInView: View {
    let profile: Profile
    let existing: CheckIn?
    let onSave: (CheckIn) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: CheckInViewModel

    init(profile: Profile, existing: CheckIn?, onSave: @escaping (CheckIn) -> Void, onDelete: (() -> Void)? = nil) {
        self.profile = profile
        self.existing = existing
        self.onSave = onSave
        self.onDelete = onDelete
        _vm = StateObject(wrappedValue: CheckInViewModel(existing: existing))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmWhite.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        SectionLabel(text: existing != nil ? "Edit Check-in" : "Daily Check-in")
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("How are you today?")
                            .font(.custom("DMSans-SemiBold", size: 22))
                            .foregroundColor(.charcoal)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 12) {
                            CollapsibleSection(title: "Period", summary: vm.periodSummary) {
                                VStack(alignment: .leading, spacing: 16) {
                                    FieldSection(label: "Period flow") {
                                        SingleChipGroup(options: flowOptions, labelFor: { $0.capitalized }, selected: vm.flow) { vm.flow = $0 }
                                    }
                                    FieldSection(label: "Pain level") {
                                        SingleChipGroup(options: [0,1,2,3,4,5], labelFor: { String($0) }, selected: vm.pain) { vm.pain = $0 }
                                    }
                                }
                            }

                            CollapsibleSection(title: "Mood & Energy", summary: vm.moodSummary) {
                                VStack(alignment: .leading, spacing: 16) {
                                    FieldSection(label: "Mood (select all that apply)") {
                                        ChipGroup(options: moodOptions, labelFor: { $0.capitalized }, selected: Set(vm.mood)) { val in
                                            if vm.mood.contains(val) { vm.mood.removeAll { $0 == val } }
                                            else { vm.mood.append(val) }
                                        }
                                    }
                                    FieldSection(label: "Energy") {
                                        SingleChipGroup(options: energyOptions, labelFor: { $0.capitalized }, selected: vm.energy) { vm.energy = $0 }
                                    }
                                }
                            }

                            CollapsibleSection(title: "Symptoms", summary: vm.symptomSummary) {
                                VStack(alignment: .leading, spacing: 16) {
                                    FieldSection(label: "Bloating") {
                                        SingleChipGroup(options: bloatOptions, labelFor: { $0.capitalized }, selected: vm.bloating) { vm.bloating = $0 }
                                    }
                                    FieldSection(label: "Nausea") {
                                        HStack(spacing: 8) {
                                            Chip(label: "No",  selected: vm.nausea == false) { vm.nausea = vm.nausea == false ? nil : false }
                                            Chip(label: "Yes", selected: vm.nausea == true)  { vm.nausea = vm.nausea == true  ? nil : true }
                                        }
                                    }
                                    FieldSection(label: "Bowel changes (select all that apply)") {
                                        ChipGroup(options: bowelOptions, labelFor: { $0.capitalized }, selected: Set(vm.bowel)) { val in
                                            if vm.bowel.contains(val) { vm.bowel.removeAll { $0 == val } }
                                            else { vm.bowel.append(val) }
                                        }
                                    }
                                    FieldSection(label: "Discharge") {
                                        SingleChipGroup(options: dischargeOptions, labelFor: { dischargeLabels[$0] ?? $0 }, selected: vm.discharge) { vm.discharge = $0 }
                                    }
                                }
                            }

                            CollapsibleSection(title: "Sleep", summary: vm.sleep?.capitalized ?? "") {
                                FieldSection(label: "Sleep quality") {
                                    SingleChipGroup(options: sleepOptions, labelFor: { $0.capitalized }, selected: vm.sleep) { vm.sleep = $0 }
                                }
                            }

                            CollapsibleSection(title: "Notes", summary: vm.notes.isEmpty ? "" : String(vm.notes.prefix(40))) {
                                TextEditor(text: $vm.notes)
                                    .font(.custom("DMSans-Regular", size: 14))
                                    .frame(minHeight: 80)
                                    .padding(10)
                                    .background(Color.warmWhite)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        if let err = vm.error {
                            Text(err)
                                .font(.custom("DMSans-Regular", size: 13))
                                .foregroundColor(.rose)
                                .padding(.horizontal, 20)
                        }

                        Button(action: {
                            Task {
                                if let saved = await vm.save(profile: profile) {
                                    onSave(saved)
                                }
                            }
                        }) {
                            HStack {
                                if vm.saving { ProgressView().tint(.white) }
                                else { Text(existing != nil ? "Update check-in" : "Save check-in")
                                    .font(.custom("DMSans-Bold", size: 15)) }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.rose)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(vm.saving)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle(existing != nil ? "Edit Check-in" : "Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.rose)
                }
            }
        }
    }
}

// MARK: - Collapsible Section
struct CollapsibleSection<Content: View>: View {
    let title: String
    let summary: String
    @ViewBuilder let content: () -> Content
    @State private var isOpen = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isOpen.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.uppercased())
                            .font(.custom("DMSans-Bold", size: 13).leading(.tight))
                            .tracking(0.6)
                            .foregroundColor(.charcoal)
                        if !isOpen && !summary.isEmpty {
                            Text(summary)
                                .font(.custom("DMSans-Regular", size: 12))
                                .foregroundColor(.slateMid)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .foregroundColor(.slateMid)
                        .font(.system(size: 14))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
            }
        }
        .background(Color.warmWhite)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1.5))
    }
}

// MARK: - Field Section
struct FieldSection<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.custom("DMSans-Medium", size: 13))
                .foregroundColor(.charcoal)
            content()
        }
    }
}

// MARK: - View Model
@MainActor
class CheckInViewModel: ObservableObject {
    @Published var flow: String?
    @Published var pain: Int?
    @Published var mood: [String] = []
    @Published var energy: String?
    @Published var bloating: String?
    @Published var sleep: String?
    @Published var bowel: [String] = []
    @Published var nausea: Bool?
    @Published var discharge: String?
    @Published var notes: String = ""
    @Published var saving = false
    @Published var error: String?

    private let existing: CheckIn?

    init(existing: CheckIn?) {
        self.existing = existing
        if let e = existing {
            self.flow      = e.flow
            self.pain      = e.painLevel
            self.mood      = e.mood ?? []
            self.energy    = e.energy
            self.bloating  = e.bloating
            self.sleep     = e.sleep
            self.bowel     = e.bowel ?? []
            self.nausea    = e.nausea
            self.discharge = e.discharge
            self.notes     = e.notes ?? ""
        }
    }

    var periodSummary: String {
        var parts: [String] = []
        if let f = flow { parts.append(f.capitalized) }
        if let p = pain  { parts.append("Pain \(p)/5") }
        return parts.joined(separator: " · ")
    }

    var moodSummary: String {
        var parts: [String] = []
        if !mood.isEmpty { parts.append(mood.map { $0.capitalized }.joined(separator: ", ")) }
        if let e = energy { parts.append(e.capitalized) }
        return parts.joined(separator: " · ")
    }

    var symptomSummary: String {
        var parts: [String] = []
        if let b = bloating, b != "none" { parts.append("Bloating: \(b.capitalized)") }
        if nausea == true { parts.append("Nausea") }
        if !bowel.isEmpty { parts.append(bowel.map { $0.capitalized }.joined(separator: ", ")) }
        return parts.joined(separator: " · ")
    }

    func save(profile: Profile) async -> CheckIn? {
        saving = true
        error  = nil
        let db = SupabaseService.shared
        do {
            let today = todayString()
            if let ex = existing {
                let update = CheckInUpdate(
                    date: ex.date,
                    flow: flow,
                    painLevel: pain,
                    mood: mood.isEmpty ? nil : mood,
                    energy: energy,
                    bloating: bloating,
                    sleep: sleep,
                    bowel: bowel.isEmpty ? nil : bowel,
                    nausea: nausea,
                    discharge: discharge ?? "none",
                    notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
                )
                let saved = try await db.updateCheckIn(id: ex.id, update: update)
                saving = false
                return saved
            } else {
                let insert = CheckInInsert(
                    userId: profile.id,
                    date: today,
                    flow: flow,
                    painLevel: pain,
                    mood: mood.isEmpty ? nil : mood,
                    energy: energy,
                    bloating: bloating,
                    sleep: sleep,
                    bowel: bowel.isEmpty ? nil : bowel,
                    nausea: nausea,
                    discharge: discharge ?? "none",
                    notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
                )
                let saved = try await db.insertCheckIn(insert)
                saving = false
                return saved
            }
        } catch {
            self.error = error.localizedDescription
            saving = false
            return nil
        }
    }
}
