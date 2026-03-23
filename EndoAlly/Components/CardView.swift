import SwiftUI

struct CardView<Content: View>: View {
    var backgroundColor: Color
    var content: () -> Content

    init(backgroundColor: Color = .white, @ViewBuilder content: @escaping () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(13)
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

struct RoseCardView<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        CardView(backgroundColor: Color.roseLight, content: content)
    }
}

struct SageCardView<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        CardView(backgroundColor: Color.sageLight, content: content)
    }
}

// MARK: - Section Title
struct SectionLabel: View {
    let text: String
    var color: Color = .rose

    var body: some View {
        Text(text.uppercased())
            .font(.custom("DMSans-Bold", size: 10).leading(.tight))
            .tracking(1.0)
            .foregroundColor(color)
    }
}
