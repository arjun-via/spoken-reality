# Via Backend

Backend service for Via — a voice-first app builder.

## Quick Start

### Prerequisites

- Node.js 20+
- PostgreSQL (local or Railway)
- API keys for: Clerk, E2B, xAI (Grok), Anthropic (Claude)

### Setup

1. **Install dependencies:**
   ```bash
   cd via-backend
   npm install
   ```

2. **Set up environment:**
   - Copy `env.example` to `.env`
   - Fill in your API keys (already done if you followed setup)

3. **Set up database:**
   
   Option A: Use local PostgreSQL
   ```bash
   # Create database
   createdb via_dev
   
   # Generate Prisma client and push schema
   npm run db:generate
   npm run db:push
   ```
   
   Option B: Use Railway PostgreSQL
   - Create a PostgreSQL database in Railway
   - Copy the DATABASE_URL to your `.env`

4. **Run development server:**
   ```bash
   npm run dev
   ```

5. **Test the server:**
   - Health check: http://localhost:3000/api/health
   - Infographic health: http://localhost:3000/api/infographic/health
   - WebSocket: ws://localhost:3000/ws?token=test

## Project Structure

```
via-backend/
├── src/
│   ├── index.ts              # Entry point
│   ├── config/
│   │   └── env.ts            # Environment config
│   ├── ws/
│   │   ├── server.ts         # WebSocket server
│   │   ├── handlers.ts       # Message handlers
│   │   └── types.ts          # Message types
│   ├── services/
│   │   ├── SessionManager.ts # User sessions
│   │   ├── VoicePipeline.ts  # Grok voice API
│   │   ├── AIOrchestrator.ts # Claude code gen
│   │   ├── SandboxManager.ts # E2B sandboxes
│   │   └── CheckpointManager.ts # Version control
│   ├── routes/
│   │   └── health.ts         # Health check
│   └── utils/
│       ├── logger.ts         # Logging
│       └── errors.ts         # Error classes
├── prisma/
│   └── schema.prisma         # Database schema
├── package.json
├── tsconfig.json
└── railway.toml              # Railway config
```

## Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start dev server with hot reload |
| `npm run build` | Build for production |
| `npm run start` | Start production server |
| `npm run db:generate` | Generate Prisma client |
| `npm run db:push` | Push schema to database |
| `npm run db:migrate` | Run migrations |
| `npm run db:studio` | Open Prisma Studio |

## WebSocket API

Connect to `ws://localhost:3000/ws?token={auth_token}`

### Client → Server Messages

| Type | Description |
|------|-------------|
| `voice.start` | Start voice recording |
| `voice.chunk` | Send audio chunk |
| `voice.end` | End voice recording |
| `command` | Send text command |
| `project.create` | Create new project |
| `project.open` | Open existing project |
| `project.getFiles` | Get project files |

### Server → Client Messages

| Type | Description |
|------|-------------|
| `agent.state` | Agent state update |
| `transcription.partial` | Partial transcription |
| `transcription.final` | Final transcription |
| `agent.speak` | Agent TTS response |
| `preview.ready` | Preview URL ready |
| `code.updated` | Files updated |
| `error` | Error occurred |

## REST API

### Infographic Generation

**POST** `/api/infographic/generate`

Generate an interactive infographic from a GitHub repository.

**Request:**
```json
{
  "repo_url": "https://github.com/owner/repo",
  "model": "zai-glm-4.7"  // optional, defaults to Cerebras GLM 4.7
}
```

**Response:**
```json
{
  "success": true,
  "duration_ms": 45678,
  "data": {
    "version": "2.0",
    "schema": "interactive-infographic",
    "repo_url": "https://github.com/owner/repo",
    "repo_name": "repo",
    "repo_summary": "Brief description",
    "pipeline_overview": "What this repo does",
    "generated_at": "2026-01-14T00:00:00Z",
    "root": { /* hierarchical JSON */ }
  },
  "stats": {
    "total_nodes": 45,
    "phases": 3,
    "steps": 8,
    "files": 12,
    "functions": 23,
    "code_blocks": 15,
    "max_depth": 5,
    "total_code_lines": 234
  }
}
```

**Health Check:**
- **GET** `/api/infographic/health` - Check if Cerebras API key is configured

## Deployment to Railway

1. Push code to GitHub
2. Create new Railway project
3. Connect GitHub repo
4. Add PostgreSQL database
5. Set environment variables
6. Deploy

Environment variables needed in Railway:
- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
- `CLERK_SECRET_KEY`
- `E2B_API_KEY`
- `XAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `CEREBRAS_API_KEY` (for infographic generation)
- `DATABASE_URL` (auto-provided by Railway PostgreSQL)

## Tech Stack

- **Runtime:** Node.js 20 + TypeScript
- **Framework:** Express + ws
- **Database:** PostgreSQL + Prisma
- **Auth:** Clerk
- **Voice:** xAI Grok Voice API
- **AI:** Claude Sonnet 4.5
- **Sandboxes:** E2B

## Current Status

✅ Project structure  
✅ WebSocket server  
✅ Message handlers  
✅ Service stubs  
⏳ Voice pipeline (mock implementation)  
⏳ AI orchestrator (connected to Claude)  
⏳ Sandbox manager (connected to E2B)  
⏳ Database integration  

## Next Steps

1. Test locally
2. Deploy to Railway
3. Implement full voice pipeline with Grok
4. Connect to iOS frontend
