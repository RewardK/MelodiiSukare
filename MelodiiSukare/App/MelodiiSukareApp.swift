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
            Tab("Search", systemImage: "magnifyingglass") {
                NavigationStack {
                    SearchView()
                }
            }
            .tag(0)

            Tab("Library", systemImage: "music.note.list") {
                NavigationStack {
                    LibraryView()
                }
            }
            .tag(1)

            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
            .tag(2)
        }
    }
}
