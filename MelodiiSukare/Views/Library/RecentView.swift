import SwiftUI
import SwiftData

struct RecentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayerManager.self) private var audioManager
    let viewModel: LibraryViewModel

    var body: some View {
        Group {
            if viewModel.history.isEmpty {
                ContentUnavailableView("No History", systemImage: "clock", description: Text("Recently played songs will appear here"))
            } else {
                List {
                    ForEach(viewModel.history) { entry in
                        if let song = entry.song {
                            SongRow(song: song)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    audioManager.playSong(song)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        modelContext.delete(entry)
                                        try? modelContext.save()
                                        viewModel.loadHistory(modelContext: modelContext)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle("Recently Played")
        .toolbar {
            if !viewModel.history.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        viewModel.clearHistory(modelContext: modelContext)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadHistory(modelContext: modelContext)
        }
    }
}
