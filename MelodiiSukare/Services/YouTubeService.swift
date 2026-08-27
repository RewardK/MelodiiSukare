import Foundation
import CryptoKit

final class YouTubeService: Sendable {
    static let shared = YouTubeService()
    private let apiKey: String

    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: "youtube_api_key") ?? ""
    }

    func search(query: String) async throws -> [YouTubeSearchResult] {
        guard !apiKey.isEmpty else {
            throw YouTubeError.apiKeyNotConfigured
        }

        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "25"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)

        let videoIDs = response.items.map { $0.id.videoId }
        let durations = try await fetchDurations(videoIDs: videoIDs)

        return response.items.map { item in
            YouTubeSearchResult(
                title: item.snippet.title,
                channelTitle: item.snippet.channelTitle,
                thumbnailURL: item.snippet.thumbnails.high.url,
                duration: durations[item.id.videoId] ?? "0:00",
                videoID: item.id.videoId
            )
        }
    }

    private func fetchDurations(videoIDs: [String]) async throws -> [String: String] {
        guard !videoIDs.isEmpty, !apiKey.isEmpty else { return [:] }

        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/videos")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "contentDetails"),
            URLQueryItem(name: "id", value: videoIDs.joined(separator: ",")),
            URLQueryItem(name: "key", value: apiKey)
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(YouTubeVideoDetailsResponse.self, from: data)

        var durations: [String: String] = [:]
        for item in response.items {
            durations[item.id] = iso8601ToReadableDuration(iso: item.contentDetails.duration)
        }
        return durations
    }

    private func iso8601ToReadableDuration(iso: String) -> String {
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return "0:00" }
        let nsRange = NSRange(iso.startIndex..., in: iso)
        guard let match = regex.firstMatch(in: iso, range: nsRange) else { return "0:00" }

        let hours = Int((match.range(at: 1).location != NSNotFound ? String(iso[Range(match.range(at: 1), in: iso)!]) : "0")) ?? 0
        let minutes = Int((match.range(at: 2).location != NSNotFound ? String(iso[Range(match.range(at: 2), in: iso)!]) : "0")) ?? 0
        let seconds = Int((match.range(at: 3).location != NSNotFound ? String(iso[Range(match.range(at: 3), in: iso)!]) : "0")) ?? 0

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    func extractStreamInfo(videoID: String) async throws -> StreamInfo {
        let url = URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw YouTubeError.invalidResponse
        }

        let patterns = [
            #"var ytInitialPlayerResponse\s*=\s*(\{.+?\});\s*(?:var|</script>)"#,
            #"ytInitialPlayerResponse\s*=\s*(\{.+?\});\s*(?:var|</script>)"#,
            #"window\["ytInitialPlayerResponse"\]\s*=\s*(\{.+?\});"#
        ]

        var playerResponseJSON: String?
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) {
                let range = NSRange(html.startIndex..., in: html)
                if let match = regex.firstMatch(in: html, range: range) {
                    playerResponseJSON = String(html[Range(match.range(at: 1), in: html)!])
                    break
                }
            }
        }

        guard let jsonString = playerResponseJSON,
              let jsonData = jsonString.data(using: .utf8) else {
            throw YouTubeError.playerResponseNotFound
        }

        let playerResponse = try JSONDecoder().decode(PlayerResponse.self, from: jsonData)

        guard let streamingData = playerResponse.streamingData else {
            throw YouTubeError.streamingDataNotFound
        }

        let adaptiveFormats = streamingData.adaptiveFormats ?? []

        let audioFormats = adaptiveFormats.filter { format in
            format.mimeType.contains("audio/mp4") || format.mimeType.contains("audio/webm")
        }

        guard let bestFormat = audioFormats.sorted(by: { $0.bitrate > $1.bitrate }).first,
              let urlString = bestFormat.url else {
            throw YouTubeError.noAudioFormatFound
        }

        guard let streamURL = URL(string: urlString) else {
            throw YouTubeError.invalidURL
        }

        return StreamInfo(
            url: streamURL,
            mimeType: bestFormat.mimeType,
            bitrate: bestFormat.bitrate,
            contentLength: bestFormat.contentLength
        )
    }
}

// MARK: - API Response Models

struct YouTubeSearchResponse: Decodable {
    let items: [SearchItem]
}

struct SearchItem: Decodable {
    let id: VideoID
    let snippet: Snippet
}

struct VideoID: Decodable {
    let videoId: String
}

struct Snippet: Decodable {
    let title: String
    let channelTitle: String
    let thumbnails: Thumbnails
}

struct Thumbnails: Decodable {
    let high: Thumbnail
}

struct Thumbnail: Decodable {
    let url: String
}

struct YouTubeVideoDetailsResponse: Decodable {
    let items: [VideoDetailItem]
}

struct VideoDetailItem: Decodable {
    let id: String
    let contentDetails: ContentDetails
}

struct ContentDetails: Decodable {
    let duration: String
}

struct PlayerResponse: Decodable {
    let streamingData: StreamingData?
}

struct StreamingData: Decodable {
    let adaptiveFormats: [AdaptiveFormat]?
}

struct AdaptiveFormat: Decodable {
    let mimeType: String
    let bitrate: Int
    let url: String?
    let signatureCipher: String?
    let contentLength: Int64

    enum CodingKeys: String, CodingKey {
        case mimeType, bitrate, url, signatureCipher, contentLength
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mimeType = try container.decode(String.self, forKey: .mimeType)
        bitrate = try container.decode(Int.self, forKey: .bitrate)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        signatureCipher = try container.decodeIfPresent(String.self, forKey: .signatureCipher)
        contentLength = (try? container.decode(Int64.self, forKey: .contentLength)) ?? 0
    }
}

// MARK: - Errors

enum YouTubeError: LocalizedError {
    case apiKeyNotConfigured
    case invalidResponse
    case playerResponseNotFound
    case streamingDataNotFound
    case noAudioFormatFound
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured: return "YouTube API key not configured. Add it in Settings."
        case .invalidResponse: return "Invalid response from YouTube."
        case .playerResponseNotFound: return "Could not find player response."
        case .streamingDataNotFound: return "No streaming data available."
        case .noAudioFormatFound: return "No audio format found."
        case .invalidURL: return "Invalid stream URL."
        }
    }
}
