import Foundation

struct CheckIn: Codable, Identifiable {
    let id: String
    let userId: String
    let date: String
    var flow: String?
    var painLevel: Int?
    var mood: [String]?
    var energy: String?
    var bloating: String?
    var sleep: String?
    var bowel: [String]?
    var nausea: Bool?
    var discharge: String?
    var notes: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case date
        case flow
        case painLevel = "pain_level"
        case mood
        case energy
        case bloating
        case sleep
        case bowel
        case nausea
        case discharge
        case notes
        case createdAt = "created_at"
    }
}

struct CheckInInsert: Encodable {
    let userId: String
    let date: String
    let flow: String?
    let painLevel: Int?
    let mood: [String]?
    let energy: String?
    let bloating: String?
    let sleep: String?
    let bowel: [String]?
    let nausea: Bool?
    let discharge: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case userId    = "user_id"
        case date
        case flow
        case painLevel = "pain_level"
        case mood
        case energy
        case bloating
        case sleep
        case bowel
        case nausea
        case discharge
        case notes
    }
}

struct CheckInUpdate: Encodable {
    let date: String?
    let flow: String?
    let painLevel: Int?
    let mood: [String]?
    let energy: String?
    let bloating: String?
    let sleep: String?
    let bowel: [String]?
    let nausea: Bool?
    let discharge: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case date
        case flow
        case painLevel = "pain_level"
        case mood
        case energy
        case bloating
        case sleep
        case bowel
        case nausea
        case discharge
        case notes
    }
}

// MARK: - Check-in option constants
let flowOptions      = ["none", "spotting", "light", "medium", "heavy"]
let moodOptions      = ["happy", "good", "calm", "okay", "sad", "low", "anxious", "irritable", "overwhelmed", "sensitive"]
let energyOptions    = ["high", "normal", "low", "exhausted"]
let bloatOptions     = ["none", "mild", "moderate", "severe"]
let sleepOptions     = ["good", "okay", "poor"]
let bowelOptions     = ["normal", "constipated", "loose", "painful"]
let dischargeOptions = ["none", "white_creamy", "clear_stretchy", "yellow", "brown"]
let dischargeLabels  = [
    "none": "None",
    "white_creamy": "White / Creamy",
    "clear_stretchy": "Clear & Stretchy",
    "yellow": "Yellow",
    "brown": "Brown",
]
