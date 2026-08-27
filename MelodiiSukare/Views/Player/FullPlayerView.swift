import SwiftUI

struct FullPlayerView: View {
    @Environment(AudioPlayerManager.self) private var audioManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let song = audioManager.currentSong {
                    AsyncImage(url: URL(string: song.artworkURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 10)

                    VStack(spacing: 4) {
                        Text(song.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { audioManager.playbackProgress },
                            set: { audioManager.seekToProgress($0) }
                        ))
                        .tint(.primary)

                        HStack {
                            Text(formatTime(audioManager.currentTime))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatTime(audioManager.duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 40) {
                        Button {
                            audioManager.toggleShuffle()
                        } label: {
                            Image(systemName: "shuffle")
                                .font(.title3)
                                .foregroundStyle(audioManager.isShuffleOn ? .primary : .secondary)
                        }

                        Button {
                            audioManager.playPrevious()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.title)
                        }

                        Button {
                            audioManager.togglePlayPause()
                        } label: {
                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.largeTitle)
                        }

                        Button {
                            audioManager.playNext()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title)
                        }

                        Button {
                            audioManager.cycleRepeatMode()
                        } label: {
                            Image(systemName: repeatModeIcon)
                                .font(.title3)
                                .foregroundStyle(audioManager.repeatMode == .off ? .secondary : .primary)
                        }
                    }
                } else {
                    ContentUnavailableView("No Song Playing", systemImage: "music.note", description: Text("Select a song to play"))
                }
            }
            .padding()
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                }
            }
        }
    }

    private var repeatModeIcon: String {
        switch audioManager.repeatMode {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
