import SwiftUI

// MARK: - Transcription Overlay

struct TranscriptionOverlay: View {
    let text: String

    var body: some View {
        VStack {
            Spacer()
                .frame(height: 150)

            if !text.isEmpty {
                VStack(spacing: Spacing.sm) {
                    // Title
                    Text("You said:")
                        .font(.caption)
                        .foregroundColor(.textTertiary)

                    // Transcription text
                    Text(text)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                .padding(Spacing.lg)
                .background(Color.bgSecondary.opacity(0.95))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 10)
                .padding(.horizontal, Spacing.xl)
            }

            Spacer()
        }
        .transition(.opacity)
    }
}

#Preview {
    ZStack {
        Color.bgPrimary.ignoresSafeArea()
        TranscriptionOverlay(text: "Add a search bar to the products table")
    }
}
