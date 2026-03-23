import Foundation

struct Profile: Codable, Identifiable {
    let id: String
    var name: String?
    var age: Int?
    var cycleLength: Int?
    var periodLength: Int?
    var lastPeriodStart: String?
    var emoji: String
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case cycleLength      = "cycle_length"
        case periodLength     = "period_length"
        case lastPeriodStart  = "last_period_start"
        case emoji
        case createdAt        = "created_at"
        case updatedAt        = "updated_at"
    }

    init(
        id: String,
        name: String? = nil,
        age: Int? = nil,
        cycleLength: Int? = 28,
        periodLength: Int? = 5,
        lastPeriodStart: String? = nil,
        emoji: String = "👤",
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.cycleLength = cycleLength
        self.periodLength = periodLength
        self.lastPeriodStart = lastPeriodStart
        self.emoji = emoji
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ProfileUpdate: Encodable {
    var name: String?
    var age: Int?
    var cycleLength: Int?
    var periodLength: Int?
    var lastPeriodStart: String?
    var emoji: String?
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case name
        case age
        case cycleLength     = "cycle_length"
        case periodLength    = "period_length"
        case lastPeriodStart = "last_period_start"
        case emoji
        case updatedAt       = "updated_at"
    }
}

struct ProfileUpsert: Encodable {
    let id: String
    var name: String?
    var age: Int?
    var cycleLength: Int?
    var periodLength: Int?
    var lastPeriodStart: String?
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case cycleLength     = "cycle_length"
        case periodLength    = "period_length"
        case lastPeriodStart = "last_period_start"
        case updatedAt       = "updated_at"
    }
}
