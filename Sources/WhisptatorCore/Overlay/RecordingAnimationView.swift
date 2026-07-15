import SwiftUI

struct RecordingAnimationView: View {
    let audioLevel: Float
    let opacity: Double

    @State private var isPulsing = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.15 * opacity))
                .frame(width: 120, height: 120)
                .scaleEffect(pulseScale)

            Circle()
                .fill(Color.red.opacity(0.3 * opacity))
                .frame(width: 90, height: 90)
                .scaleEffect(1.0 + CGFloat(audioLevel) * 0.3)

            Circle()
                .fill(Color.red.opacity(0.6 * opacity))
                .frame(width: 60, height: 60)

            Image(systemName: "mic.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
                pulseScale = 1.15
            }
        }
        .onChange(of: audioLevel) { _, _ in
            withAnimation(.easeOut(duration: 0.05)) {
                pulseScale = 1.0 + CGFloat(audioLevel) * 0.2
            }
        }
    }
}
