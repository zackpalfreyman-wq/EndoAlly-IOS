import Foundation

// MARK: - Family History
struct FamilyHistory: Codable, Identifiable {
    let id: String
    let userId: String
    var relation: String
    var condition: String
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId   = "user_id"
        case relation
        case condition
        case notes
    }
}

struct FamilyHistoryInsert: Encodable {
    let userId: String
    let relation: String
    let condition: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case userId   = "user_id"
        case relation
        case condition
        case notes
    }
}

// MARK: - Medication
struct HistoryMedication: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var dose: String?
    var frequency: String?
    var forWhat: String?
    var stillTaking: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId     = "user_id"
        case name
        case dose
        case frequency
        case forWhat    = "for_what"
        case stillTaking = "still_taking"
    }
}

struct MedicationInsert: Encodable {
    let userId: String
    let name: String
    let dose: String?
    let frequency: String?
    let forWhat: String?
    let stillTaking: Bool

    enum CodingKeys: String, CodingKey {
        case userId     = "user_id"
        case name
        case dose
        case frequency
        case forWhat    = "for_what"
        case stillTaking = "still_taking"
    }
}

struct MedicationUpdate: Encodable {
    let stillTaking: Bool

    enum CodingKeys: String, CodingKey {
        case stillTaking = "still_taking"
    }
}

// MARK: - Birth Control
struct BirthControl: Codable, Identifiable {
    let id: String
    let userId: String
    var bcType: String
    var iudType: String?
    var brand: String?
    var injBrand: String?
    var injDose: String?
    var injFrequency: String?
    var dose: String?
    var otherDescription: String?
    var startDate: String?
    var stillUsing: Bool
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId          = "user_id"
        case bcType          = "bc_type"
        case iudType         = "iud_type"
        case brand
        case injBrand        = "inj_brand"
        case injDose         = "inj_dose"
        case injFrequency    = "inj_frequency"
        case dose
        case otherDescription = "other_description"
        case startDate       = "start_date"
        case stillUsing      = "still_using"
        case notes
    }

    var displayDescription: String {
        var parts = [bcType]
        if let iud = iudType { parts.append("(\(iud))") }
        if let b = brand { parts.append(b) }
        if let ib = injBrand { parts.append(ib) }
        if let d = dose ?? injDose { parts.append(d) }
        if let sd = startDate { parts.append("From \(sd)") }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

struct BirthControlInsert: Encodable {
    let userId: String
    let bcType: String
    let iudType: String?
    let brand: String?
    let injBrand: String?
    let injDose: String?
    let injFrequency: String?
    let dose: String?
    let otherDescription: String?
    let startDate: String?
    let stillUsing: Bool
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case userId          = "user_id"
        case bcType          = "bc_type"
        case iudType         = "iud_type"
        case brand
        case injBrand        = "inj_brand"
        case injDose         = "inj_dose"
        case injFrequency    = "inj_frequency"
        case dose
        case otherDescription = "other_description"
        case startDate       = "start_date"
        case stillUsing      = "still_using"
        case notes
    }
}

// MARK: - Treatment
struct Treatment: Codable, Identifiable {
    let id: String
    let userId: String
    var treatmentType: String
    var name: String
    var date: String?
    var outcome: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId       = "user_id"
        case treatmentType = "treatment_type"
        case name
        case date
        case outcome
    }
}

struct TreatmentInsert: Encodable {
    let userId: String
    let treatmentType: String
    let name: String
    let date: String?
    let outcome: String?

    enum CodingKeys: String, CodingKey {
        case userId       = "user_id"
        case treatmentType = "treatment_type"
        case name
        case date
        case outcome
    }
}

// MARK: - Therapy
struct Therapy: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var therapyType: String
    var frequency: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId     = "user_id"
        case name
        case therapyType = "therapy_type"
        case frequency
        case notes
    }
}

struct TherapyInsert: Encodable {
    let userId: String
    let name: String
    let therapyType: String
    let frequency: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case userId     = "user_id"
        case name
        case therapyType = "therapy_type"
        case frequency
        case notes
    }
}
