import SwiftUI

struct FloatingButton: View {
    enum ButtonState {
        case idle
        case recording
        case processing
        case error
        case success
    }

    @Binding var state: ButtonState
    @State private var scale: CGFloat = 1.0
    @State private var isPressed: Bool = false

    let onPressStart: () -> Void
    let onPressEnd: () -> Void

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundColor)
                .frame(width: 64, height: 64)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

            // Pulsing ring (recording state)
            if state == .recording {
                Circle()
                    .stroke(Color.accentPrimary.opacity(0.5), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(scale)
                    .opacity(2 - scale)
            }

            // Icon
            icon
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .animation(.spring(response: 0.3), value: state)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        handlePressStart()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    handlePressEnd()
                }
        )
        .onChange(of: state) { oldValue, newValue in
            handleStateChange(newValue)
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .idle: return .accentPrimary
        case .recording: return .accentPrimary
        case .processing: return .accentPrimary
        case .error: return .error
        case .success: return .success
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .idle, .recording:
            Image(systemName: "mic.fill")
        case .processing:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
        case .success:
            Image(systemName: "checkmark")
        }
    }

    private func handlePressStart() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        onPressStart()
    }

    private func handlePressEnd() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        onPressEnd()
    }

    private func handleStateChange(_ newState: ButtonState) {
        switch newState {
        case .recording:
            startPulseAnimation()
        case .success, .error:
            // Auto-reset to idle after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                state = .idle
            }
        default:
            scale = 1.0
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            scale = 1.3
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var buttonState: FloatingButton.ButtonState = .idle

        var body: some View {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                FloatingButton(
                    state: $buttonState,
                    onPressStart: {
                        print("Press started")
                        buttonState = .recording
                    },
                    onPressEnd: {
                        print("Press ended")
                        buttonState = .processing
                    }
                )
            }
        }
    }

    return PreviewWrapper()
}
