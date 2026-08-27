import SwiftUI
import SwiftData

struct DownloadsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayerManager.self) private var audioManager
    let viewModel: LibraryViewModel

    var downloadedSongs: [Song] {
        viewModel.songs.filter { !$0.filePath.isEmpty }
    }

    var body: some View {
        Group {
            if downloadedSongs.isEmpty {
                ContentUnavailableView("No Downloads", systemImage: "arrow.down.circle", description: Text("Downloaded songs will appear here"))
            } else {
                List {
                    ForEach(downloadedSongs) { song in
                        SongRow(song: song)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                audioManager.play(queue: downloadedSongs, startIndex: firstIndex(of: song))
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteSong(song, modelContext: modelContext)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Downloads")
        .onAppear {
            viewModel.loadSongs(modelContext: modelContext)
        }
    }

    private func firstIndex(of song: Song) -> Int {
        downloadedSongs.firstIndex(where: { $0.id == song.id }) ?? 0
    }
}
