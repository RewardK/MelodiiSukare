import Foundation
import SwiftData

@Observable
final class DownloadManager {
    private(set) var activeDownloads: [String: DownloadProgress] = [:]
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    var songsDirectory: URL {
        documentsDirectory.appendingPathComponent("Songs", isDirectory: true)
    }

    init() {
        try? FileManager.default.createDirectory(at: songsDirectory, withIntermediateDirectories: true)
    }

    func download(videoID: String, title: String, artist: String, artworkURL: String, duration: Double, modelContext: ModelContext) async {
        guard activeDownloads[videoID] == nil else { return }

        let progress = DownloadProgress(videoID: videoID, status: .downloading)
        activeDownloads[videoID] = progress

        do {
            let streamInfo = try await YouTubeService.shared.extractStreamInfo(videoID: videoID)

            progress.status = .downloading

            var request = URLRequest(url: streamInfo.url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

            let (tempURL, response) = try await URLSession.shared.download(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw DownloadError.serverError
            }

            let safeFileName = title.replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: ":", with: "_")
            let fileURL = songsDirectory.appendingPathComponent("\(videoID)_\(safeFileName).m4a")

            try FileManager.default.moveItem(at: tempURL, to: fileURL)

            let song = Song(
                title: title,
                artist: artist,
                artworkURL: artworkURL,
                duration: duration,
                filePath: fileURL.path,
                youtubeVideoID: videoID
            )
            modelContext.insert(song)

            progress.status = .completed(fileURL)
        } catch {
            progress.status = .failed(error.localizedDescription)
        }

        try? await Task.sleep(for: .seconds(2))
        activeDownloads.removeValue(forKey: videoID)
    }

    func deleteSongFile(filePath: String) throws {
        let url = URL(fileURLWithPath: filePath)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}

@Observable
final class DownloadProgress {
    let videoID: String
    var status: DownloadStatus

    init(videoID: String, status: DownloadStatus) {
        self.videoID = videoID
        self.status = status
    }
}

enum DownloadStatus {
    case downloading
    case completed(URL)
    case failed(String)
}

enum DownloadError: LocalizedError {
    case serverError

    var errorDescription: String? {
        switch self {
        case .serverError: return "Server error occurred."
        }
    }
}
