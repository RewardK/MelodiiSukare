import SwiftUI
import SwiftData

@main
struct MelodiiSukareApp: App {
    @State private var audioPlayerManager = AudioPlayerManager()
    @State private var downloadManager = DownloadManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioPlayerManager)
                .environment(downloadManager)
        }
        .modelContainer(for: [Song.self, Playlist.self, HistoryEntry.self])
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(0)

            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "music.note.list")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
    }
}
