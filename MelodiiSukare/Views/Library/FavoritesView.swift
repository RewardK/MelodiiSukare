import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayerManager.self) private var audioManager
    let viewModel: LibraryViewModel

    var body: some View {
        Group {
            if viewModel.favorites.isEmpty {
                ContentUnavailableView("No Favorites", systemImage: "heart.slash", description: Text("Songs you favorite will appear here"))
            } else {
                List {
                    ForEach(viewModel.favorites) { song in
                        SongRow(song: song)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                audioManager.play(queue: viewModel.favorites, startIndex: firstIndex(of: song))
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
        .navigationTitle("Favorites")
        .onAppear {
            viewModel.loadFavorites(modelContext: modelContext)
        }
    }

    private func firstIndex(of song: Song) -> Int {
        viewModel.favorites.firstIndex(where: { $0.id == song.id }) ?? 0
    }
}
