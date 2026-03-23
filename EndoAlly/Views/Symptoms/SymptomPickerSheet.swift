import SwiftUI

enum SymptomStep: Int, CaseIterable {
    case category = 0
    case symptom  = 1
    case severity = 2
    case meds     = 3
    case mgmt     = 4
}

struct SymptomPickerSheet: View {
    let profile: Profile
    let onSave: (Symptom) -> Void

    @Environment(\.dismiss) private var dismiss

    // Step state
    @State private var step: SymptomStep = .category
    @State private var selectedCategory: String?
    @State private var selectedSymptom: String?

    // Severity
    @State private var severity: Int?
    @State private var notes = ""

    // Medications
    @State private var userMeds: [HistoryMedication] = []
    @State private var selectedMeds: [String] = []
    @State private var customMeds: [String] = []
    @State private var customMedInput = ""
    @State private var medDose = ""
    @State private var medEff: Int?

    // Management
    @State private var userTherapies: [Therapy] = []
    @State private var selectedMgmt: [String] = []
    @State private var customMgmt: [String] = []
    @State private var customMgmtInput = ""
    @State private var mgmtEff: Int?

    @State private var saving = false
    @State private var error: String?

    private var skipSeverity: Bool {
        guard let sym = selectedSymptom else { return false }
        return noSeveritySymptoms.contains(sym)
    }

    private var allMeds: [String] {
        (preloadedMeds + userMeds.map { $0.name }).removingDuplicates()
    }

    private var allMgmt: [String] {
        (preloadedManagement + userTherapies.map { $0.name }).removingDuplicates()
    }

    private var stepLabels: [String] {
        skipSeverity ? ["Category", "Symptom", "Medication", "Management"]
                     : ["Category", "Symptom", "Severity", "Medication", "Management"]
    }

    private var displayStepIndex: Int {
        if skipSeverity && step.rawValue >= 3 { return step.rawValue - 1 }
        return step.rawValue
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("STEP \(displayStepIndex + 1) OF \(stepLabels.count)")
                                    .font(.custom("DMSans-Bold", size: 10).leading(.tight))
                                    .tracking(1.0)
                                    .foregroundColor(.rose)
                                Text(stepTitle)
                                    .font(.custom("DMSans-SemiBold", size: 22))
                                    .foregroundColor(.charcoal)
                            }
                            Spacer()
                            if step.rawValue > 0 {
                                Button(action: goBack) {
                                    Image(systemName: "arrow.left")
                                        .frame(width: 36, height: 36)
                                        .background(Color.warmWhite)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                                }
                                .foregroundColor(.slateMid)
                            }
                        }

                        // Step dots
                        HStack(spacing: 6) {
                            ForEach(0..<stepLabels.count, id: \.self) { i in
                                Circle()
                                    .fill(i == displayStepIndex ? Color.rose : i < displayStepIndex ? Color.sage : Color.appBorder)
                                    .frame(width: 8, height: 8)
                            }
                            Spacer()
                        }

                        // Step content
                        switch step {
                        case .category:  categoryStep
                        case .symptom:   symptomStep
                        case .severity:  severityStep
                        case .meds:      medsStep
                        case .mgmt:      mgmtStep
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.rose)
                }
            }
        }
        .task {
            let uid = profile.id
            async let mTask = try? SupabaseService.shared.fetchMedications(userId: uid)
            async let tTask = try? SupabaseService.shared.fetchTherapies(userId: uid)
            let (m, t) = await (mTask, tTask)
            userMeds = m ?? []
            userTherapies = t ?? []
        }
    }

    // MARK: - Step title
    private var stepTitle: String {
        switch step {
        case .category: return "Select category"
        case .symptom:  return "Select symptom"
        case .severity: return "Rate severity"
        case .meds:     return "Medication taken?"
        case .mgmt:     return "Management used?"
        }
    }

    // MARK: - Category step
    private var categoryStep: some View {
        VStack(spacing: 8) {
            ForEach(symptomCategoryOrder, id: \.self) { cat in
                Button(action: {
                    selectedCategory = cat
                    selectedSymptom = nil
                    step = .symptom
                }) {
                    HStack {
                        Text(cat)
                            .font(.custom("DMSans-SemiBold", size: 14))
                            .foregroundColor(selectedCategory == cat ? .rose : .charcoal)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.slateMid)
                    }
                    .padding(14)
                    .background(selectedCategory == cat ? Color.roseLight : Color.warmWhite)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                        selectedCategory == cat ? Color.rose : Color.appBorder, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Symptom step
    private var symptomStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let cat = selectedCategory, let syms = symptomCategories[cat] {
                FlowLayout(spacing: 8) {
                    ForEach(syms, id: \.self) { sym in
                        Chip(label: sym, selected: selectedSymptom == sym) {
                            selectedSymptom = sym
                            if noSeveritySymptoms.contains(sym) {
                                step = .meds
                            } else {
                                step = .severity
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Severity step
    private var severityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let sym = selectedSymptom {
                Text("Selected: \(sym)")
                    .font(.custom("DMSans-Medium", size: 14))
                    .foregroundColor(.slateMid)
            }
            Text("Rate your severity from 1 (minimal) to 10 (unbearable)")
                .font(.custom("DMSans-Regular", size: 13))
                .foregroundColor(.slateMid)

            SeverityGrid(value: $severity)

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes (optional)")
                    .font(.custom("DMSans-Medium", size: 13))
                    .foregroundColor(.charcoal)
                TextField("Any additional details…", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color.warmWhite)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
            }

            Button(action: { step = .meds }) {
                Text("Next →")
                    .font(.custom("DMSans-Bold", size: 15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(severity != nil ? Color.rose : Color.appBorder)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(severity == nil)
        }
    }

    // MARK: - Meds step
    private var medsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            if skipSeverity, let sym = selectedSymptom {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Symptom: \(sym)")
                        .font(.custom("DMSans-Medium", size: 14))
                        .foregroundColor(.slateMid)
                    Text("This symptom type is logged without a severity rating.")
                        .font(.custom("DMSans-Regular", size: 13))
                        .foregroundColor(.slateMid)
                }
                .padding(12)
                .background(Color.warmWhite)
                .cornerRadius(8)
            }

            Text("Select any medications you took for this symptom.")
                .font(.custom("DMSans-Regular", size: 13))
                .foregroundColor(.slateMid)

            FlowLayout(spacing: 8) {
                ForEach(allMeds, id: \.self) { med in
                    Chip(label: med, selected: selectedMeds.contains(med)) {
                        if selectedMeds.contains(med) { selectedMeds.removeAll { $0 == med } }
                        else { selectedMeds.append(med) }
                    }
                }
            }

            // Custom med input
            HStack(spacing: 8) {
                TextField("Other medication…", text: $customMedInput)
                    .padding(10)
                    .background(Color.warmWhite)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                Button("Add") {
                    let val = customMedInput.trimmingCharacters(in: .whitespaces)
                    if !val.isEmpty && !customMeds.contains(val) && !selectedMeds.contains(val) {
                        customMeds.append(val)
                        customMedInput = ""
                    }
                }
                .disabled(customMedInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .font(.custom("DMSans-Bold", size: 13))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.warmWhite)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                .foregroundColor(.charcoal)
            }

            if !customMeds.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(customMeds, id: \.self) { med in
                        Button(action: { customMeds.removeAll { $0 == med } }) {
                            Text("\(med) ✕")
                                .font(.custom("DMSans-SemiBold", size: 13))
                                .foregroundColor(.rose)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.roseLight)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.rose, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !selectedMeds.isEmpty || !customMeds.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dose / details (optional)")
                        .font(.custom("DMSans-Medium", size: 13))
                        .foregroundColor(.charcoal)
                    TextField("e.g. 400mg ibuprofen", text: $medDose)
                        .padding(10)
                        .background(Color.warmWhite)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Effectiveness")
                        .font(.custom("DMSans-Medium", size: 13))
                        .foregroundColor(.charcoal)
                    FlowLayout(spacing: 8) {
                        ForEach(1...5, id: \.self) { n in
                            Chip(label: "\(n) — \(effectivenessLabels[n] ?? "")", selected: medEff == n) {
                                medEff = medEff == n ? nil : n
                            }
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button(action: { step = .mgmt }) {
                    Text("Skip")
                        .font(.custom("DMSans-SemiBold", size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.warmWhite)
                        .foregroundColor(.slateMid)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                }
                Button(action: { step = .mgmt }) {
                    Text("Next →")
                        .font(.custom("DMSans-Bold", size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.rose)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Management step
    private var mgmtStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select any management strategies you used.")
                .font(.custom("DMSans-Regular", size: 13))
                .foregroundColor(.slateMid)

            FlowLayout(spacing: 8) {
                ForEach(allMgmt, id: \.self) { mgmt in
                    Chip(label: mgmt, selected: selectedMgmt.contains(mgmt)) {
                        if selectedMgmt.contains(mgmt) { selectedMgmt.removeAll { $0 == mgmt } }
                        else { selectedMgmt.append(mgmt) }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Other management…", text: $customMgmtInput)
                    .padding(10)
                    .background(Color.warmWhite)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                Button("Add") {
                    let val = customMgmtInput.trimmingCharacters(in: .whitespaces)
                    if !val.isEmpty && !customMgmt.contains(val) && !selectedMgmt.contains(val) {
                        customMgmt.append(val)
                        customMgmtInput = ""
                    }
                }
                .disabled(customMgmtInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .font(.custom("DMSans-Bold", size: 13))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.warmWhite)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                .foregroundColor(.charcoal)
            }

            if !customMgmt.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(customMgmt, id: \.self) { mgmt in
                        Button(action: { customMgmt.removeAll { $0 == mgmt } }) {
                            Text("\(mgmt) ✕")
                                .font(.custom("DMSans-SemiBold", size: 13))
                                .foregroundColor(.rose)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.roseLight)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.rose, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !selectedMgmt.isEmpty || !customMgmt.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Effectiveness")
                        .font(.custom("DMSans-Medium", size: 13))
                        .foregroundColor(.charcoal)
                    FlowLayout(spacing: 8) {
                        ForEach(1...5, id: \.self) { n in
                            Chip(label: "\(n) — \(effectivenessLabels[n] ?? "")", selected: mgmtEff == n) {
                                mgmtEff = mgmtEff == n ? nil : n
                            }
                        }
                    }
                }
            }

            if let err = error {
                Text(err)
                    .font(.custom("DMSans-Regular", size: 13))
                    .foregroundColor(.rose)
            }

            HStack(spacing: 10) {
                Button(action: { Task { await handleSave() } }) {
                    Text(saving ? "Saving…" : "Skip & save")
                        .font(.custom("DMSans-SemiBold", size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.warmWhite)
                        .foregroundColor(.slateMid)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                }
                .disabled(saving)

                Button(action: { Task { await handleSave() } }) {
                    HStack {
                        if saving { ProgressView().tint(.white).scaleEffect(0.8) }
                        else { Text("Save symptom").font(.custom("DMSans-Bold", size: 14)) }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.rose)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(saving)
            }
        }
    }

    private func goBack() {
        switch step {
        case .category: break
        case .symptom:  step = .category
        case .severity: step = .symptom
        case .meds:
            if skipSeverity { step = .symptom }
            else { step = .severity }
        case .mgmt:     step = .meds
        }
    }

    private func handleSave() async {
        guard let symptom = selectedSymptom, let category = selectedCategory else { return }
        saving = true
        error = nil

        let cycleInfo = getSmartCycleInfo(checkins: [], profile: profile)
        let allSelectedMeds = selectedMeds + customMeds
        let allSelectedMgmt = selectedMgmt + customMgmt

        let insert = SymptomInsert(
            userId: profile.id,
            symptom: symptom,
            category: category,
            severity: skipSeverity ? nil : severity,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
            cycleDay: cycleInfo?.day,
            phase: cycleInfo?.phase.rawValue,
            meds: allSelectedMeds.isEmpty ? nil : allSelectedMeds,
            medDose: medDose.trimmingCharacters(in: .whitespaces).isEmpty ? nil : medDose.trimmingCharacters(in: .whitespaces),
            medEffectiveness: allSelectedMeds.isEmpty ? nil : medEff,
            management: allSelectedMgmt.isEmpty ? nil : allSelectedMgmt,
            mgmtEffectiveness: allSelectedMgmt.isEmpty ? nil : mgmtEff,
            loggedAt: ISO8601DateFormatter().string(from: Date())
        )

        do {
            let saved = try await SupabaseService.shared.insertSymptom(insert)
            onSave(saved)
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
