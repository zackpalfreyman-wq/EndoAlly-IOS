import Foundation

struct Report: Codable, Identifiable {
    let id: String
    let userId: String
    let type: String
    let content: String?
    let symptomCount: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId       = "user_id"
        case type
        case content
        case symptomCount = "symptom_count"
        case createdAt    = "created_at"
    }
}

struct ReportInsert: Encodable {
    let userId: String
    let type: String
    let content: String?
    let symptomCount: Int

    enum CodingKeys: String, CodingKey {
        case userId       = "user_id"
        case type
        case content
        case symptomCount = "symptom_count"
    }
}

struct ReportType {
    let id: String
    let label: String
    let description: String
    let usesAI: Bool
}

let reportTypes: [ReportType] = [
    ReportType(id: "full",       label: "Full Report",                     description: "AI narrative + symptom timeline + medication and family history",   usesAI: true),
    ReportType(id: "gp",         label: "GP Summary",                      description: "Concise 1-page summary for a short GP appointment",                  usesAI: true),
    ReportType(id: "specialist", label: "Specialist Report",               description: "Full narrative, timeline, medication and treatment history",          usesAI: true),
    ReportType(id: "timeline",   label: "Symptom Timeline Only",           description: "Grouped symptom history — no AI, generated instantly",               usesAI: false),
    ReportType(id: "medhistory", label: "Medication & Treatment History",  description: "Your logged medications, birth control, and treatments — no AI",      usesAI: false),
]
