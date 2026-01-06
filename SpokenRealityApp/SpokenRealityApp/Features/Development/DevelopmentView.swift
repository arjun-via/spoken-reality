import SwiftUI

enum DevelopmentTab {
    case output  // Shows the running app (WebView)
    case chat    // Shows conversation history (prompts & responses)
}

enum VerticalScreen {
    case code    // Swipe UP to show
    case main    // Center (Output/Chat)
    case git     // Swipe DOWN to show
}

// Model for conversation messages
struct ConversationMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let timestamp: Date
}

struct DevelopmentView: View {
    @State private var selectedTab: DevelopmentTab = .chat
    @State private var isLoading = false
    @State private var showProgress = false
    @State private var webViewLoadError: String? = nil
    @State private var webViewReloadToken: UUID = UUID()
    @State private var showSettings = false

    // Vertical navigation
    @State private var verticalScreen: VerticalScreen = .main
    @State private var verticalOffset: CGFloat = 0
    @State private var isDraggingVertically = false

    // Conversation history
    @State private var conversationMessages: [ConversationMessage] = []

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
        GeometryReader { geometry in
            ZStack {
                // Vertical stack of screens
                VStack(spacing: 0) {
                    // Code screen (above main) - shows when swiping UP
                    CodeInspectionView()
                        .frame(height: geometry.size.height)

                    // Main screen (Output/Chat)
                    mainContentWithObservers
                        .frame(height: geometry.size.height)

                    // Git Status screen (below main) - shows when swiping DOWN
                    GitStatusView()
                        .frame(height: geometry.size.height)
                }
                .offset(y: verticalNavigationOffset(for: geometry.size.height))
                .contentShape(Rectangle())
                .simultaneousGesture(verticalDragGesture(screenHeight: geometry.size.height))
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: verticalScreen)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: verticalOffset)

                // Swipe indicators
                if verticalScreen == .main && !isDraggingVertically {
                    swipeIndicators
                }
            }
        }
        .sheet(isPresented: $showClarificationModal) {
            clarificationSheet
        }
        .toolbar {
            toolbarContent
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

    // MARK: - Vertical Navigation

    private func verticalNavigationOffset(for screenHeight: CGFloat) -> CGFloat {
        let baseOffset: CGFloat
        switch verticalScreen {
        case .code:
            baseOffset = 0  // Show code (top screen)
        case .main:
            baseOffset = -screenHeight  // Show main (middle screen)
        case .git:
            baseOffset = -screenHeight * 2  // Show git (bottom screen)
        }
        return baseOffset + verticalOffset
    }

    private func verticalDragGesture(screenHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                let horizontalAmount = abs(value.translation.width)
                let verticalAmount = abs(value.translation.height)

                // Only handle if primarily vertical swipe
                guard verticalAmount > horizontalAmount else {
                    return
                }

                isDraggingVertically = true
                let translation = value.translation.height

                // Apply resistance at edges
                switch verticalScreen {
                case .code:
                    if translation > 0 {
                        verticalOffset = translation * 0.6
                    } else {
                        verticalOffset = translation * 0.2
                    }
                case .main:
                    verticalOffset = translation * 0.6
                case .git:
                    if translation < 0 {
                        verticalOffset = translation * 0.6
                    } else {
                        verticalOffset = translation * 0.2
                    }
                }
            }
            .onEnded { value in
                let horizontalAmount = abs(value.translation.width)
                let verticalAmount = abs(value.translation.height)

                guard verticalAmount > horizontalAmount || isDraggingVertically else {
                    isDraggingVertically = false
                    verticalOffset = 0
                    return
                }

                isDraggingVertically = false
                let threshold: CGFloat = screenHeight * 0.1
                let velocity = value.predictedEndTranslation.height - value.translation.height

                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                    if value.translation.height < -threshold || velocity < -500 {
                        // Swiped UP
                        switch verticalScreen {
                        case .code: break
                        case .main: verticalScreen = .code
                        case .git: verticalScreen = .main
                        }
                    } else if value.translation.height > threshold || velocity > 500 {
                        // Swiped DOWN
                        switch verticalScreen {
                        case .code: verticalScreen = .main
                        case .main: verticalScreen = .git
                        case .git: break
                        }
                    }
                    verticalOffset = 0
                }
            }
    }

    private var swipeIndicators: some View {
        VStack {
            // Swipe up indicator
            swipeIndicator(direction: .up, label: "Code")
                .padding(.top, 60)

            Spacer()

            // Swipe down indicator
            swipeIndicator(direction: .down, label: "Git")
                .padding(.bottom, 100)
        }
        .allowsHitTesting(false)
    }

    private func swipeIndicator(direction: SwipeDirection, label: String) -> some View {
        VStack(spacing: 4) {
            if direction == .down {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }

            Image(systemName: direction == .up ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textTertiary)

            if direction == .up {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color.bgSecondary.opacity(0.8))
        .cornerRadius(12)
        .opacity(0.6)
    }

    private enum SwipeDirection {
        case up, down
    }

    private var mainContentWithObservers: some View {
        mainContent
            .onAppear {
                setupAudioStreaming()
                connectToBackend()

                // If we already have a preview URL from an earlier session,
                // show it immediately (onChange won't fire for an initial value).
                if let existingPreview = webSocketService.previewURL {
                    print("📱 Using existing preview URL on appear: \(existingPreview)")
                    webViewLoadError = nil
                    webViewReloadToken = UUID()
                }
            }
            // NOTE: Do NOT disconnect on disappear - the view can disappear temporarily
            // (e.g., when sheets appear, tabs switch, or app goes to background)
            // and we need to keep the connection alive during AI processing.
            // The WebSocket will auto-reconnect if needed.
            .onChange(of: webSocketService.agentState) { oldState, newState in
                handleAgentStateChange(newState)
            }
            .onChange(of: webSocketService.previewURL) { oldValue, newValue in
                print("📱 Preview URL changed: \(String(describing: oldValue)) -> \(String(describing: newValue))")
                if let url = newValue {
                    print("📱 Preview ready: \(url)")
                    webViewLoadError = nil
                    webViewReloadToken = UUID() // force reload even if URL stays the same
                    // Auto-switch to output tab when preview is ready
                    withAnimation {
                        selectedTab = .output
                    }
                }
            }
            .onChange(of: webSocketService.clarificationQuestion) { oldValue, newValue in
                showClarificationModal = (newValue != nil)
            }
            .onChange(of: webSocketService.lastError) { oldValue, newValue in
                showErrorAlert = (newValue != nil)
            }
            .onChange(of: webSocketService.finalTranscription) { oldValue, newValue in
                // Add user message to conversation when transcription is finalized
                if !newValue.isEmpty && newValue != oldValue {
                    let userMessage = ConversationMessage(isUser: true, text: newValue, timestamp: Date())
                    conversationMessages.append(userMessage)
                }
            }
            .onChange(of: webSocketService.agentMessage) { oldValue, newValue in
                // Add agent response to conversation when in presenting state
                if webSocketService.agentState == .presenting,
                   let message = newValue,
                   !message.isEmpty {
                    let agentMessage = ConversationMessage(isUser: false, text: message, timestamp: Date())
                    conversationMessages.append(agentMessage)
                }
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
        }
    }

    private var contentStack: some View {
        VStack(spacing: 0) {
            // Status banner at top - shows real-time agent status
            if showProgress || (webSocketService.agentState != .idle && webSocketService.agentState != .presenting) {
                agentStatusBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Main content area (Chat LEFT, Output RIGHT)
            TabView(selection: $selectedTab) {
                // Chat tab (LEFT) - shows conversation history
                chatView
                    .tag(DevelopmentTab.chat)

                // Output tab (RIGHT) - shows the running app
                outputView
                    .tag(DevelopmentTab.output)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Bottom tab bar
            tabBar
        }
    }
    
    private var agentStatusBanner: some View {
        HStack(spacing: Spacing.sm) {
            // Status indicator
            statusIndicatorIcon
            
            VStack(alignment: .leading, spacing: 2) {
                Text(agentStateTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                if let message = webSocketService.agentMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Progress indicator
            if webSocketService.agentState == .executing || webSocketService.agentState == .planning {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.bgSecondary)
        .animation(.easeInOut(duration: 0.2), value: webSocketService.agentMessage)
    }
    
    @ViewBuilder
    private var statusIndicatorIcon: some View {
        switch webSocketService.agentState {
        case .idle:
            Image(systemName: "circle")
                .foregroundColor(.textSecondary)
        case .listening:
            Image(systemName: "waveform")
                .foregroundColor(.accentPrimary)
                .symbolEffect(.variableColor.iterative)
        case .interpreting:
            Image(systemName: "text.bubble")
                .foregroundColor(.accentPrimary)
        case .planning:
            Image(systemName: "brain")
                .foregroundColor(.accentPrimary)
        case .executing:
            Image(systemName: "hammer.fill")
                .foregroundColor(.accentPrimary)
        case .presenting:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.success)
        case .clarifying:
            Image(systemName: "questionmark.circle")
                .foregroundColor(.warning)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.error)
        }
    }
    
    private var agentStateTitle: String {
        switch webSocketService.agentState {
        case .idle:
            return "Ready"
        case .listening:
            return "Listening..."
        case .interpreting:
            return "Understanding..."
        case .planning:
            return "Planning..."
        case .executing:
            return "Building..."
        case .presenting:
            return "Done!"
        case .clarifying:
            return "Question"
        case .error:
            return "Error"
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
        // Hide transcription when presenting (app is ready)
        if webSocketService.agentState == .presenting || webSocketService.agentState == .idle {
            return ""
        }
        return webSocketService.partialTranscription.isEmpty ? webSocketService.finalTranscription : webSocketService.partialTranscription
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
                HStack(spacing: 12) {
                    connectionStatusIndicator

                    // Navigation to Git (down)
                    Button(action: {
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                            verticalScreen = .git
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.down")
                            Text("Git")
                        }
                        .font(.subheadline)
                        .foregroundColor(.green)
                    }

                    // Navigation to Code (up)
                    Button(action: {
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                            verticalScreen = .code
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.up")
                            Text("Code")
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentPrimary)
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
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
            if let url = webSocketService.previewURL {
                WebView(url: url, reloadToken: webViewReloadToken, isLoading: $isLoading, loadError: $webViewLoadError)
                    .edgesIgnoringSafeArea(.all) // Full screen WebView
                
                // Refresh button in top-right corner
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            webViewLoadError = nil
                            webViewReloadToken = UUID()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.top, 50)
                        .padding(.trailing, Spacing.md)
                    }
                    Spacer()
                }

                // If the preview fails to load, show a clear error overlay (instead of a blank screen)
                if let error = webViewLoadError {
                    previewErrorOverlay(error: error, url: url)
                        .transition(.opacity)
                }
            } else {
                emptyWebViewState
            }

            // Show loading overlay while the WebView is loading (even after the agent is done)
            if isLoading {
                webViewLoadingOverlay
            }
        }
    }

    private func previewErrorOverlay(error: String, url: URL) -> some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.warning)

                Text("Preview failed to load")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text(error)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                Text(url.absoluteString)
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                HStack(spacing: Spacing.sm) {
                    Button("Reload") {
                        webViewLoadError = nil
                        webViewReloadToken = UUID()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Go to Chat") {
                        withAnimation {
                            selectedTab = .chat
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(Spacing.lg)
            .background(Color.bgSecondary.opacity(0.95))
            .cornerRadius(16)
            .padding(.horizontal, Spacing.lg)
        }
    }

    private var webViewLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                    .scaleEffect(1.2)

                Text(webSocketService.agentState == .executing ? (webSocketService.agentMessage ?? "Building your app...") : "Loading preview…")
                    .font(.body)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            .padding(Spacing.xl)
            .background(Color.bgSecondary.opacity(0.95))
            .cornerRadius(16)
        }
    }

    private var emptyWebViewState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "play.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary)

            Text("No app running")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text("Use the mic to build something!")
                .font(.body)
                .foregroundColor(.textSecondary)
            
            if !conversationMessages.isEmpty {
                Text("Your last build may have expired.\nTry building again.")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.sm)
            }
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                    .scaleEffect(1.5)

                // Show real-time status from backend
                Text(webSocketService.agentMessage ?? "Building your app...")
                    .font(.body)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                    .animation(.easeInOut(duration: 0.2), value: webSocketService.agentMessage)
                
                // Show progress if available
                if let progress = webSocketService.agentProgress {
                    ProgressView(value: Double(progress), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentPrimary))
                        .frame(width: 200)
                }
            }
            .padding(Spacing.xl)
            .background(Color.bgSecondary.opacity(0.95))
            .cornerRadius(16)
        }
    }

    // MARK: - Chat View (Conversation History)

    private var chatView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    if conversationMessages.isEmpty {
                        // Empty state
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 48))
                                .foregroundColor(.textSecondary)
                            
                            Text("Start a conversation")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            Text("Hold the mic and describe what you want to build")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(conversationMessages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .onChange(of: conversationMessages.count) { _, _ in
                // Auto-scroll to latest message
                if let lastMessage = conversationMessages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.bgPrimary)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            // Chat on LEFT
            tabBarItem(
                icon: "bubble.left.and.bubble.right.fill",
                title: "Chat",
                tab: .chat
            )

            // Output on RIGHT
            tabBarItem(
                icon: "play.rectangle.fill",
                title: "Output",
                tab: .output
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

// MARK: - Chat Bubble Component

struct ChatBubble: View {
    let message: ConversationMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Header
                HStack(spacing: 6) {
                    if !message.isUser {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.accentPrimary)
                    }
                    
                    Text(message.isUser ? "You" : "Via")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(message.isUser ? .textSecondary : .accentPrimary)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
                
                // Message content
                Text(message.text)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(message.isUser ? .trailing : .leading)
            }
            .padding(Spacing.md)
            .background(message.isUser ? Color.accentPrimary.opacity(0.2) : Color.bgSecondary)
            .cornerRadius(16)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
