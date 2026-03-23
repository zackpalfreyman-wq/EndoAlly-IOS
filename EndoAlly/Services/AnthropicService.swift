import Foundation

struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

struct AnthropicRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [AnthropicMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

struct AnthropicContent: Decodable {
    let type: String
    let text: String?
}

struct AnthropicResponse: Decodable {
    let content: [AnthropicContent]
}

enum AnthropicError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from assistant."
        case .apiError(let msg): return msg
        case .noContent: return "No content returned."
        }
    }
}

private let chatSystemPrompt = """
You are an educational AI assistant for EndoAlly, an Australian health app.

STRICT RULES:
- Provide ONLY general educational information about endometriosis — what it is, diagnostic processes, surgeries, treatments, what to ask doctors
- NEVER comment on user's symptoms or data as assessment or inference
- NEVER use: "this could indicate", "this suggests", "your symptoms are consistent with", "you may have", "this is likely"
- If a user asks "do I have endometriosis?" — respond ONLY: it can be diagnosed solely by a qualified medical professional via laparoscopic surgery, see your GP
- Help users prepare doctor questions, understand terminology, understand diagnostic/treatment processes
- Validate that experiences sound difficult, encourage medical care — without commenting on what they may mean medically
- Use Australian medical terminology. Reference RANZCOG, Jean Hailes, Endometriosis Australia where relevant
- Format responses with bold headings and bullet points
"""

private let reportSystemPrompt = """
You are a medical documentation assistant for EndoAlly, an Australian health app.

STRICT RULES:
- Generate ONLY factual symptom logs based on provided data — no interpretation, no clinical assessment
- NEVER suggest, imply, or infer any condition or diagnosis
- NEVER use: "consistent with", "suggests", "indicates", "may have", "possible [condition]"
- NO pattern analysis, NO clinical interpretation, NO condition matching
- Present symptoms exactly as logged by the user — factual and neutral
- Use plain, clear language appropriate for sharing with a healthcare provider
- Format with clear headings and organised sections
- Include suggested questions for doctors that are neutral and factual (e.g., "What could cause X?" not "Do I have X?")
"""

class AnthropicService {
    static let shared = AnthropicService()
    private init() {}

    private let baseURL = "https://api.anthropic.com/v1/messages"

    private func sendRequest(system: String, messages: [AnthropicMessage], maxTokens: Int) async throws -> String {
        guard let url = URL(string: baseURL) else { throw AnthropicError.invalidResponse }

        let body = AnthropicRequest(
            model: Config.anthropicModel,
            maxTokens: maxTokens,
            system: system,
            messages: messages
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errStr = String(data: data, encoding: .utf8) {
                throw AnthropicError.apiError(errStr)
            }
            throw AnthropicError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        guard let text = decoded.content.first(where: { $0.type == "text" })?.text else {
            throw AnthropicError.noContent
        }
        return text
    }

    func chat(messages: [AnthropicMessage]) async throws -> String {
        try await sendRequest(system: chatSystemPrompt, messages: messages, maxTokens: 1000)
    }

    func generateReport(prompt: String) async throws -> String {
        let messages = [AnthropicMessage(role: "user", content: prompt)]
        return try await sendRequest(system: reportSystemPrompt, messages: messages, maxTokens: 1800)
    }

    func buildReportPrompt(
        type: String,
        profile: Profile?,
        symptoms: [Symptom],
        medications: [HistoryMedication],
        birthControls: [BirthControl],
        treatments: [Treatment],
        therapies: [Therapy],
        familyHistory: [FamilyHistory]
    ) -> String {
        let profileStr: String
        if let p = profile {
            profileStr = "Patient: \(p.name ?? "Anonymous"), Age: \(p.age.map { String($0) } ?? "not provided"), Cycle length: \(p.cycleLength.map { String($0) } ?? "unknown") days, Period length: \(p.periodLength.map { String($0) } ?? "unknown") days"
        } else {
            profileStr = "Patient: Anonymous"
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let displayFmt = DateFormatter()
        displayFmt.dateFormat = "d MMM yyyy"
        displayFmt.locale = Locale(identifier: "en_AU")

        let sympStr = symptoms.isEmpty ? "No symptoms logged." :
            symptoms.map { s in
                var line = "- \(s.symptom) (\(s.category)), Phase: \(s.phase ?? "unknown")"
                if let sev = s.severity { line += ", Severity: \(sev)/10" }
                if let notes = s.notes { line += ", Notes: \(notes)" }
                let dateStr: String
                if let d = fmt.date(from: s.loggedAt) {
                    dateStr = displayFmt.string(from: d)
                } else {
                    dateStr = s.loggedAt
                }
                line += ", Date: \(dateStr)"
                return line
            }.joined(separator: "\n")

        let medStr = medications.isEmpty ? "None logged." :
            medications.map { m in
                "- \(m.name)\(m.dose.map { " (\($0))" } ?? "")\(m.stillTaking ? ", current" : ", past")"
            }.joined(separator: "\n")

        let bcStr = birthControls.isEmpty ? "None logged." :
            birthControls.map { b in
                "- \(b.bcType)\(b.brand.map { " (\($0))" } ?? "")\(b.stillUsing ? ", current" : ", past")"
            }.joined(separator: "\n")

        let treatStr = treatments.isEmpty ? "None logged." :
            treatments.map { t in
                "- \(t.name) (\(t.treatmentType))\(t.date.map { ", \($0)" } ?? "")"
            }.joined(separator: "\n")

        let fhStr = familyHistory.isEmpty ? "None logged." :
            familyHistory.map { f in "- \(f.relation): \(f.condition)" }.joined(separator: "\n")

        switch type {
        case "gp":
            return """
            Generate a concise GP Summary for a short medical appointment.

            \(profileStr)

            Symptoms logged (\(symptoms.count) total):
            \(sympStr)

            Current medications:
            \(medStr)

            Format as: Patient Overview, Key Symptoms Logged (factual list only), Suggested Questions for Doctor (4-5 neutral questions like "What could be causing X?").

            IMPORTANT: Factual only. No interpretation. No pattern analysis. No condition suggestion.
            """

        case "specialist":
            return """
            Generate a Specialist Report for a gynaecology/specialist appointment.

            \(profileStr)

            All symptoms logged (\(symptoms.count) total):
            \(sympStr)

            Medications:
            \(medStr)

            Birth control:
            \(bcStr)

            Past treatments:
            \(treatStr)

            Family history:
            \(fhStr)

            Format as: Patient Overview, Symptom Log by Body System (factual), Medication and Management Log, Health History, Suggested Questions for Specialist (5-6 questions about diagnostics, surgery, treatments).

            IMPORTANT: Factual only. No interpretation. No pattern analysis. No condition suggestion.
            """

        default: // full
            let therapyStr = therapies.isEmpty ? "None logged." :
                therapies.map { "- \($0.name)" }.joined(separator: "\n")

            return """
            Generate a Full Symptom Report.

            \(profileStr)

            All symptoms logged (\(symptoms.count) total):
            \(sympStr)

            Medications:
            \(medStr)

            Birth control:
            \(bcStr)

            Past treatments:
            \(treatStr)

            Therapies:
            \(therapyStr)

            Family history:
            \(fhStr)

            Format as: Patient Overview, Symptom Log by Body System, Medication and Management Log, Health History, Suggested Questions for Doctor.

            IMPORTANT: Factual only. No interpretation. No pattern analysis. No condition suggestion.
            """
        }
    }
}
