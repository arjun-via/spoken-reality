import Foundation
import Combine

// MARK: - WebSocket Service

@MainActor
class WebSocketService: NSObject, ObservableObject {
    // Published state
    @Published var connectionState: ConnectionState = .disconnected
    @Published var agentState: AgentState = .idle
    @Published var agentMessage: String?
    @Published var agentProgress: Int?
    @Published var partialTranscription: String = ""
    @Published var finalTranscription: String = ""
    @Published var previewURL: URL?
    @Published var clarificationQuestion: String?
    @Published var clarificationOptions: [String]?
    @Published var lastError: BackendError?
    @Published var generatedFiles: [GeneratedFile] = []

    // Model for generated files
    struct GeneratedFile: Identifiable {
        let id = UUID()
        let path: String
        let content: String
        var timestamp: Date = Date()
    }

    // Connection state
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error(String)
    }

    // Private properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private let serverURL: String
    private var clerkToken: String?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var pingTimer: Timer?

    // Singleton
    static let shared = WebSocketService()

    private override init() {
        // Production URL on Railway
        self.serverURL = "wss://spoken-reality-production.up.railway.app/ws"
        super.init()

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
    }

    // MARK: - Connection Management

    func connect(clerkToken: String) {
        guard connectionState != .connected && connectionState != .connecting else {
            print("Already connected or connecting")
            return
        }

        self.clerkToken = clerkToken
        connectionState = .connecting

        guard var urlComponents = URLComponents(string: serverURL) else {
            connectionState = .error("Invalid server URL")
            return
        }

        // Add token as query parameter
        urlComponents.queryItems = [URLQueryItem(name: "token", value: clerkToken)]

        guard let url = urlComponents.url else {
            connectionState = .error("Failed to construct URL")
            return
        }

        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()

        connectionState = .connected
        reconnectAttempts = 0

        startReceiving()
        startPingTimer()

        print("✅ WebSocket connected to: \(serverURL)")
    }

    func disconnect() {
        stopPingTimer()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected

        print("🔌 WebSocket disconnected")
    }

    private func reconnect() {
        guard reconnectAttempts < maxReconnectAttempts,
              let token = clerkToken else {
            connectionState = .error("Max reconnection attempts reached")
            return
        }

        reconnectAttempts += 1
        connectionState = .reconnecting

        // Exponential backoff
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                print("🔄 Reconnecting... (attempt \(self.reconnectAttempts)/\(self.maxReconnectAttempts))")
                self.connect(clerkToken: token)
            }
        }
    }

    // MARK: - Sending Messages

    func send(_ message: WebSocketMessage) {
        guard connectionState == .connected else {
            print("❌ Cannot send message: Not connected")
            return
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            let message = URLSessionWebSocketTask.Message.data(data)

            webSocketTask?.send(message) { error in
                if let error = error {
                    print("❌ WebSocket send error: \(error)")
                    Task { @MainActor in
                        self.connectionState = .error(error.localizedDescription)
                    }
                }
            }
        } catch {
            print("❌ Failed to encode message: \(error)")
        }
    }

    // MARK: - Voice Messages

    func sendVoiceStart(projectId: String) {
        let message = VoiceStartMessage(projectId: projectId).toWebSocketMessage()
        send(message)
    }

    func sendAudioChunk(data: Data) {
        let base64Audio = data.base64EncodedString()
        let message = VoiceChunkMessage(audio: base64Audio).toWebSocketMessage()
        send(message)
    }

    func sendVoiceEnd() {
        let message = VoiceEndMessage().toWebSocketMessage()
        send(message)
    }

    // MARK: - Command Messages

    func sendCommand(text: String, projectId: String) {
        let message = CommandMessage(text: text, projectId: projectId).toWebSocketMessage()
        send(message)
    }

    // MARK: - Project Messages

    func createProject(name: String) {
        let message = ProjectCreateMessage(name: name).toWebSocketMessage()
        send(message)
    }

    func openProject(projectId: String) {
        let message = ProjectOpenMessage(projectId: projectId).toWebSocketMessage()
        send(message)
    }

    func getProjectFiles(projectId: String) {
        let message = ProjectGetFilesMessage(projectId: projectId).toWebSocketMessage()
        send(message)
    }

    // MARK: - Git Messages

    func sendGitCommit(message: String, projectId: String) {
        let gitMessage = GitCommitMessage(message: message, projectId: projectId).toWebSocketMessage()
        send(gitMessage)
    }

    // MARK: - Receiving Messages

    private func startReceiving() {
        receive()
    }

    private func receive() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                Task { @MainActor in
                    self.handleMessage(message)
                    self.receive() // Continue receiving
                }

            case .failure(let error):
                Task { @MainActor in
                    print("❌ WebSocket receive error: \(error)")
                    self.connectionState = .error(error.localizedDescription)
                    self.reconnect()
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            handleData(data)

        case .string(let string):
            if let data = string.data(using: .utf8) {
                handleData(data)
            }

        @unknown default:
            print("⚠️ Unknown message type")
        }
    }

    private func handleData(_ data: Data) {
        // Debug: print raw message
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📩 RAW MESSAGE: \(jsonString.prefix(200))...")
        }
        
        do {
            let decoder = JSONDecoder()
            let message = try decoder.decode(WebSocketMessage.self, from: data)

            print("📨 Received: \(message.type)")

            switch message.type {
            case "agent.state":
                handleAgentState(data: data)

            case "transcription.partial":
                handleTranscriptionPartial(data: data)

            case "transcription.final":
                handleTranscriptionFinal(data: data)

            case "agent.speak":
                handleAgentSpeak(data: data)

            case "agent.clarify":
                handleAgentClarify(data: data)

            case "preview.ready":
                handlePreviewReady(data: data)

            case "preview.reload":
                handlePreviewReload()

            case "code.updated":
                handleCodeUpdated(data: data)

            case "error":
                handleError(data: data)

            default:
                print("⚠️ Unknown message type: \(message.type)")
            }

        } catch {
            print("❌ Failed to decode message: \(error)")
        }
    }

    // MARK: - Message Handlers

    private func handleAgentState(data: Data) {
        do {
            struct Message: Codable {
                let payload: AgentStatePayload
            }
            let msg = try JSONDecoder().decode(Message.self, from: data)
            agentState = msg.payload.state
            agentMessage = msg.payload.message
            agentProgress = msg.payload.progress
            print("✅ Agent state updated: \(msg.payload.state) - \(msg.payload.message ?? "no message")")
        } catch {
            print("❌ Failed to decode agent state: \(error)")
            // Print raw data for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON: \(jsonString)")
            }
        }
    }

    private func handleTranscriptionPartial(data: Data) {
        do {
            struct Message: Codable {
                let payload: TranscriptionPartialPayload
            }
            let msg = try JSONDecoder().decode(Message.self, from: data)
            partialTranscription = msg.payload.text
        } catch {
            print("❌ Failed to decode transcription: \(error)")
        }
    }

    private func handleTranscriptionFinal(data: Data) {
        do {
            struct Message: Codable {
                let payload: TranscriptionFinalPayload
            }
            let msg = try JSONDecoder().decode(Message.self, from: data)
            finalTranscription = msg.payload.text
            partialTranscription = "" // Clear partial
        } catch {
            print("❌ Failed to decode transcription: \(error)")
        }
    }

    private func handleAgentSpeak(data: Data) {
        do {
            struct Message: Codable {
                let payload: AgentSpeakPayload
            }
            let msg = try JSONDecoder().decode(Message.self, from: data)
            agentMessage = msg.payload.text
            // TODO: Handle TTS audio if needed
        } catch {
            print("❌ Failed to decode agent speak: \(error)")
        }
    }

    private func handleAgentClarify(data: Data) {
        do {
            struct Message: Codable {
                let payload: AgentClarifyPayload
            }
            let msg = try JSONDecoder().decode(Message.self, from: data)
            clarificationQuestion = msg.payload.question
            clarificationOptions = msg.payload.options
        } catch {
            print("❌ Failed to decode clarification: \(error)")
        }
    }

    private func handlePreviewReady(data: Data) {
        do {
            struct Message: Codable {
                let payload: PreviewReadyPayload
            }
            let msg = try JSONDecoder().decode(Message.self, from: data)
            print("🌐 Preview URL received: \(msg.payload.url)")
            let newURL = URL(string: msg.payload.url)

            // IMPORTANT:
            // The preview URL can remain identical across builds (same sandbox/port host).
            // SwiftUI's onChange won't fire if the value is equal, so we force a change by
            // bouncing through nil when the URL hasn't changed.
            if newURL == previewURL {
                print("🌐 Preview URL unchanged — forcing a reload")
                previewURL = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.previewURL = newURL
                    print("🌐 Preview URL re-set to: \(String(describing: self.previewURL))")
                }
            } else {
                previewURL = newURL
                print("🌐 Preview URL set to: \(String(describing: previewURL))")
            }
        } catch {
            print("❌ Failed to decode preview URL: \(error)")
        }
    }

    private func handlePreviewReload() {
        // Trigger WebView reload by updating URL
        if let url = previewURL {
            previewURL = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.previewURL = url
            }
        }
    }

    private func handleCodeUpdated(data: Data) {
        do {
            struct Message: Codable {
                let payload: CodeUpdatedPayload
            }
            let msg = try JSONDecoder().decode(Message.self, from: data)

            // Store the generated files
            let newFiles = msg.payload.files.map { file in
                GeneratedFile(path: file.path, content: file.content)
            }

            // Update existing files or add new ones
            for newFile in newFiles {
                if let index = generatedFiles.firstIndex(where: { $0.path == newFile.path }) {
                    generatedFiles[index] = newFile
                } else {
                    generatedFiles.append(newFile)
                }
            }

            print("📝 Code updated: \(msg.payload.files.count) files, total: \(generatedFiles.count)")
        } catch {
            print("❌ Failed to decode code update: \(error)")
        }
    }

    private func handleError(data: Data) {
        do {
            struct Message: Codable {
                let payload: BackendError
            }
            let msg = try JSONDecoder().decode(Message.self, from: data)
            lastError = msg.payload
        } catch {
            print("❌ Failed to decode error: \(error)")
        }
    }

    // MARK: - Keep-Alive

    private func startPingTimer() {
        stopPingTimer()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.webSocketTask?.sendPing { error in
                    if let error = error {
                        print("❌ Ping failed: \(error)")
                        Task { @MainActor in
                            self.reconnect()
                        }
                    }
                }
            }
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketService: URLSessionWebSocketDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        Task { @MainActor in
            print("✅ WebSocket opened")
            connectionState = .connected
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        Task { @MainActor in
            print("🔌 WebSocket closed: \(closeCode)")
            connectionState = .disconnected
            reconnect()
        }
    }
}
