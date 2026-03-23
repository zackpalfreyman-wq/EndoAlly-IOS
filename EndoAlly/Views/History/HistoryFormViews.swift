import SwiftUI

// MARK: - Family History Section
struct HistoryFormViews: View {
    @ObservedObject var vm: HistoryViewModel

    var body: some View {
        VStack(spacing: 16) {
            FamilyHistorySectionView(vm: vm)
            MedicationsSectionView(vm: vm)
            BirthControlSectionView(vm: vm)
            TreatmentsSectionView(vm: vm)
            TherapiesSectionView(vm: vm)
        }
    }
}

// MARK: - Shared list item style
private struct ListRow: View {
    let title: String
    let meta: String
    var badge: (label: String, isActive: Bool)? = nil
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("DMSans-SemiBold", size: 14))
                    .foregroundColor(.charcoal)
                if !meta.isEmpty {
                    HStack(spacing: 4) {
                        Text(meta)
                            .font(.custom("DMSans-Regular", size: 12))
                            .foregroundColor(.slateMid)
                        if let badge = badge {
                            Text(badge.label)
                                .font(.custom("DMSans-SemiBold", size: 11))
                                .foregroundColor(badge.isActive ? .sage : .slateMid)
                        }
                    }
                }
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.rose)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .overlay(Divider(), alignment: .bottom)
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.custom("DMSans-SemiBold", size: 20))
                    .foregroundColor(.charcoal)
                content()
            }
        }
    }
}

// MARK: - Family History
struct FamilyHistorySectionView: View {
    @ObservedObject var vm: HistoryViewModel
    @State private var showForm = false
    @State private var relation = "Mother"
    @State private var condition = "Endometriosis"
    @State private var notes = ""
    @State private var saving = false

    private let relations  = ["Mother", "Sister", "Aunt", "Grandmother", "Other"]
    private let conditions = ["Endometriosis", "PCOS", "Fibroids", "Adenomyosis", "Other"]

    var body: some View {
        SectionCard(title: "Family History") {
            if vm.familyHistory.isEmpty && !showForm {
                EmptyStateRow(icon: "figure.2.and.child.holdinghands", text: "No family history added yet.")
            }
            ForEach(vm.familyHistory) { item in
                ListRow(title: "\(item.relation) — \(item.condition)", meta: item.notes ?? "") {
                    Task { try? await vm.db.deleteFamilyHistory(id: item.id); vm.familyHistory.removeAll { $0.id == item.id } }
                }
            }
            if showForm {
                VStack(alignment: .leading, spacing: 12) {
                    PickerRow(label: "Relationship", value: $relation, options: relations)
                    PickerRow(label: "Condition",    value: $condition, options: conditions)
                    TextAreaRow(label: "Notes (optional)", text: $notes, placeholder: "Any details…")
                    FormActions(saving: saving, onCancel: { showForm = false; notes = "" }) {
                        Task { await addEntry() }
                    }
                }
                .padding(12)
                .background(Color.warmWhite)
                .cornerRadius(8)
            } else {
                AddButton(label: "+ Add family history") { showForm = true }
            }
        }
    }

    private func addEntry() async {
        saving = true
        let insert = FamilyHistoryInsert(userId: vm.userId, relation: relation, condition: condition, notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces))
        if let saved = try? await vm.db.insertFamilyHistory(insert) {
            vm.familyHistory.append(saved)
        }
        saving = false
        showForm = false
        notes = ""
    }
}

// MARK: - Medications
struct MedicationsSectionView: View {
    @ObservedObject var vm: HistoryViewModel
    @State private var showForm = false
    @State private var name = ""
    @State private var dose = ""
    @State private var frequency = "Daily"
    @State private var forWhat = ""
    @State private var stillTaking = true
    @State private var saving = false

    private let frequencies = ["Daily", "As needed", "Weekly", "Monthly", "Other"]

    var body: some View {
        SectionCard(title: "Regular Medications") {
            if vm.medications.isEmpty && !showForm {
                EmptyStateRow(icon: "pills", text: "No medications added yet.")
            }
            ForEach(vm.medications) { med in
                ListRow(
                    title: "\(med.name)\(med.dose.map { " — \($0)" } ?? "")",
                    meta: [med.frequency, med.forWhat].compactMap { $0 }.joined(separator: " · "),
                    badge: (label: med.stillTaking ? "● Current" : "○ Past", isActive: med.stillTaking)
                ) {
                    Task { try? await vm.db.deleteMedication(id: med.id); vm.medications.removeAll { $0.id == med.id } }
                }
            }
            if showForm {
                VStack(alignment: .leading, spacing: 12) {
                    InputRow(label: "Medication name *", text: $name, placeholder: "e.g. Ibuprofen")
                    HStack(spacing: 10) {
                        InputRow(label: "Dose", text: $dose, placeholder: "e.g. 400mg")
                        PickerRow(label: "Frequency", value: $frequency, options: frequencies)
                    }
                    InputRow(label: "What for", text: $forWhat, placeholder: "e.g. Pain management")
                    ToggleRow(label: "Still taking", value: $stillTaking)
                    FormActions(saving: saving, onCancel: resetForm) {
                        Task { await addEntry() }
                    }
                }
                .padding(12)
                .background(Color.warmWhite)
                .cornerRadius(8)
            } else {
                AddButton(label: "+ Add medication") { showForm = true }
            }
        }
    }

    private func resetForm() {
        showForm = false; name = ""; dose = ""; forWhat = ""; stillTaking = true
    }

    private func addEntry() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        saving = true
        let insert = MedicationInsert(userId: vm.userId, name: name.trimmingCharacters(in: .whitespaces), dose: dose.isEmpty ? nil : dose, frequency: frequency, forWhat: forWhat.isEmpty ? nil : forWhat, stillTaking: stillTaking)
        if let saved = try? await vm.db.insertMedication(insert) {
            vm.medications.append(saved)
        }
        saving = false
        resetForm()
    }
}

// MARK: - Birth Control
struct BirthControlSectionView: View {
    @ObservedObject var vm: HistoryViewModel
    @State private var showForm = false
    @State private var bcType = "Pill"
    @State private var iudType = "Hormonal"
    @State private var brand = ""
    @State private var injBrand = ""
    @State private var injDose = ""
    @State private var injFreq = ""
    @State private var dose = ""
    @State private var otherDesc = ""
    @State private var startDate = ""
    @State private var stillUsing = true
    @State private var notes = ""
    @State private var saving = false

    private let types = ["Pill", "IUD", "Injection", "Patch", "Ring", "Other"]

    var body: some View {
        SectionCard(title: "Birth Control") {
            if vm.birthControls.isEmpty && !showForm {
                EmptyStateRow(icon: "cross.circle", text: "No birth control history added yet.")
            }
            ForEach(vm.birthControls) { bc in
                ListRow(
                    title: bc.displayDescription,
                    meta: "",
                    badge: (label: bc.stillUsing ? "● Currently using" : "○ Past", isActive: bc.stillUsing)
                ) {
                    Task { try? await vm.db.deleteBirthControl(id: bc.id); vm.birthControls.removeAll { $0.id == bc.id } }
                }
            }
            if showForm {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Type").font(.custom("DMSans-Medium", size: 13)).foregroundColor(.charcoal)
                        FlowLayout(spacing: 8) {
                            ForEach(types, id: \.self) { t in
                                Chip(label: t, selected: bcType == t) { bcType = t }
                            }
                        }
                    }
                    if bcType == "IUD" {
                        PickerRow(label: "IUD type", value: $iudType, options: ["Hormonal", "Copper"])
                    }
                    if ["Pill", "Patch", "Ring", "IUD"].contains(bcType) {
                        InputRow(label: "Brand / Name", text: $brand, placeholder: bcType == "IUD" ? "e.g. Mirena, Kyleena" : "e.g. Levlen")
                    }
                    if ["Pill", "Patch", "Ring"].contains(bcType) {
                        InputRow(label: "Dose", text: $dose, placeholder: "e.g. 30mcg")
                    }
                    if bcType == "Injection" {
                        InputRow(label: "Brand", text: $injBrand, placeholder: "e.g. Depo-Provera")
                        HStack(spacing: 10) {
                            InputRow(label: "Dose", text: $injDose, placeholder: "e.g. 150mg")
                            InputRow(label: "Frequency", text: $injFreq, placeholder: "e.g. every 12 weeks")
                        }
                    }
                    if bcType == "Other" {
                        InputRow(label: "Description", text: $otherDesc, placeholder: "Describe the method")
                    }
                    InputRow(label: "Start date", text: $startDate, placeholder: "e.g. January 2022")
                    ToggleRow(label: "Currently using", value: $stillUsing)
                    TextAreaRow(label: "Notes (optional)", text: $notes, placeholder: "Side effects, reasons for stopping…")
                    FormActions(saving: saving, onCancel: resetForm) {
                        Task { await addEntry() }
                    }
                }
                .padding(12)
                .background(Color.warmWhite)
                .cornerRadius(8)
            } else {
                AddButton(label: "+ Add birth control") { showForm = true }
            }
        }
    }

    private func resetForm() {
        showForm = false; brand = ""; injBrand = ""; injDose = ""; injFreq = ""; dose = ""; otherDesc = ""; startDate = ""; notes = ""; stillUsing = true; bcType = "Pill"
    }

    private func addEntry() async {
        saving = true
        let insert = BirthControlInsert(
            userId: vm.userId,
            bcType: bcType,
            iudType: bcType == "IUD" ? iudType : nil,
            brand: ["Pill", "Patch", "Ring", "IUD"].contains(bcType) ? (brand.isEmpty ? nil : brand) : nil,
            injBrand: bcType == "Injection" ? (injBrand.isEmpty ? nil : injBrand) : nil,
            injDose: bcType == "Injection" ? (injDose.isEmpty ? nil : injDose) : nil,
            injFrequency: bcType == "Injection" ? (injFreq.isEmpty ? nil : injFreq) : nil,
            dose: ["Pill", "Patch", "Ring"].contains(bcType) ? (dose.isEmpty ? nil : dose) : nil,
            otherDescription: bcType == "Other" ? (otherDesc.isEmpty ? nil : otherDesc) : nil,
            startDate: startDate.isEmpty ? nil : startDate,
            stillUsing: stillUsing,
            notes: notes.isEmpty ? nil : notes
        )
        if let saved = try? await vm.db.insertBirthControl(insert) {
            vm.birthControls.append(saved)
        }
        saving = false
        resetForm()
    }
}

// MARK: - Treatments
struct TreatmentsSectionView: View {
    @ObservedObject var vm: HistoryViewModel
    @State private var showForm = false
    @State private var treatmentType = "Surgery"
    @State private var name = ""
    @State private var date = ""
    @State private var outcome = ""
    @State private var saving = false

    private let types = ["Surgery", "Hormonal treatment", "Procedure", "Other"]

    var body: some View {
        SectionCard(title: "Past Treatments") {
            if vm.treatments.isEmpty && !showForm {
                EmptyStateRow(icon: "cross.case", text: "No past treatments added yet.")
            }
            ForEach(vm.treatments) { t in
                ListRow(title: t.name, meta: [t.treatmentType, t.date, t.outcome].compactMap { $0 }.joined(separator: " · ")) {
                    Task { try? await vm.db.deleteTreatment(id: t.id); vm.treatments.removeAll { $0.id == t.id } }
                }
            }
            if showForm {
                VStack(alignment: .leading, spacing: 12) {
                    PickerRow(label: "Type", value: $treatmentType, options: types)
                    InputRow(label: "Name / description *", text: $name, placeholder: "e.g. Laparoscopy, Visanne, Zoladex")
                    InputRow(label: "Date (approximate)", text: $date, placeholder: "e.g. March 2023")
                    TextAreaRow(label: "Outcome / notes", text: $outcome, placeholder: "e.g. Endo found and removed, symptoms improved")
                    FormActions(saving: saving, onCancel: { showForm = false; name = ""; date = ""; outcome = "" }) {
                        Task { await addEntry() }
                    }
                }
                .padding(12)
                .background(Color.warmWhite)
                .cornerRadius(8)
            } else {
                AddButton(label: "+ Add treatment") { showForm = true }
            }
        }
    }

    private func addEntry() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        saving = true
        let insert = TreatmentInsert(userId: vm.userId, treatmentType: treatmentType, name: name.trimmingCharacters(in: .whitespaces), date: date.isEmpty ? nil : date, outcome: outcome.isEmpty ? nil : outcome)
        if let saved = try? await vm.db.insertTreatment(insert) { vm.treatments.append(saved) }
        saving = false; showForm = false; name = ""; date = ""; outcome = ""
    }
}

// MARK: - Therapies
struct TherapiesSectionView: View {
    @ObservedObject var vm: HistoryViewModel
    @State private var showForm = false
    @State private var name = ""
    @State private var therapyType = "Physical therapy"
    @State private var frequency = ""
    @State private var notes = ""
    @State private var saving = false

    private let types = ["Physical therapy", "Exercise", "Mind-body", "Other"]

    var body: some View {
        SectionCard(title: "Therapies & Exercises") {
            if vm.therapies.isEmpty && !showForm {
                EmptyStateRow(icon: "figure.mind.and.body", text: "No therapies or exercises added yet.")
            }
            ForEach(vm.therapies) { t in
                ListRow(title: t.name, meta: [t.therapyType, t.frequency].compactMap { $0 }.joined(separator: " · ")) {
                    Task { try? await vm.db.deleteTherapy(id: t.id); vm.therapies.removeAll { $0.id == t.id } }
                }
            }
            if showForm {
                VStack(alignment: .leading, spacing: 12) {
                    InputRow(label: "Name *", text: $name, placeholder: "e.g. Pelvic floor physio, Yoga, Meditation")
                    PickerRow(label: "Type", value: $therapyType, options: types)
                    InputRow(label: "Frequency", text: $frequency, placeholder: "e.g. Weekly, Daily")
                    TextAreaRow(label: "Notes (optional)", text: $notes, placeholder: "Any notes…")
                    FormActions(saving: saving, onCancel: { showForm = false; name = ""; frequency = ""; notes = "" }) {
                        Task { await addEntry() }
                    }
                }
                .padding(12)
                .background(Color.warmWhite)
                .cornerRadius(8)
            } else {
                AddButton(label: "+ Add therapy / exercise") { showForm = true }
            }
        }
    }

    private func addEntry() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        saving = true
        let insert = TherapyInsert(userId: vm.userId, name: name.trimmingCharacters(in: .whitespaces), therapyType: therapyType, frequency: frequency.isEmpty ? nil : frequency, notes: notes.isEmpty ? nil : notes)
        if let saved = try? await vm.db.insertTherapy(insert) { vm.therapies.append(saved) }
        saving = false; showForm = false; name = ""; frequency = ""; notes = ""
    }
}

// MARK: - Shared form sub-components
private struct EmptyStateRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.slateMid)
            Text(text).font(.custom("DMSans-Regular", size: 13)).foregroundColor(.slateMid)
        }
        .padding(.vertical, 8)
    }
}

private struct InputRow: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.custom("DMSans-Medium", size: 13)).foregroundColor(.charcoal)
            TextField(placeholder, text: $text)
                .padding(10)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
        }
    }
}

private struct TextAreaRow: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.custom("DMSans-Medium", size: 13)).foregroundColor(.charcoal)
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(2...4)
                .padding(10)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
        }
    }
}

private struct PickerRow: View {
    let label: String
    @Binding var value: String
    let options: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.custom("DMSans-Medium", size: 13)).foregroundColor(.charcoal)
            Picker(label, selection: $value) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
        }
    }
}

private struct ToggleRow: View {
    let label: String
    @Binding var value: Bool
    var body: some View {
        HStack {
            Text(label).font(.custom("DMSans-Medium", size: 14)).foregroundColor(.charcoal)
            Spacer()
            Toggle("", isOn: $value).tint(.rose)
        }
    }
}

private struct FormActions: View {
    let saving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    var saveLabel = "Add entry"

    var body: some View {
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
            Button(action: onSave) {
                Text(saving ? "Saving…" : saveLabel)
                    .font(.custom("DMSans-SemiBold", size: 13))
            }
            .disabled(saving)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color.rose)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

private struct AddButton: View {
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom("DMSans-SemiBold", size: 13))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.warmWhite)
                .foregroundColor(.slateMid)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}
