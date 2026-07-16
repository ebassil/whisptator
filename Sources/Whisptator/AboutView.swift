import SwiftUI
import AppKit

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Whisptator")
                .font(.title)
                .fontWeight(.bold)

            Text("Real-time speech-to-text dictation and meeting transcription for macOS")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Text("Version")
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Beta")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Text("Developed by Émile Bassil")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("GitHub Repository") {
                if let url = URL(string: "https://github.com/ebassil/whisptator") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)

            Text("Credits: This app uses open source software and AI models including Whisper.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
