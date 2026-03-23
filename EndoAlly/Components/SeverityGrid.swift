import SwiftUI

struct SeverityGrid: View {
    @Binding var value: Int?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(1...10, id: \.self) { level in
                    Button(action: {
                        if value == level { value = nil }
                        else { value = level }
                    }) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(value == level ? Color.severityColor(for: level) : Color.severityColor(for: level).opacity(0.25))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text("\(level)")
                                        .font(.custom("DMSans-Bold", size: 11))
                                        .foregroundColor(value == level ? .white : .charcoal)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(value == level ? Color.severityColor(for: level) : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            if let selected = value, let label = severityLabels[selected] {
                Text(label)
                    .font(.custom("DMSans-Medium", size: 13))
                    .foregroundColor(Color.severityColor(for: selected))
            }
        }
    }
}
