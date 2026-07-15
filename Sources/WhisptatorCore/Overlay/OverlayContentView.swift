import SwiftUI

struct OverlayContentView: View {
    let state: OverlayState
    let audioLevel: Float
    let opacity: Double

    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
            case .recording:
                RecordingAnimationView(audioLevel: audioLevel, opacity: opacity)
            case .transcribing:
                TranscribingAnimationView(opacity: opacity)
            case .completion:
                CompletionAnimationView(opacity: opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
}
