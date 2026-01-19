# Frontend Compatibility Status

This document tracks compatibility between the backend and the iOS frontend as specified in `SpokenRealityApp/BACKEND_REQUIREMENTS.md`.

## ✅ Protocol Compatibility

All message types match exactly:

### Client → Server Messages
| Message | Status | Notes |
|---------|--------|-------|
| `voice.start` | ✅ Implemented | Initializes voice pipeline |
| `voice.chunk` | ✅ Implemented | Buffers audio chunks |
| `voice.end` | ✅ Implemented | Triggers Whisper transcription + AI processing |
| `command` | ✅ Implemented | Handles text commands and clarifications |
| `project.create` | ✅ Implemented | Creates project (DB pending) |
| `project.open` | ✅ Implemented | Opens project (DB pending) |
| `project.getFiles` | ✅ Implemented | Returns files from checkpoint |

### Server → Client Messages
| Message | Status | Notes |
|---------|--------|-------|
| `agent.state` | ✅ Implemented | All 8 states supported |
| `transcription.partial` | ⏳ Pending | Needs streaming STT |
| `transcription.final` | ✅ Implemented | Sent after Whisper transcription |
| `agent.speak` | ✅ Implemented | Text only (TTS pending) |
| `agent.clarify` | ✅ Implemented | Question + options |
| `preview.ready` | ✅ Implemented | Sends sandbox URL |
| `preview.reload` | ✅ Implemented | Triggers WebView reload |
| `code.updated` | ✅ Implemented | Sends file changes |
| `error` | ✅ Implemented | All error codes supported |

## ✅ Error Codes

All error codes from `BACKEND_REQUIREMENTS.md` are implemented:

| Code | Status | When Used |
|------|--------|-----------|
| `TRANSCRIPTION_FAILED` | ✅ | OpenAI Whisper API errors |
| `CLAUDE_ERROR` | ✅ | Claude API errors |
| `SANDBOX_ERROR` | ✅ | E2B sandbox errors |
| `INVALID_COMMAND` | ✅ | Unknown message types |
| `PROJECT_NOT_FOUND` | ✅ | Invalid project ID |
| `RATE_LIMIT` | ✅ | API rate limits |

## ⏳ Pending Implementation

### Audio Processing
- **Current:** Audio chunks buffered, transcribed via OpenAI Whisper
- **Format:** PCM 16-bit, 16kHz, mono, Base64 encoded
- **Future:** Streaming transcription for real-time feedback

### Authentication
- **Current:** Mock user ID assigned on connection
- **Needed:** Clerk token validation
- **Token Location:** `?token=` query parameter

### Database
- **Current:** In-memory storage only
- **Needed:** PostgreSQL via Prisma for:
  - Users
  - Projects
  - Conversations
  - Checkpoints

### Partial Transcriptions
- **Current:** Not sent during recording (batch transcription)
- **Future:** Stream partial transcriptions as user speaks

## Connection Details

### Development
```
WebSocket: ws://localhost:3000/ws?token=test
Health: http://localhost:3000/api/health
```

### Production (when deployed)
```
WebSocket: wss://api.via.app/ws?token={clerk-token}
```

## Testing Checklist

### Connection
- [x] WebSocket connects
- [x] Health endpoint works
- [ ] Clerk token validation
- [x] Reconnection supported (ping/pong)

### Voice Flow
- [x] voice.start received
- [x] voice.chunk buffered
- [x] voice.end triggers processing
- [ ] Partial transcriptions streamed
- [x] Final transcription sent
- [x] Agent states update correctly

### Command Processing
- [x] Commands parsed by Claude
- [x] Clarification flow works
- [x] Code generated
- [x] Sandbox created
- [x] Preview URL sent
- [x] Code updates sent

### Error Handling
- [x] Errors have correct codes
- [x] Recoverable flag set correctly
- [x] Suggested actions provided

## Next Steps for Full Integration

1. ✅ **Deploy to Railway** - `spoken-reality-production-9cd5.up.railway.app`
2. ✅ **Update frontend URL** - Connected to Railway backend
3. ✅ **Implement Whisper STT** - Batch transcription working
4. **Add Clerk validation** - Secure authentication (pending)
5. **Connect database** - Persistent storage (pending)

## Audio Format Reference

From `BACKEND_REQUIREMENTS.md`:
```
Codec: Linear PCM (uncompressed)
Sample Rate: 16kHz
Bit Depth: 16-bit
Channels: Mono (1 channel)
Container: .caf (Core Audio Format)
Encoding: Base64 (when sent over WebSocket)
Chunk Size: ~16KB per chunk
Streaming Interval: 100ms (10 chunks per second)
```

Backend decodes Base64 → raw PCM → creates WAV → feeds to OpenAI Whisper API.
