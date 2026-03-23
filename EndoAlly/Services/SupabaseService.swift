import Foundation
import Supabase

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }

    // MARK: - Profile
    func fetchProfile(userId: String) async throws -> Profile {
        let response: Profile = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return response
    }

    func upsertProfile(_ upsert: ProfileUpsert) async throws -> Profile {
        let response: Profile = try await client
            .from("profiles")
            .upsert(upsert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func updateProfile(userId: String, update: ProfileUpdate) async throws -> Profile {
        let response: Profile = try await client
            .from("profiles")
            .update(update)
            .eq("id", value: userId)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    // MARK: - Symptoms
    func fetchSymptoms(userId: String) async throws -> [Symptom] {
        let response: [Symptom] = try await client
            .from("symptoms")
            .select()
            .eq("user_id", value: userId)
            .order("logged_at", ascending: false)
            .execute()
            .value
        return response
    }

    func insertSymptom(_ insert: SymptomInsert) async throws -> Symptom {
        let response: Symptom = try await client
            .from("symptoms")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func deleteSymptom(id: String) async throws {
        try await client
            .from("symptoms")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Check-ins
    func fetchCheckIns(userId: String) async throws -> [CheckIn] {
        let response: [CheckIn] = try await client
            .from("checkins")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
            .value
        return response
    }

    func fetchTodayCheckIn(userId: String) async throws -> CheckIn? {
        let today = todayString()
        let response: [CheckIn] = try await client
            .from("checkins")
            .select()
            .eq("user_id", value: userId)
            .eq("date", value: today)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    func insertCheckIn(_ insert: CheckInInsert) async throws -> CheckIn {
        let response: CheckIn = try await client
            .from("checkins")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func updateCheckIn(id: String, update: CheckInUpdate) async throws -> CheckIn {
        let response: CheckIn = try await client
            .from("checkins")
            .update(update)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func deleteCheckIn(id: String) async throws {
        try await client
            .from("checkins")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Reports
    func fetchReports(userId: String) async throws -> [Report] {
        let response: [Report] = try await client
            .from("reports")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func insertReport(_ insert: ReportInsert) async throws -> Report {
        let response: Report = try await client
            .from("reports")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func deleteReport(id: String) async throws {
        try await client
            .from("reports")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Family History
    func fetchFamilyHistory(userId: String) async throws -> [FamilyHistory] {
        let response: [FamilyHistory] = try await client
            .from("history_family")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        return response
    }

    func insertFamilyHistory(_ insert: FamilyHistoryInsert) async throws -> FamilyHistory {
        let response: FamilyHistory = try await client
            .from("history_family")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func deleteFamilyHistory(id: String) async throws {
        try await client
            .from("history_family")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Medications
    func fetchMedications(userId: String) async throws -> [HistoryMedication] {
        let response: [HistoryMedication] = try await client
            .from("history_medications")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        return response
    }

    func insertMedication(_ insert: MedicationInsert) async throws -> HistoryMedication {
        let response: HistoryMedication = try await client
            .from("history_medications")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func updateMedication(id: String, update: MedicationUpdate) async throws {
        try await client
            .from("history_medications")
            .update(update)
            .eq("id", value: id)
            .execute()
    }

    func deleteMedication(id: String) async throws {
        try await client
            .from("history_medications")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Birth Control
    func fetchBirthControl(userId: String) async throws -> [BirthControl] {
        let response: [BirthControl] = try await client
            .from("history_birth_control")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        return response
    }

    func insertBirthControl(_ insert: BirthControlInsert) async throws -> BirthControl {
        let response: BirthControl = try await client
            .from("history_birth_control")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func deleteBirthControl(id: String) async throws {
        try await client
            .from("history_birth_control")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Treatments
    func fetchTreatments(userId: String) async throws -> [Treatment] {
        let response: [Treatment] = try await client
            .from("history_treatments")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        return response
    }

    func insertTreatment(_ insert: TreatmentInsert) async throws -> Treatment {
        let response: Treatment = try await client
            .from("history_treatments")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func deleteTreatment(id: String) async throws {
        try await client
            .from("history_treatments")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Therapies
    func fetchTherapies(userId: String) async throws -> [Therapy] {
        let response: [Therapy] = try await client
            .from("history_therapies")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        return response
    }

    func insertTherapy(_ insert: TherapyInsert) async throws -> Therapy {
        let response: Therapy = try await client
            .from("history_therapies")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func deleteTherapy(id: String) async throws {
        try await client
            .from("history_therapies")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Clear all data
    func clearAllData(userId: String) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.client.from("symptoms").delete().eq("user_id", value: userId).execute()
            }
            group.addTask {
                try await self.client.from("checkins").delete().eq("user_id", value: userId).execute()
            }
            group.addTask {
                try await self.client.from("history_family").delete().eq("user_id", value: userId).execute()
            }
            group.addTask {
                try await self.client.from("history_medications").delete().eq("user_id", value: userId).execute()
            }
            group.addTask {
                try await self.client.from("history_birth_control").delete().eq("user_id", value: userId).execute()
            }
            group.addTask {
                try await self.client.from("history_treatments").delete().eq("user_id", value: userId).execute()
            }
            group.addTask {
                try await self.client.from("history_therapies").delete().eq("user_id", value: userId).execute()
            }
            group.addTask {
                try await self.client.from("reports").delete().eq("user_id", value: userId).execute()
            }
            try await group.waitForAll()
        }
    }
}
