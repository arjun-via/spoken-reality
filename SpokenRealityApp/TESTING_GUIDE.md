# Testing Guide - iOS Frontend with Backend Integration

## Overview

The iOS frontend is now configured to connect to your local backend for testing. This guide walks through how to test the full voice → AI → preview flow.

## Prerequisites

### Backend Setup

1. **Start the backend server:**
   ```bash
   cd via-backend
   npm run dev
   ```

2. **Verify backend is running:**
   - Server should be listening on `http://localhost:3000`
   - WebSocket endpoint: `ws://localhost:3000/ws`
   - Check console for "Server running on port 3000" message

### iOS App Setup

1. **Open the project in Xcode:**
   ```bash
   open SpokenRealityApp.xcodeproj
   ```

2. **Select iOS Simulator:**
   - Choose any iPhone simulator (iPhone 15 Pro recommended)
   - Device menu → Select simulator

3. **Build and Run:**
   - Press ⌘R or click the Play button
   - Wait for app to install and launch

## Testing Flow

### 1. Launch and Connect

**Expected Behavior:**
- App opens to Home screen with projects
- Tap any project to enter Development view
- Connection status indicator appears in top-left: "Connecting..." → "Connected"
- Green dot indicates successful connection

**What to Watch:**

**iOS Console:**
```
🔌 Connecting to WebSocket backend...
✅ WebSocket connected to: ws://localhost:3000/ws
✅ WebSocket opened
```

**Backend Console:**
```
New WebSocket connection from userId: mock-user-test
```

**Troubleshooting:**
- If "Offline" or "Error" appears: Check backend is running
- If connection hangs: Check firewall/network settings
- If immediate disconnect: Check backend accepts test token

### 2. Test Voice Recording

**Steps:**
1. Tap and hold the coral floating button (bottom-right)
2. Speak a command: "Create a product dashboard with search"
3. Release the button

**Expected Behavior:**

**During Recording (Hold):**
- Button shows pulsing ring animation
- Recording overlay appears with waveform bars
- Timer shows recording duration (00:00.0)
- Audio waveform reacts to your voice

**iOS Console:**
```
🎤 Recording started
📤 Sending voice.start
📤 Sending audio chunk (16384 bytes)
📤 Sending audio chunk (16384 bytes)
...
📤 Sending voice.end
```

**Backend Console:**
```
Received: voice.start { projectId: 'default-project' }
Received: voice.chunk (16KB audio data)
Received: voice.chunk (16KB audio data)
...
Received: voice.end
Starting AI processing...
```

**After Release:**
- Button transitions to processing state (spinner)
- Progress bar appears at top
- Recording overlay fades out
- Transcription overlay appears

### 3. Test Transcription Display

**Expected Behavior:**

**iOS UI:**
- Transcription overlay shows: "You said: Create a product dashboard..."
- Text appears in semi-transparent box at top of screen
- Stays visible during processing

**iOS Console:**
```
📨 Received: transcription.final
📝 Transcription: "Create a product dashboard with search"
```

**Backend Console:**
```
Sending transcription.final: "Create a product dashboard..."
```

**Note:** Backend uses OpenAI Whisper for speech-to-text transcription.

### 4. Test Agent State Flow

**Expected State Transitions:**

1. **LISTENING** (during recording)
   - Button: Pulsing ring
   - UI: Recording overlay visible

2. **INTERPRETING** (after voice.end)
   - Button: Spinner
   - Progress bar: Visible
   - UI: "Building your app..."

3. **PLANNING** (AI planning)
   - Same as INTERPRETING
   - Backend decides what to build

4. **EXECUTING** (code generation)
   - Same as INTERPRETING
   - Backend generates files

5. **PRESENTING** (complete)
   - Button: Green checkmark (1 second)
   - Progress bar: Hidden
   - Preview URL loads in WebView

**iOS Console:**
```
📨 Received: agent.state { state: LISTENING }
📨 Received: agent.state { state: INTERPRETING }
📨 Received: agent.state { state: PLANNING }
📨 Received: agent.state { state: EXECUTING }
📨 Received: agent.state { state: PRESENTING }
```

**Backend Console:**
```
State change: IDLE → LISTENING
State change: LISTENING → INTERPRETING
State change: INTERPRETING → PLANNING
State change: PLANNING → EXECUTING
State change: EXECUTING → PRESENTING
```

### 5. Test Preview URL Loading

**Expected Behavior:**

**When preview.ready arrives:**
- WebView automatically loads the E2B sandbox URL
- URL appears in WebView (center of screen)
- Loading spinner shows during page load
- Page renders once loaded

**iOS Console:**
```
📨 Received: preview.ready { url: 'https://...' }
🌐 Loading preview URL: https://...
```

**Backend Console:**
```
E2B sandbox ready
Sending preview.ready: https://...
```

**iOS UI:**
- Tab automatically switches to "Output" if on "Database"
- WebView shows the live preview
- Can interact with the preview

### 6. Test Code Updates

**Expected Behavior:**

**iOS Console:**
```
📨 Received: code.updated
📝 Code updated: 3 files
- src/App.tsx
- src/components/ProductTable.tsx
- src/styles/globals.css
```

**iOS UI:**
- Code inspection view will show updated files (when implemented)
- For now, logged to console

### 7. Test Clarification Flow

**To Trigger:**
Backend sends clarification when intent is ambiguous. You can test by modifying backend to send:

```typescript
sendMessage(ws, {
  type: 'agent.clarify',
  payload: {
    question: 'What database should I use?',
    options: ['SQLite', 'PostgreSQL', 'MongoDB']
  }
})
```

**Expected Behavior:**

**iOS UI:**
- Modal pops up with question
- Three option buttons appear
- "Other (type response)" button at bottom
- User selects option or types custom response

**After Selection:**
- Modal dismisses
- Command message sent to backend
- Processing continues

**iOS Console:**
```
📨 Received: agent.clarify
❓ Showing clarification modal
📤 Sending command: "PostgreSQL"
```

**Backend Console:**
```
Received: command { text: 'PostgreSQL' }
Resuming execution with user choice...
```

### 8. Test Error Handling

**To Trigger:**
Backend can send error at any point:

```typescript
sendMessage(ws, {
  type: 'error',
  payload: {
    code: 'TRANSCRIPTION_FAILED',
    message: 'Failed to transcribe audio',
    recoverable: true,
    suggestedAction: 'Please try recording again with clearer audio'
  }
})
```

**Expected Behavior:**

**iOS UI:**
- Alert dialog appears
- Shows error message and suggested action
- If recoverable: "Retry" and "Cancel" buttons
- If not recoverable: "OK" button only

**iOS Console:**
```
📨 Received: error
❌ Error: TRANSCRIPTION_FAILED - Failed to transcribe audio
```

**Backend Console:**
```
Sending error: TRANSCRIPTION_FAILED
```

### 9. Test Reconnection

**To Trigger:**
1. Stop the backend server (Ctrl+C)
2. Observe iOS app behavior
3. Restart backend server
4. Observe reconnection

**Expected Behavior:**

**After Backend Stops:**
- Connection status: "Offline" (gray dot)
- iOS Console: "❌ WebSocket receive error: ..."
- iOS Console: "🔄 Reconnecting... (attempt 1/5)"

**Reconnection Attempts:**
- Attempt 1: After 2 seconds
- Attempt 2: After 4 seconds
- Attempt 3: After 8 seconds
- Attempt 4: After 16 seconds
- Attempt 5: After 30 seconds

**After Backend Restarts:**
- Connection status: "Connected" (green dot)
- iOS Console: "✅ WebSocket connected"
- Recording functionality restored

### 10. Test Preview Reload

**To Trigger:**
Backend sends preview.reload when code changes:

```typescript
sendMessage(ws, {
  type: 'preview.reload',
  payload: {}
})
```

**Expected Behavior:**

**iOS UI:**
- WebView refreshes
- Brief loading spinner
- Updated preview appears

**iOS Console:**
```
📨 Received: preview.reload
🔄 Reloading preview...
```

## Common Issues and Solutions

### Issue: Connection Status Shows "Offline"

**Possible Causes:**
1. Backend not running
2. Backend running on different port
3. Network/firewall blocking connection

**Solution:**
```bash
# Check backend is running
curl http://localhost:3000

# Check WebSocket endpoint
wscat -c ws://localhost:3000/ws?token=test

# If port 3000 is in use, change port in backend and update iOS:
# WebSocketService.swift line 45: self.serverURL = "ws://localhost:YOUR_PORT/ws"
```

### Issue: No Audio Recording

**Possible Causes:**
1. Microphone permission denied
2. Simulator audio input not configured
3. Recording service not initialized

**Solution:**
1. Check Settings → Privacy → Microphone → Allow
2. Use physical device for better audio testing
3. Check console for "Recording error:" messages

### Issue: Backend Receives Empty Audio Chunks

**Possible Causes:**
1. Audio encoding issue
2. Base64 encoding/decoding problem
3. Format mismatch

**Solution:**
1. Check backend logs for chunk sizes
2. Verify Base64 decoding works
3. Confirm PCM 16kHz format expected

### Issue: Preview URL Not Loading

**Possible Causes:**
1. Invalid URL from backend
2. E2B sandbox not ready
3. Network connectivity issue

**Solution:**
1. Check URL format in backend logs
2. Test URL in Safari: copy from logs and open
3. Verify E2B API key is valid

### Issue: Agent State Stuck

**Possible Causes:**
1. Backend not sending state updates
2. WebSocket message lost
3. Error in backend processing

**Solution:**
1. Check backend console for state transitions
2. Look for error messages in both consoles
3. Restart both backend and iOS app

## Performance Benchmarks

### Expected Metrics:

**Connection:**
- Initial connection: < 1 second
- Reconnection: 2-30 seconds (exponential backoff)

**Audio Streaming:**
- Chunk size: ~16KB
- Chunk interval: 100ms
- Chunks per second: 10
- Bandwidth during recording: ~160KB/s

**Recording:**
- 5-second recording: ~800KB total
- 10-second recording: ~1.6MB total
- Max recommended: 30 seconds (~4.8MB)

**UI Response:**
- Button tap → recording start: < 100ms
- Button release → processing start: < 200ms
- State change → UI update: < 100ms
- Preview URL → WebView load: 1-3 seconds

## Debug Console Commands

### Viewing iOS Logs:

**In Xcode:**
1. Run app (⌘R)
2. Open Debug Area (⌘⇧Y)
3. Look for console output in bottom panel

**Filter logs:**
- Search box: Enter "WebSocket" or "📨" to filter messages
- Click "All Output" dropdown for more options

### Viewing Backend Logs:

**In Terminal:**
```bash
cd via-backend
npm run dev | grep -E "(WebSocket|Received|Sending)"
```

### Testing WebSocket Manually:

```bash
# Install wscat
npm install -g wscat

# Connect to backend
wscat -c ws://localhost:3000/ws?token=test

# Send test message
> {"type":"voice.start","payload":{"projectId":"test"},"timestamp":1234567890,"messageId":"test-123"}

# You should see confirmation in backend logs
```

## Next Steps

### Phase 1: Local Testing ✅
- [x] Connect iOS app to local backend
- [x] Test voice recording → transcription
- [x] Test agent state flow
- [x] Test preview URL loading

### Phase 2: Voice Integration (Backend)
- [x] OpenAI Whisper transcription implemented
- [ ] Implement streaming partial transcriptions
- [ ] Test with various voice inputs

### Phase 3: Clerk Authentication
- [ ] Add Clerk iOS SDK to frontend
- [ ] Implement sign-in flow
- [ ] Pass real Clerk tokens to WebSocket
- [ ] Backend validates Clerk tokens

### Phase 4: Deployment
- [ ] Deploy backend to Railway
- [ ] Update iOS app with production URL
- [ ] Test with deployed backend
- [ ] TestFlight beta testing

### Phase 5: Polish
- [ ] Improve code inspection view
- [ ] Add project management (create/delete/rename)
- [ ] Add settings (audio quality, etc.)
- [ ] Add onboarding tutorial

## Support

If you encounter issues:

1. **Check both consoles** (iOS + Backend) for error messages
2. **Verify compatibility** with FRONTEND_COMPATIBILITY.md
3. **Test WebSocket manually** with wscat
4. **Review message protocol** in BACKEND_REQUIREMENTS.md
5. **Check this guide** for common issues

For specific errors, search console output for error codes:
- `TRANSCRIPTION_FAILED` - Whisper API issue
- `CLAUDE_ERROR` - Claude API issue
- `SANDBOX_ERROR` - E2B issue
- `INVALID_COMMAND` - User input issue

---

**Last Updated:** 2025-12-31
**iOS App Version:** 1.0 (Debug build)
**Backend Version:** See via-backend/package.json
