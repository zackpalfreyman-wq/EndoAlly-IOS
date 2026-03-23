import Foundation

struct Symptom: Codable, Identifiable {
    let id: String
    let userId: String
    let symptom: String
    let category: String
    let severity: Int?
    let notes: String?
    let cycleDay: Int?
    let phase: String?
    let meds: [String]?
    let medDose: String?
    let medEffectiveness: Int?
    let management: [String]?
    let mgmtEffectiveness: Int?
    let loggedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId            = "user_id"
        case symptom
        case category
        case severity
        case notes
        case cycleDay          = "cycle_day"
        case phase
        case meds
        case medDose           = "med_dose"
        case medEffectiveness  = "med_effectiveness"
        case management
        case mgmtEffectiveness = "mgmt_effectiveness"
        case loggedAt          = "logged_at"
    }
}

struct SymptomInsert: Encodable {
    let userId: String
    let symptom: String
    let category: String
    let severity: Int?
    let notes: String?
    let cycleDay: Int?
    let phase: String?
    let meds: [String]?
    let medDose: String?
    let medEffectiveness: Int?
    let management: [String]?
    let mgmtEffectiveness: Int?
    let loggedAt: String

    enum CodingKeys: String, CodingKey {
        case userId            = "user_id"
        case symptom
        case category
        case severity
        case notes
        case cycleDay          = "cycle_day"
        case phase
        case meds
        case medDose           = "med_dose"
        case medEffectiveness  = "med_effectiveness"
        case management
        case mgmtEffectiveness = "mgmt_effectiveness"
        case loggedAt          = "logged_at"
    }
}

// MARK: - Symptom Constants
let symptomCategories: [String: [String]] = [
    "Period & Bleeding": [
        "Painful periods",
        "Very heavy bleeding",
        "Large blood clots",
        "Spotting between periods",
        "Irregular cycle",
        "Periods lasting longer than 7 days",
        "Painful ovulation",
        "Bleeding after sex",
        "Very light periods",
        "Cycle length changes",
    ],
    "Pelvic & Back Pain": [
        "Pelvic pain between periods",
        "Lower back pain",
        "Hip pain",
        "Tailbone pain",
        "Abdominal cramping outside period",
        "Groin pain",
        "Deep pelvic pressure",
        "Pain when sitting long periods",
        "One-sided pelvic pain",
        "Inner thigh pain",
    ],
    "Bowel & Digestive": [
        "Painful bowel movements",
        "Constipation",
        "Diarrhoea",
        "Severe bloating",
        "Nausea",
        "Pain after eating",
        "Rectal bleeding during period",
        "Alternating constipation and diarrhoea",
        "Feeling full quickly",
    ],
    "Bladder & Urinary": [
        "Painful urination",
        "Needing to urinate frequently",
        "Urgent need to urinate",
        "Blood in urine during period",
        "Bladder pressure or fullness",
        "Incomplete bladder emptying",
        "Waking at night to urinate",
    ],
    "Sex & Intimacy": [
        "Pain during sex",
        "Pain deep inside during sex",
        "Pain after sex",
        "Pain with internal examinations",
        "Reduced sex drive",
        "Vaginal dryness",
        "Discomfort with tampon use",
        "Pelvic aching after orgasm",
    ],
    "Whole Body": [
        "Extreme fatigue",
        "Fatigue linked to cycle",
        "Shoulder or chest pain during period",
        "Leg pain or numbness",
        "Nerve pain",
        "Night sweats",
        "Fever during period",
        "Brain fog",
        "Difficulty sleeping",
        "Low mood linked to cycle",
        "Anxiety linked to cycle",
        "Dizziness",
    ],
    "Hormonal & Skin": [
        "Acne linked to cycle",
        "Breast tenderness",
        "Hair thinning or loss",
        "Mood swings",
        "Severe PMS",
        "Water retention",
        "Headaches linked to cycle",
        "Weight changes linked to cycle",
        "Hot flushes",
    ],
]

let symptomCategoryOrder = [
    "Period & Bleeding",
    "Pelvic & Back Pain",
    "Bowel & Digestive",
    "Bladder & Urinary",
    "Sex & Intimacy",
    "Whole Body",
    "Hormonal & Skin",
]

let noSeveritySymptoms: Set<String> = [
    "Periods lasting longer than 7 days",
    "Irregular cycle",
    "Cycle length changes",
]

let preloadedMeds = [
    "Ibuprofen", "Naproxen", "Paracetamol", "Tranexamic acid",
    "Endone", "Tramadol", "Ponstan", "Amitriptyline", "Gabapentin",
]

let preloadedManagement = [
    "Walking", "Yoga", "Swimming", "Heat pack", "TENS machine",
    "Rest", "Meditation", "Stretching", "Physiotherapy exercises", "Hot bath",
]

let effectivenessLabels: [Int: String] = [
    1: "No help",
    2: "Slight help",
    3: "Moderate help",
    4: "Good help",
    5: "Complete relief",
]

let severityLabels: [Int: String] = [
    1: "Minimal",
    2: "Mild",
    3: "Mild-Moderate",
    4: "Moderate",
    5: "Moderate",
    6: "Moderate-Severe",
    7: "Severe",
    8: "Severe",
    9: "Very Severe",
    10: "Unbearable",
]
