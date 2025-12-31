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
    @State private var showCodeInspection = false
    @State private var showSettings = false

    // For mic button and recording
    @State private var buttonState: FloatingButton.ButtonState = .idle
    @StateObject private var audioService = AudioRecordingService.shared
    @StateObject private var webSocketService = WebSocketService.shared
    @State private var showPermissionAlert = false
    @State private var lastRecordingInfo: String = ""
    @State private var showRecordingInfo = false
    @State private var showClarificationModal = false
    @State private var showErrorAlert = false
    @State private var currentProjectId = "default-project" // TODO: Get from actual project
    @State private var audioStreamingHandler: AudioStreamingHandler?

    var body: some View {
        mainContentWithObservers
            .sheet(isPresented: $showClarificationModal) {
                clarificationSheet
            }
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showCodeInspection) {
                CodeInspectionView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            } message: {
                Text("Spoken Reality needs microphone access to record your voice commands. Please enable it in Settings.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                errorAlertButtons
            } message: {
                errorAlertMessage
            }
            .preferredColorScheme(.dark)
    }

    private var mainContentWithObservers: some View {
        mainContent
            .onAppear {
                setupAudioStreaming()
                connectToBackend()
            }
            .onDisappear {
                webSocketService.disconnect()
            }
            .onChange(of: webSocketService.agentState) { oldState, newState in
                handleAgentStateChange(newState)
            }
            .onChange(of: webSocketService.previewURL) { oldValue, newValue in
                if let url = newValue {
                    devServerURL = url
                }
            }
            .onChange(of: webSocketService.clarificationQuestion) { oldValue, newValue in
                showClarificationModal = (newValue != nil)
            }
            .onChange(of: webSocketService.lastError) { oldValue, newValue in
                showErrorAlert = (newValue != nil)
            }
    }

    private func connectToBackend() {
        // For testing: use "test" token as per backend's mock authentication
        // TODO: Replace with real Clerk token after authentication implementation
        let testToken = "test"
        webSocketService.connect(clerkToken: testToken)

        print("🔌 Connecting to WebSocket backend...")
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            contentStack

            floatingButton

            // Recording overlay with audio level
            if audioService.recordingState == .recording {
                recordingOverlay
            }

            // Recording info overlay
            if showRecordingInfo {
                recordingInfoOverlay
            }

            // Transcription overlay
            TranscriptionOverlay(text: transcriptionText)
        }
    }

    private var contentStack: some View {
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
    }

    private var floatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingButton(
                    state: $buttonState,
                    onPressStart: {
                        handleRecordingStart()
                    },
                    onPressEnd: {
                        handleRecordingEnd()
                    }
                )
                .padding(.trailing, Spacing.lg)
                .padding(.bottom, 80) // Above tab bar
            }
        }
    }

    private var transcriptionText: String {
        webSocketService.partialTranscription.isEmpty ? webSocketService.finalTranscription : webSocketService.partialTranscription
    }

    private var clarificationSheet: some View {
        Group {
            if let question = webSocketService.clarificationQuestion {
                ClarificationModal(
                    question: question,
                    options: webSocketService.clarificationOptions,
                    onSelect: { response in
                        handleClarificationResponse(response)
                    }
                )
            }
        }
    }

    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                connectionStatusIndicator
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showCodeInspection = true }) {
                        Label("View Code", systemImage: "doc.text")
                    }
                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.accentPrimary)
                }
            }
        }
    }

    private var connectionStatusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connectionStatusColor)
                .frame(width: 8, height: 8)

            Text(connectionStatusText)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }

    private var connectionStatusColor: Color {
        switch webSocketService.connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .yellow
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }

    private var connectionStatusText: String {
        switch webSocketService.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .reconnecting:
            return "Reconnecting..."
        case .disconnected:
            return "Offline"
        case .error(let message):
            return "Error"
        }
    }

    @ViewBuilder
    private var errorAlertButtons: some View {
        if let error = webSocketService.lastError, error.recoverable {
            Button("Retry") {
                // TODO: Implement retry logic
                webSocketService.lastError = nil
            }
            Button("Cancel", role: .cancel) {
                webSocketService.lastError = nil
            }
        } else {
            Button("OK") {
                webSocketService.lastError = nil
            }
        }
    }

    private var errorAlertMessage: some View {
        Group {
            if let error = webSocketService.lastError {
                Text("\(error.message)\n\n\(error.suggestedAction ?? "")")
            }
        }
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
        DatabaseBrowserView()
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

    // MARK: - Recording Overlay

    private var recordingOverlay: some View {
        VStack {
            Spacer()
                .frame(height: 100)

            VStack(spacing: Spacing.md) {
                // Audio level visualization
                HStack(spacing: 4) {
                    ForEach(0..<20, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentPrimary)
                            .frame(width: 3, height: barHeight(for: index))
                            .animation(.easeInOut(duration: 0.1), value: audioService.audioLevel)
                    }
                }
                .frame(height: 40)

                // Recording duration
                Text(formatDuration(audioService.recordingDuration))
                    .font(.system(size: 32, weight: .medium, design: .monospaced))
                    .foregroundColor(.textPrimary)

                // Instruction text
                Text("Release to send")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(Spacing.xl)
            .background(Color.bgSecondary.opacity(0.95))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 20)

            Spacer()
        }
        .transition(.opacity)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let level = audioService.audioLevel
        let normalizedIndex = CGFloat(index) / 20.0
        let centerDistance = abs(normalizedIndex - 0.5) * 2.0

        // Create a wave-like pattern based on audio level
        let baseHeight: CGFloat = 8.0
        let maxHeight: CGFloat = 40.0
        let heightRange = maxHeight - baseHeight
        let distanceFactor = 1.0 - centerDistance
        let levelMultiplier = CGFloat(level) * distanceFactor
        let height = baseHeight + (heightRange * levelMultiplier)

        return max(baseHeight, height)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
    }

    // MARK: - Actions

    private func handleRecordingStart() {
        Task {
            do {
                // Send voice.start message to backend
                webSocketService.sendVoiceStart(projectId: currentProjectId)

                // Start recording
                try await audioService.startRecording()
                buttonState = .recording
            } catch RecordingError.permissionDenied {
                showPermissionAlert = true
                buttonState = .error
            } catch {
                print("Recording error: \(error)")
                buttonState = .error
            }
        }
    }

    private func handleRecordingEnd() {
        audioService.stopRecording()

        // Send voice.end message to backend
        webSocketService.sendVoiceEnd()

        // Button state will be updated by agent state changes
        buttonState = .processing
        showProgress = true
    }

    private func setupAudioStreaming() {
        // Set up audio streaming delegate to forward chunks to WebSocket
        // Keep strong reference to prevent deallocation
        let handler = AudioStreamingHandler(webSocketService: webSocketService)
        audioStreamingHandler = handler
        audioService.streamingDelegate = handler
    }

    private func handleAgentStateChange(_ newState: AgentState) {
        switch newState {
        case .idle:
            buttonState = .idle
            showProgress = false

        case .listening:
            // Recording state already handled by button
            break

        case .interpreting, .planning, .executing:
            buttonState = .processing
            showProgress = true

        case .presenting:
            buttonState = .success
            showProgress = false

            // Reset to idle after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                buttonState = .idle
            }

        case .clarifying:
            // Modal will be shown automatically by onChange handler
            buttonState = .idle
            showProgress = false

        case .error:
            buttonState = .error
            showProgress = false

            // Reset to idle after showing error
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                buttonState = .idle
            }
        }
    }

    private func handleClarificationResponse(_ response: String) {
        // Send response back to backend via text command
        webSocketService.sendCommand(text: response, projectId: currentProjectId)

        // Clear clarification state
        webSocketService.clarificationQuestion = nil
        webSocketService.clarificationOptions = nil
    }

    private var recordingInfoOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.success)

                Text("Recording Saved!")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text(lastRecordingInfo)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.lg)
            .background(Color.bgSecondary)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 10)
            .padding(.horizontal, Spacing.xl)

            Spacer()
                .frame(height: 100)
        }
        .transition(.opacity)
    }

}

// MARK: - Audio Streaming Handler

class AudioStreamingHandler: AudioStreamingDelegate {
    private let webSocketService: WebSocketService

    init(webSocketService: WebSocketService) {
        self.webSocketService = webSocketService
    }

    func audioRecorder(didReceiveChunk data: Data) {
        // Forward audio chunk to WebSocket
        webSocketService.sendAudioChunk(data: data)
    }
}

#Preview {
    NavigationStack {
        DevelopmentView()
    }
}

#Preview {
    DevelopmentView()
}
