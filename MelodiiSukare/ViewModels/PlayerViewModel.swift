import Foundation
import SwiftData

@Observable
final class PlayerViewModel {
    var showFullPlayer = false
    var audioManager: AudioPlayerManager
    var downloadManager: DownloadManager
    var modelContext: ModelContext?

    init(audioManager: AudioPlayerManager, downloadManager: DownloadManager) {
        self.audioManager = audioManager
        self.downloadManager = downloadManager
    }

    func downloadAndPlay(result: YouTubeSearchResult) {
        guard let modelContext else { return }

        Task {
            await downloadManager.download(
                videoID: result.videoID,
                title: result.title,
                artist: result.channelTitle,
                artworkURL: result.thumbnailURL,
                duration: parseDuration(result.duration),
                modelContext: modelContext
            )

            let descriptor = FetchDescriptor<Song>()
            if let songs = try? modelContext.fetch(descriptor),
               let song = songs.first(where: { $0.youtubeVideoID == result.videoID }) {
                audioManager.playSong(song)
            }
        }
    }

    func playSong(_ song: Song) {
        audioManager.playSong(song)
    }

    func playFromList(_ songs: [Song], startAt index: Int) {
        audioManager.play(queue: songs, startIndex: index)
    }

    func toggleFavorite(_ song: Song) {
        song.isFavorite.toggle()
        try? modelContext?.save()
    }

    private func parseDuration(_ duration: String) -> Double {
        let parts = duration.split(separator: ":").map { Int($0) ?? 0 }
        if parts.count == 3 {
            return Double(parts[0] * 3600 + parts[1] * 60 + parts[2])
        } else if parts.count == 2 {
            return Double(parts[0] * 60 + parts[1])
        }
        return Double(parts.first ?? 0)
    }
}
