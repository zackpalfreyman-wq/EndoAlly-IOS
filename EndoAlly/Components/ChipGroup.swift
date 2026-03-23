import SwiftUI

struct Chip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom("DMSans-Medium", size: 13))
                .foregroundColor(selected ? .white : .charcoal)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Color.rose : Color.warmWhite)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(selected ? Color.rose : Color.appBorder, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ChipGroup<T: Hashable>: View {
    let options: [T]
    let labelFor: (T) -> String
    var selected: Set<T>
    let onToggle: (T) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Chip(
                    label: labelFor(option),
                    selected: selected.contains(option),
                    action: { onToggle(option) }
                )
            }
        }
    }
}

struct SingleChipGroup<T: Hashable>: View {
    let options: [T]
    let labelFor: (T) -> String
    var selected: T?
    let onSelect: (T?) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Chip(
                    label: labelFor(option),
                    selected: selected == option,
                    action: {
                        if selected == option {
                            onSelect(nil)
                        } else {
                            onSelect(option)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Flow Layout (wrapping chip container)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
