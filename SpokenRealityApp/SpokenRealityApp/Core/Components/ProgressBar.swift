import SwiftUI

struct ProgressBar: View {
    @State private var progress: CGFloat = 0
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.bgSecondary)
                    .frame(height: 2)

                // Progress
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.accentPrimary, .accentHover],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 2)
                    .animation(.linear(duration: 0.3), value: progress)
            }
        }
        .frame(height: 2)
    }

    func start() {
        isAnimating = true
        animateProgress()
    }

    func complete() {
        withAnimation(.easeOut(duration: 0.2)) {
            progress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            reset()
        }
    }

    func reset() {
        progress = 0
        isAnimating = false
    }

    private func animateProgress() {
        guard isAnimating else { return }
        withAnimation(.linear(duration: 0.5)) {
            progress = min(progress + 0.1, 0.9)
        }
        if progress < 0.9 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateProgress()
            }
        }
    }
}

#Preview {
    VStack {
        ProgressBar()
        Spacer()
    }
    .background(Color.bgPrimary)
}
