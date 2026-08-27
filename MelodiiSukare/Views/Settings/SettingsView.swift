import SwiftUI

struct SettingsView: View {
    @AppStorage("youtube_api_key") private var apiKey = ""
    @AppStorage("downloads_wifi_only") private var downloadsWifiOnly = false
    @AppStorage("stream_quality") private var streamQuality = "high"

    var body: some View {
        List {
            Section("YouTube API") {
                SecureField("API Key", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Link(destination: URL(string: "https://console.cloud.google.com/apis/credentials")!) {
                    HStack {
                        Text("Get API Key")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Instructions:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("1. Go to Google Cloud Console")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("2. Enable YouTube Data API v3")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("3. Create an API key")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("4. Paste the key above")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Playback") {
                Toggle("Downloads on WiFi Only", isOn: $downloadsWifiOnly)

                Picker("Stream Quality", selection: $streamQuality) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Link(destination: URL(string: "https://github.com")!) {
                    HStack {
                        Text("Source Code")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
