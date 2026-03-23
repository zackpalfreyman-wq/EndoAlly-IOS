import SwiftUI

struct AssistantView: View {
    @State private var messages: [AnthropicMessage] = []
    @State private var input = ""
    @State private var loading = false
    @State private var error: String?
    @FocusState private var inputFocused: Bool

    private let quickPrompts = [
        "What is endometriosis?",
        "What does a laparoscopy involve?",
        "How do I talk to my GP about pelvic pain?",
        "What questions should I ask a gynaecologist?",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages scroll
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            if messages.isEmpty {
                                WelcomeView(quickPrompts: quickPrompts) { prompt in
                                    sendMessage(prompt)
                                }
                                .padding(.top, 20)
                            }

                            ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                                MessageBubble(message: msg)
                            }
                            .id("msgs")

                            if loading {
                                HStack(alignment: .bottom, spacing: 8) {
                                    Circle()
                                        .fill(Color.roseLight)
                                        .frame(width: 30, height: 30)
                                        .overlay(Image(systemName: "sparkles").foregroundColor(.rose).font(.system(size: 12)))
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .frame(width: 56, height: 36)
                                        .overlay(
                                            HStack(spacing: 4) {
                                                ForEach(0..<3, id: \.self) { i in
                                                    Circle().fill(Color.slateMid).frame(width: 6, height: 6)
                                                        .opacity(0.6)
                                                }
                                            }
                                        )
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }

                            if let err = error {
                                Text(err)
                                    .font(.custom("DMSans-Regular", size: 13))
                                    .foregroundColor(.rose)
                                    .padding(12)
                                    .background(Color.roseLight)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 16)
                            }

                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom") }
                    }
                    .onChange(of: loading) { _, _ in
                        withAnimation { proxy.scrollTo("bottom") }
                    }
                }

                Divider()

                // Input area
                VStack(spacing: 6) {
                    HStack(alignment: .bottom, spacing: 8) {
                        TextField("Ask about endometriosis…", text: $input, axis: .vertical)
                            .lineLimit(1...4)
                            .font(.custom("DMSans-Regular", size: 14))
                            .foregroundColor(.charcoal)
                            .focused($inputFocused)
                            .onSubmit { if !input.isEmpty { sendMessage(input) } }

                        Button(action: { sendMessage(input) }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 34, height: 34)
                                .background(input.trimmingCharacters(in: .whitespaces).isEmpty || loading ? Color.appBorder : Color.rose)
                                .cornerRadius(10)
                        }
                        .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || loading)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1.5))
                    .padding(.horizontal, 16)

                    Text("Educational information only. Not medical advice. Always consult your doctor.")
                        .font(.custom("DMSans-Regular", size: 10))
                        .foregroundColor(.slateMid)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                .background(Color.warmWhite)
            }
            .background(Color.warmWhite)
            .navigationTitle("Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !loading else { return }
        error = nil
        let userMsg = AnthropicMessage(role: "user", content: trimmed)
        messages.append(userMsg)
        input = ""
        loading = true

        Task {
            do {
                let reply = try await AnthropicService.shared.chat(messages: messages)
                messages.append(AnthropicMessage(role: "assistant", content: reply))
            } catch {
                self.error = "Sorry, something went wrong. Please try again."
            }
            loading = false
        }
    }
}

// MARK: - Welcome view
struct WelcomeView: View {
    let quickPrompts: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.roseLight)
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: "sparkles").foregroundColor(.rose).font(.system(size: 24)))

            Text("EndoAlly Assistant")
                .font(.custom("DMSans-SemiBold", size: 22))
                .foregroundColor(.charcoal)

            Text("I provide general educational information about endometriosis.\nI cannot assess your symptoms or provide medical advice.")
                .font(.custom("DMSans-Regular", size: 13))
                .foregroundColor(.slateMid)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("QUICK QUESTIONS")
                    .font(.custom("DMSans-Bold", size: 10).leading(.tight))
                    .tracking(1.0)
                    .foregroundColor(.slateMid)

                ForEach(quickPrompts, id: \.self) { prompt in
                    Button(action: { onSelect(prompt) }) {
                        HStack {
                            Text(prompt)
                                .font(.custom("DMSans-Medium", size: 13))
                                .foregroundColor(.charcoal)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(.slateMid)
                                .font(.system(size: 12))
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Message bubble
struct MessageBubble: View {
    let message: AnthropicMessage
    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isUser {
                Circle()
                    .fill(Color.roseLight)
                    .frame(width: 30, height: 30)
                    .overlay(Image(systemName: "sparkles").foregroundColor(.rose).font(.system(size: 12)))
            }

            if isUser {
                Spacer()
                Text(message.content)
                    .font(.custom("DMSans-Regular", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.rose)
                    .cornerRadius(16)
                    .cornerRadius(4, corners: .bottomRight)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    AssistantTextView(text: message.content)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(16)
                .cornerRadius(4, corners: .bottomLeft)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
                Spacer()
            }
        }
    }
}

// MARK: - Assistant text renderer
struct AssistantTextView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(parseLines(text), id: \.id) { line in
                switch line.type {
                case "h2":
                    Text(line.text)
                        .font(.custom("DMSans-SemiBold", size: 15))
                        .foregroundColor(.charcoal)
                        .padding(.top, 4)
                case "h3":
                    Text(line.text)
                        .font(.custom("DMSans-SemiBold", size: 14))
                        .foregroundColor(.charcoal)
                case "bullet":
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").foregroundColor(.rose)
                        Text(line.text)
                            .font(.custom("DMSans-Regular", size: 14))
                            .foregroundColor(.charcoal)
                    }
                default:
                    Text(line.text)
                        .font(.custom("DMSans-Regular", size: 14))
                        .foregroundColor(.charcoal)
                }
            }
        }
    }

    struct Line: Identifiable {
        let id = UUID()
        let type: String
        let text: String
    }

    private func parseLines(_ content: String) -> [Line] {
        content.components(separatedBy: "\n").compactMap { raw in
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { return nil }
            if line.hasPrefix("## ")  { return Line(type: "h2",     text: String(line.dropFirst(3))) }
            if line.hasPrefix("### ") { return Line(type: "h3",     text: String(line.dropFirst(4))) }
            if line.hasPrefix("- ") || line.hasPrefix("* ") { return Line(type: "bullet", text: String(line.dropFirst(2))) }
            if line.hasPrefix("#")    { return nil }
            return Line(type: "paragraph", text: line)
        }
    }
}

// MARK: - Corner radius helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
