import SwiftUI

struct OnboardingView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @Binding var isOnboardingComplete: Bool

    enum OnboardingStep {
        case welcome
        case microphone
        case firstTip
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            switch currentStep {
            case .welcome:
                welcomeScreen
            case .microphone:
                microphoneScreen
            case .firstTip:
                firstTipScreen
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Welcome Screen

    private var welcomeScreen: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Logo or icon
            Image(systemName: "wand.and.stars")
                .font(.system(size: 80))
                .foregroundColor(.accentPrimary)

            VStack(spacing: Spacing.sm) {
                Text("Spoken Reality")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("Speak it. Build it. Ship it.")
                    .font(.title3)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Button(action: {
                withAnimation {
                    currentStep = .microphone
                }
            }) {
                Text("Get Started")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(Color.accentPrimary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Microphone Permission Screen

    private var microphoneScreen: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Microphone icon
            Image(systemName: "mic.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentPrimary)

            VStack(spacing: Spacing.md) {
                Text("Spoken Reality needs")
                    .font(.title2)
                    .foregroundColor(.textPrimary)

                Text("microphone access")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("Speak your app into existence\nand watch it build live")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.sm)
            }

            Spacer()

            VStack(spacing: Spacing.md) {
                Button(action: {
                    requestMicrophonePermission()
                }) {
                    Text("Allow Microphone")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                        .background(Color.accentPrimary)
                        .cornerRadius(12)
                }

                Button(action: {
                    skipOnboarding()
                }) {
                    Text("Maybe Later")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - First Tip Screen

    private var firstTipScreen: some View {
        ZStack {
            // Background with dimmed content
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Tooltip
            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Hold mic to speak")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("Release to build")
                        .font(.body)
                        .foregroundColor(.textSecondary)

                    Divider()
                        .background(Color.bgTertiary)
                        .padding(.vertical, Spacing.xs)

                    Text("Try: \"Create a product dashboard\"")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .italic()

                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("Got it")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .background(Color.accentPrimary)
                            .cornerRadius(8)
                    }
                    .padding(.top, Spacing.md)
                }
                .padding(Spacing.lg)
                .background(Color.bgSecondary)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.5), radius: 20)
                .padding(.horizontal, Spacing.lg)

                // Floating mic button (highlighted)
                HStack {
                    Spacer()
                    ZStack {
                        // Pulsing ring animation
                        Circle()
                            .stroke(Color.accentPrimary.opacity(0.5), lineWidth: 2)
                            .frame(width: 80, height: 80)
                            .scaleEffect(1.2)

                        Circle()
                            .fill(Color.accentPrimary)
                            .frame(width: 64, height: 64)
                            .shadow(color: .black.opacity(0.3), radius: 8)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, Spacing.lg)
                }
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Actions

    private func requestMicrophonePermission() {
        // TODO: Request actual microphone permission
        // For now, just move to next step
        withAnimation {
            currentStep = .firstTip
        }
    }

    private func skipOnboarding() {
        isOnboardingComplete = true
    }

    private func completeOnboarding() {
        isOnboardingComplete = true
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
