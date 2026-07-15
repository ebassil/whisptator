import SwiftUI

struct CompletionAnimationView: View {
    let opacity: Double

    @State private var scale: CGFloat = 0.5
    @State private var checkOpacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.3 * opacity))
                .frame(width: 80, height: 80)
                .scaleEffect(scale)

            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .opacity(checkOpacity * opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.2).delay(0.2)) {
                checkOpacity = 1.0
            }
        }
    }
}
