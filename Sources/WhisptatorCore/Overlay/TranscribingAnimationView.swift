import SwiftUI

struct TranscribingAnimationView: View {
    let opacity: Double

    @State private var rotation: Double = 0
    @State private var dotScales: [CGFloat] = [1, 1, 1]

    private let dotCount = 3

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.6 * opacity),
                            Color.purple.opacity(0.8 * opacity),
                            Color.blue.opacity(0.6 * opacity)
                        ]),
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(rotation))

            Circle()
                .fill(Color.purple.opacity(0.3 * opacity))
                .frame(width: 60, height: 60)

            HStack(spacing: 8) {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.9 * opacity))
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScales[index])
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            animateDots()
        }
    }

    private func animateDots() {
        for index in 0..<dotCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    dotScales[index] = 1.5
                }
            }
        }
    }
}
