# Backend Requirements for iOS Frontend Integration

## Overview

This document outlines the backend requirements needed to support the iOS frontend. The frontend has been fully implemented and is ready to integrate with the backend WebSocket API.

## WebSocket Connection

### Endpoint
```
wss://api.via.app/ws
```

**Current Status:** URL is hardcoded in `WebSocketService.swift:43`.
**Action Needed:**
- Deploy backend to this endpoint OR
- Update the URL in WebSocketService.swift to point to actual backend location
- Consider making this configurable via environment or settings

### Authentication
- **Method:** Query parameter authentication
- **Parameter:** `token` (Clerk session token)
- **Example:** `wss://api.via.app/ws?token=<clerk-token>`

**Action Needed:**
- Ensure backend validates Clerk tokens on WebSocket connection
- Reject invalid or expired tokens with appropriate close code

## Audio Format Requirements

The iOS app streams audio in the following format:

- **Codec:** Linear PCM (uncompressed)
- **Sample Rate:** 16kHz
- **Bit Depth:** 16-bit
- **Channels:** Mono (1 channel)
- **Container:** .caf (Core Audio Format)
- **Encoding:** Base64 (when sent over WebSocket)
- **Chunk Size:** ~16KB per chunk
- **Streaming Interval:** 100ms (10 chunks per second)

**Backend Must:**
- Accept Base64-encoded PCM audio in `voice.chunk` messages
- Decode Base64 to raw PCM data
- Feed decoded PCM directly to OpenAI Whisper API
- Handle streaming chunks (not complete files)

## WebSocket Message Protocol

All messages follow this structure:
```json
{
  "type": "string",
  "payload": {},
  "timestamp": 1234567890,
  "messageId": "uuid"
}
```

### Client → Server Messages (Outgoing)

#### 1. voice.start
Sent when user starts recording.

```json
{
  "type": "voice.start",
  "payload": {
    "projectId": "string"
  },
  "timestamp": 1234567890,
  "messageId": "uuid"
}
```

**Backend Action:**
- Initialize transcription session for this project
- Start buffering audio chunks
- Send confirmation or error

#### 2. voice.chunk
Sent every 100ms during recording with audio data.

```json
{
  "type": "voice.chunk",
  "payload": {
    "audio": "base64-encoded-pcm-data"
  },
  "timestamp": 1234567890,
  "messageId": "uuid"
}
```

**Backend Action:**
- Decode Base64 audio
- Send to OpenAI Whisper API
- Return transcription when complete

#### 3. voice.end
Sent when user releases record button.

```json
{
  "type": "voice.end",
  "payload": {},
  "timestamp": 1234567890,
  "messageId": "uuid"
}
```

**Backend Action:**
- Finalize transcription
- Send final transcription
- Begin AI processing of command

#### 4. command
Sent for text-based commands or clarification responses.

```json
{
  "type": "command",
  "payload": {
    "text": "string",
    "projectId": "string"
  },
  "timestamp": 1234567890,
  "messageId": "uuid"
}
```

**Backend Action:**
- Process text command with Claude
- Update agent state accordingly

#### 5. project.create
```json
{
  "type": "project.create",
  "payload": {
    "name": "string"
  },
  "timestamp": 1234567890,
  "messageId": "uuid"
}
```

#### 6. project.open
```json
{
  "type": "project.open",
  "payload": {
    "projectId": "string"
  },
  "timestamp": 1234567890,
  "messageId": "uuid"
}
```

#### 7. project.getFiles
```json
{
  "type": "project.getFiles",
  "payload": {
    "projectId": "string"
  },
  "timestamp": 1234567890,
  "messageId": "uuid"
}
```

### Server → Client Messages (Incoming)

#### 1. agent.state
Sent whenever agent state changes.

```json
{
  "type": "agent.state",
  "payload": {
    "state": "IDLE" | "LISTENING" | "INTERPRETING" | "CLARIFYING" | "PLANNING" | "EXECUTING" | "PRESENTING" | "ERROR",
    "message": "Optional status message",
    "progress": 0-100
  }
}
```

**Frontend Behavior:**
- IDLE → Coral button, ready state
- LISTENING → Pulsing ring, recording indicator
- INTERPRETING/PLANNING/EXECUTING → Spinner, "Building your app..."
- PRESENTING → Green checkmark, success animation
- CLARIFYING → Shows clarification modal
- ERROR → Red error indicator

#### 2. transcription.partial
Sent during recording with live transcription.

```json
{
  "type": "transcription.partial",
  "payload": {
    "text": "This is what the user is saying..."
  }
}
```

**Frontend Behavior:**
- Displays live transcription overlay
- Updates in real-time as user speaks

#### 3. transcription.final
Sent when recording ends with final transcription.

```json
{
  "type": "transcription.final",
  "payload": {
    "text": "Create a product dashboard with search"
  }
}
```

**Frontend Behavior:**
- Clears partial transcription
- Shows final transcription briefly
- Begins processing state

#### 4. agent.speak
Sent when agent wants to communicate with user (optional for voice).

```json
{
  "type": "agent.speak",
  "payload": {
    "text": "I've created your dashboard",
    "audio": "optional-base64-tts-audio"
  }
}
```

**Frontend Behavior:**
- Displays text message
- Optionally plays audio (TTS not implemented yet)

#### 5. agent.clarify
Sent when agent needs clarification from user.

```json
{
  "type": "agent.clarify",
  "payload": {
    "question": "What database should I use?",
    "options": ["SQLite", "PostgreSQL", "MongoDB"]
  }
}
```

**Frontend Behavior:**
- Shows modal with question and buttons
- User can select option or type custom response
- Sends response via `command` message
- Frontend automatically clears clarification state after sending

**Backend Must:**
- Pause execution and wait for response
- Resume when command message received
- Clear clarification state after processing response

#### 6. preview.ready
Sent when E2B sandbox is ready with preview URL.

```json
{
  "type": "preview.ready",
  "payload": {
    "url": "https://sandbox.e2b.dev/..."
  }
}
```

**Frontend Behavior:**
- Automatically loads URL in WebView
- Switches to Output tab if not already there

**Backend Must:**
- Send valid, publicly accessible URL
- Ensure sandbox is running before sending
- URL must remain valid for session duration

#### 7. preview.reload
Sent when code changes and preview needs refresh.

```json
{
  "type": "preview.reload",
  "payload": {}
}
```

**Frontend Behavior:**
- Reloads WebView
- Brief animation during reload

#### 8. code.updated
Sent when code files change (for code inspector).

```json
{
  "type": "code.updated",
  "payload": {
    "files": [
      {
        "path": "src/App.tsx",
        "content": "import React..."
      }
    ]
  }
}
```

**Frontend Behavior:**
- Updates code inspection view
- Shows file tree with changes

**Action Needed:**
- Implement code inspection view in frontend (currently basic)
- Backend should send complete file contents

#### 9. error
Sent when an error occurs.

```json
{
  "type": "error",
  "payload": {
    "code": "TRANSCRIPTION_FAILED",
    "message": "Failed to transcribe audio",
    "recoverable": true,
    "suggestedAction": "Please try recording again"
  }
}
```

**Frontend Behavior:**
- Shows error alert dialog
- Displays message and suggested action
- If recoverable, shows Retry button
- If not recoverable, shows OK button only

**Error Codes to Implement:**
- `TRANSCRIPTION_FAILED` - OpenAI Whisper API error
- `CLAUDE_ERROR` - Claude API error
- `SANDBOX_ERROR` - E2B sandbox error
- `INVALID_COMMAND` - User command not understood
- `PROJECT_NOT_FOUND` - Invalid project ID
- `RATE_LIMIT` - API rate limit exceeded

## Connection Management

### Reconnection Logic

The frontend implements automatic reconnection:
- **Max Attempts:** 5
- **Backoff:** Exponential (2^n seconds, max 30s)
- **Keep-Alive:** Ping every 30 seconds

**Backend Must:**
- Respond to WebSocket pings with pongs
- Support reconnection with same token
- Restore session state on reconnection if possible

### Connection States

Frontend tracks these states:
- `disconnected` - No connection
- `connecting` - Attempting to connect
- `connected` - Active connection
- `reconnecting` - Attempting to reconnect
- `error(String)` - Connection error with message

## Project Management

### Project ID
- The frontend currently uses a hardcoded `"default-project"` ID
- **Action Needed:** Implement proper project creation/selection flow
- Projects should be tied to Clerk user ID

### Project Context
When user opens a project:
1. Frontend sends `project.open` message
2. Backend should load project context into Claude
3. All subsequent commands apply to that project
4. Preview URL should point to that project's sandbox

## Clerk Authentication Integration

### Frontend TODO:
- ✅ WebSocket integration complete
- ✅ Message protocol implemented
- ❌ Clerk SDK integration pending
- ❌ Token retrieval not implemented

### Backend Requirements:
- Accept Clerk session tokens
- Validate tokens on every WebSocket connection
- Map Clerk user ID to internal user records
- Reject invalid/expired tokens with WebSocket close code

**Implementation Steps:**
1. Frontend: Install Clerk iOS SDK
2. Frontend: Get session token after user signs in
3. Frontend: Pass token to WebSocketService.connect()
4. Backend: Validate token with Clerk API
5. Backend: Associate WebSocket connection with user

## Environment Configuration

### Recommended Environment Variables

```bash
# WebSocket
WEBSOCKET_URL=wss://api.via.app/ws
WEBSOCKET_PORT=8080

# Clerk
CLERK_PUBLISHABLE_KEY=pk_...
CLERK_SECRET_KEY=sk_...

# OpenAI (Whisper)
GROK_API_KEY=...
GROK_API_URL=https://api.x.ai/v1

# Claude
ANTHROPIC_API_KEY=...
CLAUDE_MODEL=claude-sonnet-4.5-20250929

# E2B
E2B_API_KEY=...
E2B_TEMPLATE=nextjs-developer

# Database (for project storage)
DATABASE_URL=postgresql://...
```

## Testing Checklist

### Connection Testing
- [ ] WebSocket connects successfully
- [ ] Authentication with valid Clerk token works
- [ ] Authentication with invalid token is rejected
- [ ] Reconnection works after disconnect
- [ ] Keep-alive pings keep connection alive

### Audio Streaming Testing
- [x] voice.start message received
- [x] Audio chunks decoded correctly
- [x] PCM data fed to Whisper successfully
- [ ] Partial transcriptions sent back
- [x] Final transcription sent on voice.end
- [ ] Long recordings handled (>1 minute)

### Agent State Testing
- [ ] State transitions work correctly
- [ ] Progress updates displayed properly
- [ ] Error state triggers error alert
- [ ] Clarifying state shows modal

### Command Processing Testing
- [ ] Simple commands processed ("create a form")
- [ ] Complex commands processed ("add authentication with OAuth")
- [ ] Invalid commands trigger appropriate errors
- [ ] Clarification flow works end-to-end

### Preview Testing
- [ ] Preview URL loads in WebView
- [ ] Reload works correctly
- [ ] URL remains accessible during session
- [ ] Multiple preview updates work

### Error Handling Testing
- [ ] Recoverable errors show retry button
- [ ] Non-recoverable errors show OK button only
- [ ] Suggested actions displayed correctly
- [ ] Errors clear properly after dismissal

## Performance Considerations

### Audio Streaming
- Chunks arrive every 100ms (10/sec)
- Each chunk is ~16KB
- ~160KB/sec total bandwidth during recording
- Average recording: 5-10 seconds = 800KB-1.6MB total

**Backend Should:**
- Buffer chunks efficiently
- Collect all audio before transcription (Whisper batch mode)
- Send to Whisper when recording ends
- Send final transcription immediately

### WebSocket Optimization
- Use binary frames for large payloads if needed
- Compress messages if supported
- Keep message sizes reasonable (<100KB typically)
- Batch code updates if many files change

## Security Considerations

1. **Token Validation:** Always validate Clerk tokens
2. **Rate Limiting:** Implement per-user rate limits
3. **Sandbox Isolation:** Ensure E2B sandboxes are isolated
4. **Input Validation:** Validate all client messages
5. **XSS Prevention:** Sanitize any user content before sending
6. **Project Access:** Verify user owns project before operations

## Frontend Implementation Status

### ✅ Completed
- Audio recording with PCM 16kHz format
- Audio chunk streaming every 100ms
- WebSocket client with reconnection
- All message types implemented
- Agent state handling
- Transcription display
- Clarification modal
- Preview WebView integration
- Error handling and alerts
- UI for all states

### ❌ Pending
- Clerk authentication integration
- Actual project management (currently hardcoded "default-project")
- Code inspection view improvements
- Voice playback for agent.speak audio
- Proper onboarding flow with Clerk signup

## Next Steps

1. **Immediate:**
   - ✅ Deploy backend to Railway (spoken-reality-production-9cd5.up.railway.app)
   - ✅ Implement audio chunk handling and Whisper integration
   - ✅ Test end-to-end voice → transcription → command flow

2. **Short-term:**
   - Integrate Clerk authentication on both sides
   - Implement project CRUD operations
   - Test with real E2B sandboxes and preview URLs

3. **Polish:**
   - Add TTS audio playback
   - Improve code inspection view
   - Add loading states and animations
   - Handle edge cases and errors gracefully

## Contact

For questions about the frontend implementation, refer to:
- `TECHNICAL_SPEC.md` - Architecture overview
- `BACKEND_COMPATIBILITY.md` - Detailed compatibility analysis
- `SpokenRealityApp/Services/WebSocketService.swift` - WebSocket implementation
- `SpokenRealityApp/Services/AudioRecordingService.swift` - Audio recording implementation
