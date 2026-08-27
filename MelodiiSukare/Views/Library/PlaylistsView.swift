import SwiftUI
import SwiftData

struct PlaylistsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayerManager.self) private var audioManager
    let playlist: Playlist
    let viewModel: LibraryViewModel

    var body: some View {
        Group {
            if playlist.songs?.isEmpty ?? true {
                ContentUnavailableView("Empty Playlist", systemImage: "music.note.list", description: Text("Add songs to this playlist from your library"))
            } else {
                List {
                    if let songs = playlist.songs {
                        ForEach(songs) { song in
                            SongRow(song: song)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    audioManager.play(queue: songs, startIndex: firstIndex(of: song, in: songs))
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.removeSongFromPlaylist(song, playlist: playlist, modelContext: modelContext)
                                    } label: {
                                        Label("Remove", systemImage: "minus.circle")
                                    }
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle(playlist.name)
    }

    private func firstIndex(of song: Song, in songs: [Song]) -> Int {
        songs.firstIndex(where: { $0.id == song.id }) ?? 0
    }
}
