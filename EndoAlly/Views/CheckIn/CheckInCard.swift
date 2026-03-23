import SwiftUI

struct CheckInCard: View {
    let checkIn: CheckIn

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    let dateFmt = DateFormatter()
                    let _ = { dateFmt.dateFormat = "yyyy-MM-dd" }()
                    let displayFmt = DateFormatter()
                    let _ = { displayFmt.dateFormat = "d MMM yyyy"; displayFmt.locale = Locale(identifier: "en_AU") }()
                    let dateStr: String = {
                        if let d = dateFmt.date(from: checkIn.date) { return displayFmt.string(from: d) }
                        return checkIn.date
                    }()
                    Text(dateStr)
                        .font(.custom("DMSans-SemiBold", size: 14))
                        .foregroundColor(.charcoal)
                    Spacer()
                    if let flow = checkIn.flow, flow != "none" {
                        FlowBadge(flow: flow)
                    }
                }

                if let pain = checkIn.painLevel {
                    HStack(spacing: 6) {
                        Text("Pain")
                            .font(.custom("DMSans-Regular", size: 12))
                            .foregroundColor(.slateMid)
                        Text("\(pain)/5")
                            .font(.custom("DMSans-Bold", size: 12))
                            .foregroundColor(.rose)
                    }
                }

                if let moods = checkIn.mood, !moods.isEmpty {
                    Text(moods.map { $0.capitalized }.joined(separator: ", "))
                        .font(.custom("DMSans-Regular", size: 12))
                        .foregroundColor(.slateMid)
                }
            }
        }
    }
}

struct FlowBadge: View {
    let flow: String

    private var color: Color {
        switch flow {
        case "heavy":   return Color(hex: "#C2566A")
        case "medium":  return Color(hex: "#C8626E")
        case "light":   return Color(hex: "#C8A96E")
        case "spotting": return Color(hex: "#B8BE6A")
        default:        return .slateMid
        }
    }

    var body: some View {
        Text(flow.capitalized)
            .font(.custom("DMSans-SemiBold", size: 11))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}
