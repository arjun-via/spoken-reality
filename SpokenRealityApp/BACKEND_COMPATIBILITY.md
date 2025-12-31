# Backend Compatibility - iOS Frontend

## Current Status: ✅ 85% Compatible

### What's Already Compatible

1. **Project Data Model** ✅
   - iOS `Project` model matches backend schema
   - Ready for API integration

2. **UI State Machine** ✅
   - FloatingButton states map to backend agent states
   - Visual feedback ready for all backend state transitions

3. **Recording Infrastructure** ✅
   - AudioRecordingService exists and working
   - Just needs format conversion

### Required Changes

## 1. Audio Format Conversion 🔴 CRITICAL

**Backend Requirement:**
- Format: PCM 16-bit
- Sample Rate: 16kHz
- Encoding: Base64
- Delivery: Streaming chunks (not complete file)

**Current iOS Implementation:**
- Format: M4A (AAC)
- Sample Rate: 44.1kHz
- Encoding: File-based
- Delivery: Complete file after recording

**Solution:**
Update `AudioRecordingService.swift` to:
```swift
// Change recording settings to PCM
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatLinearPCM),  // PCM instead of AAC
    AVSampleRateKey: 16000.0,                   // 16kHz instead of 44.1kHz
    AVNumberOfChannelsKey: 1,
    AVLinearPCMBitDepthKey: 16,                 // 16-bit
    AVLinearPCMIsFloatKey: false,
    AVLinearPCMIsBigEndianKey: false
]
```

Add streaming capability:
```swift
// Stream audio chunks every 100ms
func startStreaming(onChunk: @escaping (Data) -> Void)
```

## 2. WebSocket Client Integration 🟡 HIGH PRIORITY

**Backend WebSocket URL:**
```
wss://api.via.app/ws?token={clerk_session_token}
```

**Required iOS Implementation:**

### Add WebSocket Service
Create `WebSocketService.swift`:

```swift
import Foundation
import Starscream // or native URLSessionWebSocketTask

class WebSocketService: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published var agentState: AgentState = .idle

    private var socket: WebSocket?
    private let serverURL = "wss://api.via.app/ws"

    enum ConnectionState {
        case disconnected, connecting, connected, error
    }

    enum AgentState: String {
        case idle = "IDLE"
        case listening = "LISTENING"
        case interpreting = "INTERPRETING"
        case clarifying = "CLARIFYING"
        case planning = "PLANNING"
        case executing = "EXECUTING"
        case presenting = "PRESENTING"
        case error = "ERROR"
    }

    // Connect with Clerk token
    func connect(clerkToken: String)

    // Send messages
    func sendVoiceStart(projectId: String)
    func sendAudioChunk(data: Data)
    func sendVoiceEnd()
    func sendCommand(text: String, projectId: String)

    // Receive handlers
    func handleAgentState(state: AgentState, message: String?)
    func handleTranscription(text: String, isFinal: Bool)
    func handlePreviewReady(url: String)
    func handleError(error: BackendError)
}
```

### Message Format
All messages follow backend spec:

```swift
struct WebSocketMessage: Codable {
    let type: String
    let payload: [String: Any]
    let timestamp: Int
    let messageId: String
}

// Outgoing messages
// voice.start
{
  "type": "voice.start",
  "payload": { "projectId": "proj_123" },
  "timestamp": 1704067200000,
  "messageId": "msg_abc"
}

// voice.chunk (sent continuously)
{
  "type": "voice.chunk",
  "payload": { "audio": "base64_encoded_pcm_data" },
  "timestamp": 1704067200100,
  "messageId": "msg_def"
}

// voice.end
{
  "type": "voice.end",
  "payload": {},
  "timestamp": 1704067202000,
  "messageId": "msg_ghi"
}
```

## 3. Agent State Mapping 🟢 EASY

Map FloatingButton states to backend agent states:

| FloatingButton.ButtonState | Backend AgentState | UI Behavior |
|----------------------------|-------------------|-------------|
| idle | IDLE | Default coral button |
| recording | LISTENING | Pulsing ring + waveform |
| processing | INTERPRETING → PLANNING → EXECUTING | Spinner |
| success | PRESENTING | Green checkmark |
| error | ERROR | Red triangle |

**New states to add:**
- CLARIFYING: Show question modal
- PLANNING: Show "Thinking..." status

## 4. Preview URL Handling 🟢 EASY

**Backend sends:**
```json
{
  "type": "preview.ready",
  "payload": {
    "url": "https://abc123.e2b.dev"
  }
}
```

**iOS action:**
Update WebView URL in `DevelopmentView`:
```swift
.onReceive(webSocketService.$previewURL) { url in
    self.devServerURL = url
}
```

## 5. Real-time Transcription Display 🟢 EASY

**Backend streams:**
```json
{
  "type": "transcription.partial",
  "payload": { "text": "Add a search bar to the" }
}
```

**iOS shows:**
Display live transcript in recording overlay below waveform

## 6. Error Handling 🟡 MEDIUM

**Backend error format:**
```json
{
  "type": "error",
  "payload": {
    "code": "SANDBOX_FAILED",
    "message": "Preview isn't loading",
    "recoverable": true,
    "suggestedAction": "Retrying..."
  }
}
```

**iOS handling:**
```swift
func handleError(error: BackendError) {
    if error.recoverable {
        // Show retry option
        buttonState = .error
        showAlert(message: error.message, action: error.suggestedAction)
    } else {
        // Show permanent error
        showAlert(message: error.message)
    }
}
```

## Implementation Priority

### Phase 1: Core Communication ⏰ Week 1
- [ ] Add WebSocket client (Starscream or native)
- [ ] Implement message formatting
- [ ] Add Clerk authentication
- [ ] Test connection flow

### Phase 2: Audio Streaming ⏰ Week 2
- [ ] Convert audio format to PCM 16kHz
- [ ] Implement chunk streaming (100ms intervals)
- [ ] Base64 encode audio chunks
- [ ] Test latency

### Phase 3: State Synchronization ⏰ Week 3
- [ ] Map all backend agent states to UI
- [ ] Handle preview URL updates
- [ ] Implement real-time transcription display
- [ ] Add clarification modal

### Phase 4: Error Handling ⏰ Week 4
- [ ] Implement error recovery flow
- [ ] Add retry logic
- [ ] Connection loss handling
- [ ] Graceful degradation

## Testing Checklist

- [ ] WebSocket connects with Clerk token
- [ ] Audio chunks stream in real-time
- [ ] Agent states update UI correctly
- [ ] Preview URL updates WebView
- [ ] Transcription shows live
- [ ] Errors display with recovery options
- [ ] Reconnection works after disconnect
- [ ] Latency under 3 seconds end-to-end

## Dependencies Needed

Add to `Package.swift` or use SPM:
```swift
.package(url: "https://github.com/daltoniam/Starscream", from: "4.0.0")
.package(url: "https://github.com/clerk/clerk-ios", from: "1.0.0")
```

## Environment Variables

Add to Xcode scheme or Config.plist:
```
BACKEND_WS_URL = wss://api.via.app/ws
CLERK_PUBLISHABLE_KEY = pk_test_...
```

---

**Status:** Ready for implementation
**Estimated Time:** 3-4 weeks full compatibility
**Critical Path:** Audio format + WebSocket (Week 1-2)

