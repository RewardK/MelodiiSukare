import Foundation
import SwiftData

@Observable
final class LibraryViewModel {
    var songs: [Song] = []
    var playlists: [Playlist] = []
    var history: [HistoryEntry] = []
    var favorites: [Song] = []

    func loadAll(modelContext: ModelContext) {
        loadSongs(modelContext: modelContext)
        loadPlaylists(modelContext: modelContext)
        loadHistory(modelContext: modelContext)
        loadFavorites(modelContext: modelContext)
    }

    func loadSongs(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        songs = (try? modelContext.fetch(descriptor)) ?? []
    }

    func loadPlaylists(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Playlist>(sortBy: [SortDescriptor(\.dateCreated, order: .reverse)])
        playlists = (try? modelContext.fetch(descriptor)) ?? []
    }

    func loadHistory(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<HistoryEntry>(sortBy: [SortDescriptor(\.playedAt, order: .reverse)])
        history = (try? modelContext.fetch(descriptor)) ?? []
    }

    func loadFavorites(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Song>(predicate: #Predicate { $0.isFavorite }, sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        favorites = (try? modelContext.fetch(descriptor)) ?? []
    }

    func toggleFavorite(_ song: Song, modelContext: ModelContext) {
        song.isFavorite.toggle()
        try? modelContext.save()
        loadFavorites(modelContext: modelContext)
    }

    func deleteSong(_ song: Song, modelContext: ModelContext) {
        if let filePath = song.filePath as String? {
            try? DownloadManager().deleteSongFile(filePath: filePath)
        }
        modelContext.delete(song)
        try? modelContext.save()
        loadAll(modelContext: modelContext)
    }

    func createPlaylist(name: String, modelContext: ModelContext) {
        let playlist = Playlist(name: name)
        modelContext.insert(playlist)
        try? modelContext.save()
        loadPlaylists(modelContext: modelContext)
    }

    func deletePlaylist(_ playlist: Playlist, modelContext: ModelContext) {
        modelContext.delete(playlist)
        try? modelContext.save()
        loadPlaylists(modelContext: modelContext)
    }

    func addSongToPlaylist(_ song: Song, playlist: Playlist, modelContext: ModelContext) {
        playlist.songs?.append(song)
        try? modelContext.save()
    }

    func removeSongFromPlaylist(_ song: Song, playlist: Playlist, modelContext: ModelContext) {
        playlist.songs?.removeAll { $0.id == song.id }
        try? modelContext.save()
    }

    func clearHistory(modelContext: ModelContext) {
        for entry in history {
            modelContext.delete(entry)
        }
        try? modelContext.save()
        history = []
    }
}
