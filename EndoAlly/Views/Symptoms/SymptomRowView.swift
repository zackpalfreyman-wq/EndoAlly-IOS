import SwiftUI

struct SymptomRowView: View {
    let symptom: Symptom
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(symptom.symptom)
                    .font(.custom("DMSans-SemiBold", size: 14))
                    .foregroundColor(.charcoal)
                HStack(spacing: 4) {
                    Text(symptom.category)
                        .font(.custom("DMSans-Regular", size: 12))
                        .foregroundColor(.slateMid)
                    if let phase = symptom.phase, let p = CyclePhase(rawValue: phase) {
                        Text("·")
                            .foregroundColor(.slateMid)
                        Text(phase)
                            .font(.custom("DMSans-SemiBold", size: 12))
                            .foregroundColor(phaseColor(for: p))
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let sev = symptom.severity {
                    Text("\(sev)/10")
                        .font(.custom("DMSans-Bold", size: 12))
                        .foregroundColor(.rose)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.roseLight)
                        .cornerRadius(8)
                }
                Text(formattedDate)
                    .font(.custom("DMSans-Regular", size: 11))
                    .foregroundColor(.slateMid)
            }
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(.slateMid)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .overlay(Divider(), alignment: .bottom)
    }

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let d2 = DateFormatter()
        d2.dateFormat = "d MMM"
        d2.locale = Locale(identifier: "en_AU")
        if let d = fmt.date(from: symptom.loggedAt) { return d2.string(from: d) }
        return symptom.loggedAt
    }
}
