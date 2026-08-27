import Foundation
import SwiftData

@Model
final class Song {
    var title: String
    var artist: String
    var artworkURL: String
    var duration: Double
    var filePath: String
    var youtubeVideoID: String
    var isFavorite: Bool
    var dateAdded: Date
    var lastPlayed: Date?

    @Relationship(inverse: \Playlist.songs)
    var playlists: [Playlist]?

    @Relationship(inverse: \HistoryEntry.song)
    var historyEntries: [HistoryEntry]?

    init(title: String, artist: String, artworkURL: String, duration: Double, filePath: String, youtubeVideoID: String, isFavorite: Bool = false, dateAdded: Date = .now) {
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
        self.duration = duration
        self.filePath = filePath
        self.youtubeVideoID = youtubeVideoID
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
    }
}

@Model
final class Playlist {
    var name: String
    var dateCreated: Date
    var songs: [Song]?

    init(name: String, dateCreated: Date = .now) {
        self.name = name
        self.dateCreated = dateCreated
    }
}

@Model
final class HistoryEntry {
    var song: Song?
    var playedAt: Date

    init(song: Song? = nil, playedAt: Date = .now) {
        self.song = song
        self.playedAt = playedAt
    }
}

struct YouTubeSearchResult: Identifiable, Sendable {
    let id: String
    let title: String
    let channelTitle: String
    let thumbnailURL: String
    let duration: String
    let videoID: String

    init(id: String = UUID().uuidString, title: String, channelTitle: String, thumbnailURL: String, duration: String, videoID: String) {
        self.id = id
        self.title = title
        self.channelTitle = channelTitle
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.videoID = videoID
    }
}

struct StreamInfo: Sendable {
    let url: URL
    let mimeType: String
    let bitrate: Int
    let contentLength: Int64
}
