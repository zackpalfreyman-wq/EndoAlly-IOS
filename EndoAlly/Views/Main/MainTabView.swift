import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            AssistantView()
                .tabItem {
                    Label("Assistant", systemImage: "sparkles")
                }
                .tag(1)

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }
                .tag(2)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(.rose)
    }
}

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    @Published var selectedTab: Int = 0
    private init() {}
}
