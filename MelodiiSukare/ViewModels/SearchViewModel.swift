import Foundation
import SwiftData

@Observable
final class SearchViewModel {
    var searchText = ""
    var searchResults: [YouTubeSearchResult] = []
    var isLoading = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                let results = try await YouTubeService.shared.search(query: query)
                guard !Task.isCancelled else { return }
                searchResults = results
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                searchResults = []
            }

            isLoading = false
        }
    }

    func cancelSearch() {
        searchTask?.cancel()
        isLoading = false
    }
}
