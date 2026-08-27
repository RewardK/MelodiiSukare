import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LibraryViewModel()
    @State private var showNewPlaylistAlert = false
    @State private var newPlaylistName = ""

    var body: some View {
        List {
            Section("Your Music") {
                NavigationLink {
                    FavoritesView(viewModel: viewModel)
                } label: {
                    Label("Favorites", systemImage: "heart.fill")
                        .foregroundStyle(.red)
                }

                NavigationLink {
                    RecentView(viewModel: viewModel)
                } label: {
                    Label("Recently Played", systemImage: "clock.fill")
                        .foregroundStyle(.orange)
                }

                NavigationLink {
                    DownloadsView(viewModel: viewModel)
                } label: {
                    Label("Downloads", systemImage: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                }
            }

            Section("Playlists") {
                ForEach(viewModel.playlists) { playlist in
                    NavigationLink {
                        PlaylistsView(playlist: playlist, viewModel: viewModel)
                    } label: {
                        Label(playlist.name, systemImage: "music.note.list")
                    }
                }

                Button {
                    showNewPlaylistAlert = true
                } label: {
                    Label("New Playlist", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Library")
        .onAppear {
            viewModel.loadAll(modelContext: modelContext)
        }
        .alert("New Playlist", isPresented: $showNewPlaylistAlert) {
            TextField("Playlist Name", text: $newPlaylistName)
            Button("Create") {
                if !newPlaylistName.isEmpty {
                    viewModel.createPlaylist(name: newPlaylistName, modelContext: modelContext)
                    newPlaylistName = ""
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for your new playlist")
        }
    }
}
