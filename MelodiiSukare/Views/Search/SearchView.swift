import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayerManager.self) private var audioManager
    @Environment(DownloadManager.self) private var downloadManager
    @State private var viewModel = SearchViewModel()
    @State private var playerViewModel: PlayerViewModel?

    var body: some View {
        List {
            if viewModel.searchResults.isEmpty && !viewModel.isLoading && viewModel.searchText.isEmpty {
                ContentUnavailableView("Search YouTube", systemImage: "magnifyingglass", description: Text("Find your favorite songs"))
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                ForEach(viewModel.searchResults) { result in
                    SearchResultRow(result: result)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playerViewModel?.downloadAndPlay(result: result)
                        }
                }
            }
        }
        .navigationTitle("Search")
        .searchable(text: $viewModel.searchText, prompt: "Search songs...")
        .onChange(of: viewModel.searchText) {
            viewModel.search()
        }
        .onAppear {
            if playerViewModel == nil {
                playerViewModel = PlayerViewModel(audioManager: audioManager, downloadManager: downloadManager)
                playerViewModel?.modelContext = modelContext
            }
        }
        .overlay {
            if !downloadManager.activeDownloads.isEmpty {
                VStack {
                    Spacer()
                    downloadProgressView
                }
            }
        }
    }

    private var downloadProgressView: some View {
        VStack(spacing: 4) {
            ForEach(Array(downloadManager.activeDownloads.values), id: \.videoID) { progress in
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text(progressStatusText(progress))
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
    }

    private func progressStatusText(_ progress: DownloadProgress) -> String {
        switch progress.status {
        case .downloading: return "Downloading..."
        case .completed: return "Downloaded"
        case .failed(let error): return "Failed: \(error)"
        }
    }
}
