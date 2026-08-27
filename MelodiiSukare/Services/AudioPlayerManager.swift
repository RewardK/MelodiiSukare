import AVFoundation
import MediaPlayer
import SwiftUI

@Observable
final class AudioPlayerManager {
    private let player = AVPlayer()
    private var timeObserverToken: Any?

    var currentSong: Song?
    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var playbackProgress: Double = 0
    var queue: [Song] = []
    var queueIndex: Int = -1
    var isShuffleOn = false
    var repeatMode: RepeatMode = .off
    var volume: Float = 1.0

    enum RepeatMode {
        case off, all, one
    }

    init() {
        setupAudioSession()
        setupRemoteCommands()
        setupTimeObserver()
        setupNotifications()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.isPlaying { self.pause() } else { self.play() }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds
            if self.duration > 0 {
                self.playbackProgress = self.currentTime / self.duration
            }
            self.updateNowPlaying()
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackEnd()
        }
    }

    func playSong(_ song: Song) {
        let fileURL = URL(fileURLWithPath: song.filePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        let playerItem = AVPlayerItem(url: fileURL)
        player.replaceCurrentItem(with: playerItem)
        duration = playerItem.asset.duration.seconds
        currentSong = song
        isPlaying = true
        play()

        let historyEntry = HistoryEntry(song: song)
        song.lastPlayed = .now

        updateNowPlaying()
    }

    func play(queue songs: [Song], startIndex: Int = 0) {
        queue = songs
        queueIndex = startIndex
        if startIndex < songs.count {
            playSong(songs[startIndex])
        }
    }

    func play() {
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    func pause() {
        player.pause()
        isPlaying = false
        updateNowPlaying()
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func seekToProgress(_ progress: Double) {
        seek(to: duration * progress)
    }

    func playNext() {
        guard !queue.isEmpty else { return }

        if isShuffleOn {
            queueIndex = Int.random(in: 0..<queue.count)
        } else {
            queueIndex += 1
            if queueIndex >= queue.count {
                switch repeatMode {
                case .all:
                    queueIndex = 0
                case .one:
                    queueIndex = queue.count - 1
                case .off:
                    pause()
                    return
                }
            }
        }

        playSong(queue[queueIndex])
    }

    func playPrevious() {
        guard !queue.isEmpty else { return }

        if currentTime > 3.0 {
            seek(to: 0)
        } else {
            queueIndex -= 1
            if queueIndex < 0 {
                queueIndex = repeatMode == .all ? queue.count - 1 : 0
            }
            playSong(queue[queueIndex])
        }
    }

    func toggleShuffle() {
        isShuffleOn.toggle()
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    private func handlePlaybackEnd() {
        if repeatMode == .one {
            seek(to: 0)
            play()
        } else {
            playNext()
        }
    }

    private func updateNowPlaying() {
        guard let song = currentSong else { return }

        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = song.title
        info[MPMediaItemPropertyArtist] = song.artist
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPMediaItemPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyPlaybackProgress] = playbackProgress

        if let artworkURL = URL(string: song.artworkURL), let imageData = try? Data(contentsOf: artworkURL),
           let image = UIImage(data: imageData) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    deinit {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
        NotificationCenter.default.removeObserver(self)
    }
}
