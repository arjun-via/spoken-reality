import SwiftUI

enum DevelopmentTab {
    case output
    case database
}

struct DevelopmentView: View {
    @State private var selectedTab: DevelopmentTab = .output
    @State private var isLoading = false
    @State private var showProgress = false
    @State private var devServerURL: URL? = URL(string: "https://example.com")

    // For mic button
    @State private var isRecording = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar at top
                if showProgress {
                    ProgressBar()
                        .transition(.opacity)
                }

                // Main content area
                TabView(selection: $selectedTab) {
                    // Output tab (WebView)
                    outputView
                        .tag(DevelopmentTab.output)

                    // Database tab
                    databaseView
                        .tag(DevelopmentTab.database)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom tab bar
                tabBar
            }

            // Floating mic button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingButton {
                        handleMicTap()
                    }
                    .padding(.trailing, Spacing.lg)
                    .padding(.bottom, 80) // Above tab bar
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Output View (WebView)

    private var outputView: some View {
        ZStack {
            if let url = devServerURL {
                WebView(url: url, isLoading: $isLoading)
            } else {
                emptyWebViewState
            }

            if isLoading {
                loadingOverlay
            }
        }
    }

    private var emptyWebViewState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary)

            Text("Hold the mic and speak")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text("Try: 'Create a product dashboard'")
                .font(.body)
                .foregroundColor(.textSecondary)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                    .scaleEffect(1.5)

                Text("Building your app...")
                    .font(.body)
                    .foregroundColor(.textPrimary)
            }
        }
    }

    // MARK: - Database View

    private var databaseView: some View {
        VStack {
            Text("Database Browser")
                .font(.title)
                .foregroundColor(.textPrimary)

            Spacer()

            Text("Coming soon")
                .font(.body)
                .foregroundColor(.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(
                icon: "app.fill",
                title: "Output",
                tab: .output
            )

            tabBarItem(
                icon: "cylinder.fill",
                title: "Database",
                tab: .database
            )
        }
        .frame(height: 50)
        .background(Color.bgSecondary)
    }

    private func tabBarItem(icon: String, title: String, tab: DevelopmentTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))

                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selectedTab == tab ? .accentPrimary : .textSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func handleMicTap() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true

        // TODO: Start actual audio recording

        // Simulate recording and processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            stopRecording()
        }
    }

    private func stopRecording() {
        isRecording = false
        showProgress = true

        // TODO: Send audio to Grok API

        // Simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            processComplete()
        }
    }

    private func processComplete() {
        showProgress = false

        // TODO: Reload WebView with new code

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRecording = false
        }
    }
}

#Preview {
    DevelopmentView()
}
