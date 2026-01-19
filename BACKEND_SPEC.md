# Via Backend Specification — MVP

**Version:** 2.0  
**Last Updated:** 2025-12-31  
**Status:** Planning  

---

## Executive Summary

This document specifies the backend architecture for Via's MVP — a voice-first mobile app that generates production-grade CRUD dashboards. The backend handles voice processing, AI orchestration, code generation, and real-time preview delivery.

**Core Flow:**
```
iOS App → WebSocket → Backend → OpenAI Whisper (STT) → Claude (code) → E2B (execution) → WebView
```

**Design Principle:** Simplest possible architecture that delivers sub-3-second voice-to-visual latency.

---

## Technology Stack

| Component | Technology | Why | Current Status (Dec 2025) |
|-----------|------------|-----|---------------------------|
| **Runtime** | Node.js 20+ with TypeScript | Best WebSocket ecosystem, simple deployment | Stable, LTS |
| **Framework** | Express + ws (WebSocket) | Minimal, battle-tested, easy to understand | Stable |
| **Database** | PostgreSQL (Railway-managed) | Single DB for everything, no ops overhead | Stable |
| **ORM** | Prisma | Type-safe, simple migrations, great DX | v5.x stable |
| **Authentication** | Clerk | Handles iOS SDK, no custom auth code, free tier up to 10K MAU | Stable, iOS SDK available |
| **Voice STT** | OpenAI Whisper | Industry standard, high accuracy, $0.006/min | Stable |
| **AI Model** | Anthropic Claude | Best code generation quality | Current production model |
| **Code Execution** | E2B Sandboxes | <200ms startup, 24-hour sessions, battle-tested for AI agents | Stable |
| **Hosting** | Railway | One-click deploy, managed Postgres, WebSocket support, global scaling | Stable |

---

## Model Selection Rationale

### Claude Model Options (as of December 2025)

| Model | Best For | Speed | Cost (per 1M tokens) | Our Use |
|-------|----------|-------|---------------------|---------|
| **Claude Opus 4.5** | Complex reasoning, planning, architecture decisions | Slower | $15 input / $75 output | Future: complex refactors |
| **Claude Sonnet 4.5** | Code generation, real-world agents, balanced performance | Fast | $3 input / $15 output | **MVP: Primary model** |
| **Claude Haiku 4.5** | Simple tasks, fast responses | Fastest | ~$0.25 input / $1.25 output | Future: simple edits |

**Decision: Claude Sonnet 4.5 for MVP**
- Released September 29, 2025
- Optimized for coding and agentic tasks
- Best balance of speed and quality for real-time voice interaction
- 200K context window (sufficient for full project context)
- Significantly faster than Opus 4.5 (critical for latency budget)

### Voice API Options

| API | Latency | Cost | Notes |
|-----|---------|------|-------|
| **OpenAI Whisper** | <1s | $0.006/min | Industry standard, high accuracy |
| Deepgram | <300ms STT | $0.0043/min | STT only, need separate TTS |

**Decision: OpenAI Whisper**
- Industry standard with excellent accuracy
- Simple integration via OpenAI SDK
- Cost-effective at $0.006/minute
- Compatible with OpenAI Realtime API spec (easy migration if needed)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           iOS App                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │   Voice     │  │   WebView   │  │   Agent     │                  │
│  │   Input     │  │   (Output)  │  │   Bar UI    │                  │
│  └──────┬──────┘  └──────▲──────┘  └──────▲──────┘                  │
│         │                │                │                          │
│         └────────────────┼────────────────┘                          │
│                          │                                           │
│                    WebSocket Connection                              │
└──────────────────────────┼───────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      Railway Backend                                  │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                    WebSocket Server                             │  │
│  │  • Receives voice audio chunks                                  │  │
│  │  • Streams agent state updates                                  │  │
│  │  • Delivers preview URLs                                        │  │
│  └─────────────────────────┬──────────────────────────────────────┘  │
│                            │                                          │
│  ┌─────────────────────────▼──────────────────────────────────────┐  │
│  │                    Session Manager                              │  │
│  │  • Maps user → active session                                   │  │
│  │  • Tracks agent state (IDLE, LISTENING, EXECUTING, etc.)        │  │
│  │  • Manages conversation history                                 │  │
│  └─────────────────────────┬──────────────────────────────────────┘  │
│                            │                                          │
│  ┌─────────────────────────▼──────────────────────────────────────┐  │
│  │                    Voice Pipeline                               │  │
│  │  • OpenAI Whisper integration                                   │  │
│  │  • Speech-to-text                                               │  │
│  │  • Text-to-speech (planned)                                     │  │
│  └─────────────────────────┬──────────────────────────────────────┘  │
│                            │                                          │
│  ┌─────────────────────────▼──────────────────────────────────────┐  │
│  │                    AI Orchestrator                              │  │
│  │  • Claude Sonnet 4.5 for code generation                        │  │
│  │  • Intent parsing                                               │  │
│  │  • Code generation with full project context                    │  │
│  └─────────────────────────┬──────────────────────────────────────┘  │
│                            │                                          │
│  ┌─────────────────────────▼──────────────────────────────────────┐  │
│  │                    Sandbox Manager                              │  │
│  │  • E2B sandbox lifecycle                                        │  │
│  │  • File operations (write generated code)                       │  │
│  │  • Dev server management (Vite)                                 │  │
│  │  • Returns preview URL                                          │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                    PostgreSQL (Railway)                         │  │
│  │  • Users, Projects, Conversations, Checkpoints                  │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   ┌────────────┐   ┌────────────┐   ┌────────────┐
   │  OpenAI    │   │  Claude    │   │    E2B     │
   │  Whisper   │   │ (Anthropic)│   │  Sandbox   │
   │  (STT)     │   │            │   │            │
   └────────────┘   └────────────┘   └────────────┘
```

---

## Generated Code Stack (Fixed for MVP)

The code Via generates uses this opinionated, fixed stack:

| Layer | Technology | Version | Notes |
|-------|------------|---------|-------|
| **Framework** | Next.js | 15.x (App Router) | Latest stable, Dec 2025 |
| **Language** | TypeScript | 5.x | Strict mode |
| **Styling** | Tailwind CSS | 4.x | Latest stable |
| **Components** | Shadcn/UI | Latest | Copy-paste components |
| **ORM** | Prisma | 5.x | Type-safe database access |
| **Database** | PostgreSQL | 16.x | Via E2B sandbox |
| **Dev Server** | Vite | 6.x | Fast HMR |

---

## Data Models (Prisma Schema)

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ============================================
// USER & AUTH
// ============================================

model User {
  id            String    @id @default(cuid())
  clerkId       String    @unique  // Clerk user ID
  email         String    @unique
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  
  projects      Project[]
  sessions      Session[]
}

// ============================================
// PROJECTS
// ============================================

model Project {
  id            String    @id @default(cuid())
  name          String
  description   String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  
  // E2B sandbox info
  sandboxId     String?   // Active E2B sandbox ID
  sandboxUrl    String?   // Preview URL from sandbox
  sandboxExpiresAt DateTime? // E2B sandboxes expire after 24h
  
  // Owner
  userId        String
  user          User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  // Related data
  conversations Conversation[]
  checkpoints   Checkpoint[]
  files         ProjectFile[]
  
  @@index([userId])
}

model ProjectFile {
  id            String    @id @default(cuid())
  path          String    // e.g., "src/components/Dashboard.tsx"
  content       String    // File content
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  
  projectId     String
  project       Project   @relation(fields: [projectId], references: [id], onDelete: Cascade)
  
  @@unique([projectId, path])
  @@index([projectId])
}

// ============================================
// CONVERSATIONS & HISTORY
// ============================================

model Conversation {
  id            String    @id @default(cuid())
  createdAt     DateTime  @default(now())
  
  projectId     String
  project       Project   @relation(fields: [projectId], references: [id], onDelete: Cascade)
  
  messages      Message[]
  
  @@index([projectId])
}

model Message {
  id              String      @id @default(cuid())
  role            MessageRole
  content         String      // Text content (transcribed for user, generated for assistant)
  createdAt       DateTime    @default(now())
  
  // For assistant messages: what action was taken
  action          String?     // e.g., "generated_code", "clarification", "error"
  actionDetails   Json?       // Additional structured data about the action
  
  // Token usage tracking
  inputTokens     Int?
  outputTokens    Int?
  
  conversationId  String
  conversation    Conversation @relation(fields: [conversationId], references: [id], onDelete: Cascade)
  
  @@index([conversationId])
}

enum MessageRole {
  USER
  ASSISTANT
  SYSTEM
}

// ============================================
// CHECKPOINTS (Version Control)
// ============================================

model Checkpoint {
  id            String    @id @default(cuid())
  name          String    // Auto-generated or user-provided name
  description   String?   // What was built at this point
  createdAt     DateTime  @default(now())
  
  // Snapshot of all files at this checkpoint
  files         Json      // Array of { path: string, content: string }
  
  projectId     String
  project       Project   @relation(fields: [projectId], references: [id], onDelete: Cascade)
  
  @@index([projectId])
}

// ============================================
// ACTIVE SESSIONS (In-Memory, but tracked)
// ============================================

model Session {
  id            String       @id @default(cuid())
  state         AgentState   @default(IDLE)
  createdAt     DateTime     @default(now())
  updatedAt     DateTime     @updatedAt
  lastActiveAt  DateTime     @default(now())
  
  // Current context
  currentProjectId  String?
  
  userId        String
  user          User         @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  @@index([userId])
}

enum AgentState {
  IDLE
  LISTENING
  INTERPRETING
  CLARIFYING
  PLANNING
  EXECUTING
  PRESENTING
  ERROR
}
```

---

## API Design

### WebSocket Protocol

Single WebSocket connection per user session. All communication flows through this connection.

**Connection URL:**
```
wss://api.via.app/ws?token={clerk_session_token}
```

### Message Format

All messages are JSON with a `type` field:

```typescript
interface WebSocketMessage {
  type: string;
  payload: any;
  timestamp: number;  // Unix timestamp
  messageId: string;  // For request/response correlation
}
```

### Client → Server Messages

#### 1. Voice Audio Stream
```typescript
// Start voice input
{
  type: "voice.start",
  payload: {
    projectId: string;
  }
}

// Audio chunk (sent continuously while recording)
{
  type: "voice.chunk",
  payload: {
    audio: string;  // Base64-encoded audio chunk (PCM 16-bit, 16kHz)
  }
}

// End voice input
{
  type: "voice.end",
  payload: {}
}
```

#### 2. Commands
```typescript
// Voice command (already transcribed on client, or typed)
{
  type: "command",
  payload: {
    text: string;  // "stop", "undo", "show me the code", etc.
    projectId: string;
  }
}
```

#### 3. Project Operations
```typescript
// Create new project
{
  type: "project.create",
  payload: {
    name: string;
  }
}

// Open existing project
{
  type: "project.open",
  payload: {
    projectId: string;
  }
}

// Get project files (for code inspection)
{
  type: "project.getFiles",
  payload: {
    projectId: string;
  }
}
```

### Server → Client Messages

#### 1. Agent State Updates
```typescript
{
  type: "agent.state",
  payload: {
    state: "IDLE" | "LISTENING" | "INTERPRETING" | "CLARIFYING" | "PLANNING" | "EXECUTING" | "PRESENTING" | "ERROR";
    message?: string;  // Human-readable status, e.g., "Adding search bar..."
    progress?: number; // 0-100 for EXECUTING state
  }
}
```

#### 2. Transcription
```typescript
// Real-time transcription as user speaks
{
  type: "transcription.partial",
  payload: {
    text: string;  // Partial transcription
  }
}

// Final transcription
{
  type: "transcription.final",
  payload: {
    text: string;  // Complete transcription
  }
}
```

#### 3. Agent Response
```typescript
// Agent speaks (TTS audio)
{
  type: "agent.speak",
  payload: {
    text: string;      // What the agent is saying
    audio?: string;    // Base64-encoded audio (optional, for TTS)
  }
}

// Agent asks for clarification
{
  type: "agent.clarify",
  payload: {
    question: string;  // "Do you want Google OAuth or GitHub OAuth?"
    options?: string[]; // Optional: suggested options
  }
}
```

#### 4. Preview Updates
```typescript
// Preview URL ready or updated
{
  type: "preview.ready",
  payload: {
    url: string;  // E2B sandbox URL, e.g., "https://abc123.e2b.dev"
  }
}

// Hot reload triggered (WebView should refresh)
{
  type: "preview.reload",
  payload: {}
}
```

#### 5. Code Updates (for code inspection)
```typescript
{
  type: "code.updated",
  payload: {
    files: Array<{
      path: string;
      content: string;
    }>;
  }
}
```

#### 6. Errors
```typescript
{
  type: "error",
  payload: {
    code: string;        // Error code, e.g., "SANDBOX_FAILED"
    message: string;     // Human-readable message
    recoverable: boolean;
    suggestedAction?: string;  // "Try again" or "Check your API key"
  }
}
```

### REST Endpoints (Fallback/Utility)

For operations that don't need real-time:

```
GET  /api/health              → Health check
GET  /api/projects            → List user's projects
GET  /api/projects/:id        → Get project details
GET  /api/projects/:id/files  → Get all project files
POST /api/projects/:id/export → Export project as zip
```

---

## Core Services

### 1. WebSocket Server (`src/ws/server.ts`)

Handles connection lifecycle, authentication, and message routing.

```typescript
// Responsibilities:
// - Authenticate incoming connections via Clerk token
// - Create/restore user session
// - Route messages to appropriate handlers
// - Broadcast state updates to client
// - Handle disconnection and cleanup

interface WebSocketServer {
  // Connection management
  handleConnection(ws: WebSocket, req: Request): Promise<void>;
  handleDisconnection(userId: string): Promise<void>;
  
  // Message routing
  handleMessage(userId: string, message: WebSocketMessage): Promise<void>;
  
  // Broadcasting
  sendToUser(userId: string, message: WebSocketMessage): void;
}
```

### 2. Session Manager (`src/services/SessionManager.ts`)

Manages active user sessions and agent state.

```typescript
interface SessionManager {
  // Session lifecycle
  createSession(userId: string): Promise<Session>;
  getSession(userId: string): Promise<Session | null>;
  updateState(userId: string, state: AgentState, message?: string): Promise<void>;
  
  // Project context
  setActiveProject(userId: string, projectId: string): Promise<void>;
  getActiveProject(userId: string): Promise<Project | null>;
  
  // Conversation context
  getConversationHistory(projectId: string, limit?: number): Promise<Message[]>;
  addMessage(projectId: string, message: Omit<Message, 'id'>): Promise<Message>;
}
```

### 3. Voice Pipeline (`src/services/VoicePipeline.ts`)

Handles voice input/output via OpenAI Whisper API.

```typescript
interface VoicePipeline {
  // Speech-to-text
  startListening(userId: string): void;
  processAudioChunk(userId: string, audioChunk: Buffer): void;
  stopListening(userId: string): Promise<string>;  // Returns final transcription
  
  // Text-to-speech
  speak(text: string): Promise<Buffer>;  // Returns audio buffer
}
```

**OpenAI Whisper Integration:**
- **Endpoint:** OpenAI SDK `audio.transcriptions.create`
- **Model:** `whisper-1`
- **Format:** WAV (16-bit PCM, 16kHz, mono)
- **Cost:** $0.006/minute of audio
- **Latency:** <1 second time-to-first-audio
- **Features:** Native conversation handling, context awareness

### 4. AI Orchestrator (`src/services/AIOrchestrator.ts`)

Handles intent parsing and code generation via Claude Sonnet 4.5.

```typescript
interface AIOrchestrator {
  // Parse user intent from transcription
  parseIntent(
    transcription: string, 
    conversationHistory: Message[],
    projectContext: ProjectContext
  ): Promise<Intent>;
  
  // Generate code based on intent
  generateCode(
    intent: Intent,
    existingFiles: ProjectFile[],
    conversationHistory: Message[]
  ): Promise<CodeGenResult>;
  
  // Handle clarification
  generateClarification(
    intent: Intent,
    ambiguity: string
  ): Promise<string>;
}

interface Intent {
  type: 'create' | 'modify' | 'delete' | 'query' | 'command';
  target?: string;      // What to modify, e.g., "search bar", "products table"
  action?: string;      // What to do, e.g., "add", "remove", "change"
  details?: string;     // Additional context
  confidence: number;   // 0-1
  needsClarification: boolean;
  clarificationQuestion?: string;
}

interface CodeGenResult {
  files: Array<{
    path: string;
    content: string;
    action: 'create' | 'update' | 'delete';
  }>;
  explanation: string;  // What was done
  checkpoint: boolean;  // Should create a checkpoint?
}
```

**Claude Sonnet 4.5 Integration:**
- **Endpoint:** `https://api.anthropic.com/v1/messages`
- **Model:** `claude-sonnet-4-5-20250929` (released Sept 29, 2025)
- **Context Window:** 200K tokens
- **Max Output:** 8192 tokens (sufficient for most file changes)
- **Pricing:** $3/1M input tokens, $15/1M output tokens
- **Features:** Excellent at coding, agentic tasks, computer use

### 5. Sandbox Manager (`src/services/SandboxManager.ts`)

Manages E2B sandbox lifecycle and file operations.

```typescript
interface SandboxManager {
  // Sandbox lifecycle
  createSandbox(projectId: string): Promise<Sandbox>;
  getSandbox(projectId: string): Promise<Sandbox | null>;
  destroySandbox(projectId: string): Promise<void>;
  keepAlive(sandboxId: string): Promise<void>;  // Extend session
  
  // File operations
  writeFiles(sandboxId: string, files: Array<{path: string, content: string}>): Promise<void>;
  readFile(sandboxId: string, path: string): Promise<string>;
  listFiles(sandboxId: string, directory?: string): Promise<string[]>;
  
  // Dev server
  startDevServer(sandboxId: string): Promise<string>;  // Returns preview URL
  getPreviewUrl(sandboxId: string): Promise<string>;
}

interface Sandbox {
  id: string;
  projectId: string;
  url: string;          // Preview URL
  createdAt: Date;
  expiresAt: Date;      // E2B sandboxes expire after 24h
}
```

**E2B Integration Details:**
- **Template:** Custom template with Next.js 15 + Tailwind 4 + Shadcn/UI pre-installed
- **Startup:** <200ms (no cold start with keep-alive)
- **Session Duration:** Up to 24 hours (can extend with keep-alive)
- **Cost:** ~$0.10/hour per sandbox
- **Features:** Full Linux environment, persistent filesystem within session

### 6. Checkpoint Manager (`src/services/CheckpointManager.ts`)

Handles versioning and rollback.

```typescript
interface CheckpointManager {
  // Create checkpoint
  createCheckpoint(
    projectId: string, 
    name: string, 
    description?: string
  ): Promise<Checkpoint>;
  
  // Auto-checkpoint after significant changes
  autoCheckpoint(projectId: string, action: string): Promise<Checkpoint>;
  
  // List checkpoints
  listCheckpoints(projectId: string): Promise<Checkpoint[]>;
  
  // Restore to checkpoint
  restoreCheckpoint(projectId: string, checkpointId: string): Promise<void>;
  
  // Undo last change
  undo(projectId: string): Promise<void>;
}
```

---

## Agent State Machine

```
                    ┌─────────────────────────────────────┐
                    │                                     │
                    ▼                                     │
              ┌──────────┐                                │
              │   IDLE   │◄───────────────────────────────┤
              └────┬─────┘                                │
                   │ voice.start                          │
                   ▼                                      │
              ┌──────────┐                                │
              │LISTENING │                                │
              └────┬─────┘                                │
                   │ voice.end OR 1.5s silence            │
                   ▼                                      │
           ┌──────────────┐                               │
           │ INTERPRETING │                               │
           └───────┬──────┘                               │
                   │                                      │
          ┌────────┴────────┐                             │
          │                 │                             │
          ▼                 ▼                             │
    ┌───────────┐    ┌──────────┐                         │
    │CLARIFYING │    │ PLANNING │                         │
    └─────┬─────┘    └────┬─────┘                         │
          │               │                               │
          │ user responds │                               │
          └───────┬───────┘                               │
                  ▼                                       │
            ┌───────────┐                                 │
            │ EXECUTING │                                 │
            └─────┬─────┘                                 │
                  │                                       │
         ┌────────┴────────┐                              │
         │                 │                              │
         ▼                 ▼                              │
   ┌───────────┐     ┌─────────┐                          │
   │PRESENTING │     │  ERROR  │                          │
   └─────┬─────┘     └────┬────┘                          │
         │                │                               │
         │ new request    │ user recovers                 │
         └────────────────┴───────────────────────────────┘
```

**State Transitions:**

| From | Event | To | Action |
|------|-------|-----|--------|
| IDLE | voice.start | LISTENING | Start audio capture |
| LISTENING | voice.end | INTERPRETING | Send to Whisper STT |
| LISTENING | 1.5s silence | INTERPRETING | Auto-end, send to Whisper |
| INTERPRETING | intent parsed | PLANNING | Determine code changes |
| INTERPRETING | ambiguous | CLARIFYING | Ask clarification question |
| CLARIFYING | user responds | PLANNING | Re-parse with clarification |
| PLANNING | plan ready | EXECUTING | Generate code, write to sandbox |
| EXECUTING | success | PRESENTING | Show preview, announce completion |
| EXECUTING | failure | ERROR | Show error with recovery options |
| PRESENTING | new request | LISTENING | Implicit confirmation, start new |
| PRESENTING | "done" | IDLE | Explicit confirmation |
| ERROR | retry | EXECUTING | Retry last action |
| ERROR | new request | LISTENING | Abandon error, start fresh |

---

## Prompts

### System Prompt for Intent Parsing

```
You are an AI assistant for Via, a voice-first app builder. Your job is to parse user voice commands into structured intents.

The user is building a CRUD dashboard application using Next.js 15, Tailwind CSS 4, Shadcn/UI, and Prisma with PostgreSQL.

Parse the user's transcription into:
1. Intent type: create, modify, delete, query, or command
2. Target: What they want to change (e.g., "products table", "search bar", "login page")
3. Action: What they want to do (e.g., "add", "remove", "change color")
4. Details: Any specific requirements mentioned

If the intent is ambiguous, set needsClarification to true and provide a clarificationQuestion.

Examples:
- "Add a search bar to the products table" → { type: "modify", target: "products table", action: "add search bar" }
- "Make the header blue" → { type: "modify", target: "header", action: "change color", details: "blue" }
- "Create a login page" → { type: "create", target: "login page" }
- "Add authentication" → { type: "create", target: "authentication", needsClarification: true, clarificationQuestion: "What type of authentication? Email/password, Google, or GitHub?" }

Respond in JSON format only.
```

### System Prompt for Code Generation

```
You are an expert full-stack developer for Via, a voice-first app builder. Generate production-grade Next.js code.

Tech stack (fixed, do not deviate):
- Next.js 15 (App Router)
- TypeScript (strict mode)
- Tailwind CSS 4
- Shadcn/UI components
- Prisma ORM
- PostgreSQL

Code quality requirements:
- Production-grade: proper error handling, type safety, accessibility
- No placeholder code or TODOs — everything must work
- Use Shadcn/UI components when available
- Follow Next.js 15 App Router conventions (app directory, server components by default)
- Keep files focused and under 300 lines
- Use 'use client' directive only when necessary
- Proper loading and error states

Current project files:
{files}

Conversation history:
{history}

User intent:
{intent}

Generate the necessary file changes. For each file, specify:
- path: Full file path from project root (e.g., "app/dashboard/page.tsx")
- content: Complete file content (not a diff)
- action: "create", "update", or "delete"

Respond in JSON format:
{
  "files": [...],
  "explanation": "Brief description of what was done",
  "checkpoint": true/false  // true if this is a significant feature addition
}
```

---

## Project Structure

```
via-backend/
├── src/
│   ├── index.ts                    # Entry point
│   ├── config/
│   │   └── env.ts                  # Environment variables
│   ├── ws/
│   │   ├── server.ts               # WebSocket server
│   │   ├── handlers.ts             # Message handlers
│   │   └── types.ts                # WebSocket message types
│   ├── services/
│   │   ├── SessionManager.ts       # Session & state management
│   │   ├── VoicePipeline.ts        # OpenAI Whisper STT
│   │   ├── AIOrchestrator.ts       # Claude integration
│   │   ├── SandboxManager.ts       # E2B integration
│   │   └── CheckpointManager.ts    # Version control
│   ├── routes/
│   │   ├── health.ts               # Health check
│   │   └── projects.ts             # REST endpoints
│   ├── middleware/
│   │   └── auth.ts                 # Clerk authentication
│   └── utils/
│       ├── logger.ts               # Logging
│       └── errors.ts               # Error handling
├── prisma/
│   └── schema.prisma               # Database schema
├── e2b-template/                   # Custom E2B template
│   ├── package.json                # Next.js 15 + deps
│   └── setup.sh                    # Template setup script
├── package.json
├── tsconfig.json
├── .env.example
└── README.md
```

---

## Environment Variables

```bash
# .env.example

# Server
PORT=3000
NODE_ENV=development

# Database (Railway provides this)
DATABASE_URL=postgresql://...

# Authentication (Clerk)
CLERK_SECRET_KEY=sk_...
CLERK_PUBLISHABLE_KEY=pk_...

# Voice API (OpenAI Whisper)
GROK_API_KEY=xai-...

# AI Model (Anthropic Claude)
ANTHROPIC_API_KEY=sk-ant-...

# Code Execution (E2B)
E2B_API_KEY=e2b_...

# Optional: Logging
LOG_LEVEL=info
```

---

## Latency Budget

Target: **< 3 seconds** from voice end to visual update

| Stage | Target | Notes |
|-------|--------|-------|
| Voice capture end | 0ms | Baseline |
| Audio → Whisper STT | 500ms | Batch transcription |
| Intent parsing (Claude) | 300ms | Simple structured output |
| Code generation (Claude) | 1200ms | Main bottleneck |
| E2B file write | 100ms | Fast, sandbox already running |
| Vite HMR | 200ms | Hot reload, not full rebuild |
| WebView update | 100ms | Client-side |
| **Total** | **2400ms** | Within budget |

**Why Sonnet 4.5 over Opus 4.5:**
- Opus 4.5 would add 2-3 seconds to code generation
- Sonnet 4.5 is optimized for coding tasks
- Quality difference is minimal for CRUD operations

**Optimizations for later:**
- Stream code generation to start writing files before completion
- Pre-warm Claude with project context
- Keep Vite dev server always running in sandbox

---

## Error Handling

**Principle: FAIL IS FAIL — No silent fallbacks**

All errors must:
1. Be surfaced to the user with clear message
2. Offer concrete recovery action
3. Be logged for debugging

### Error Categories

| Category | Example | Recovery |
|----------|---------|----------|
| **Voice** | Whisper API timeout | "I didn't catch that. Try again?" |
| **AI** | Claude rate limit | "I'm thinking too hard. Give me a moment." |
| **Sandbox** | E2B startup failed | "Preview isn't loading. Retrying..." |
| **Code** | Generated code has errors | "That didn't work. Let me try a different approach." |
| **Auth** | Session expired | Prompt re-authentication |

---

## MVP Scope

### In Scope

✅ Single user sessions (no collaboration)  
✅ One project at a time  
✅ CRUD dashboard generation  
✅ Voice input → code → preview loop  
✅ Basic commands: stop, undo, show code  
✅ Checkpoints and undo  
✅ Code inspection (read-only)  
✅ Error handling with recovery  

### Out of Scope (V2+)

❌ Multi-user collaboration  
❌ Multiple simultaneous projects  
❌ Custom tech stacks  
❌ Economic metrics / cost tracking  
❌ Offline mode  
❌ Export to GitHub  
❌ Advanced integrations (Stripe, etc.)  
❌ Claude Opus 4.5 for complex reasoning (use Sonnet for everything in MVP)

---

## Deployment

### Railway Setup

1. Create new Railway project
2. Add PostgreSQL database
3. Connect GitHub repo for auto-deploy
4. Set environment variables
5. Deploy

### Railway Configuration

```toml
# railway.toml
[build]
builder = "nixpacks"

[deploy]
startCommand = "npm run start"
healthcheckPath = "/api/health"
healthcheckTimeout = 30
```

---

## Cost Estimates

### Per-Unit Costs (December 2025)

| Service | Unit Cost | Notes |
|---------|-----------|-------|
| **Railway (Pro)** | $20/month base | Includes 8GB RAM, 8 vCPU |
| **PostgreSQL** | $10/month | Included in Railway |
| **Clerk** | Free tier | Up to 10,000 MAU |
| **OpenAI Whisper** | $0.006/minute | Audio processing |
| **Claude** | $3/1M input, $15/1M output | Code generation |
| **E2B Sandboxes** | $0.10/hour | Per active sandbox |

### Estimated Monthly Cost (100 Active Users)

Assumptions:
- 100 users, 10 minutes voice/day each
- ~50 code generation requests/user/day
- Average 2K input tokens, 4K output tokens per request
- 2 hours sandbox time per user per day

| Service | Calculation | Monthly Cost |
|---------|-------------|--------------|
| Railway | Base plan | $20 |
| PostgreSQL | Included | $0 |
| Clerk | Free tier | $0 |
| OpenAI Whisper | 100 × 10 min × 30 days × $0.006 | $18 |
| Claude Input | 100 × 50 × 30 × 2K tokens × $3/1M | $9 |
| Claude Output | 100 × 50 × 30 × 4K tokens × $15/1M | $90 |
| E2B | 100 × 2 hr × 30 days × $0.10 | $600 |
| **Total** | | **~$870/month** |

**Cost per active user: ~$8.70/month**

---

## Implementation Order

### Phase 1: Foundation (Week 1)
1. Project setup (TypeScript, Express, Prisma)
2. Railway deployment
3. Clerk authentication
4. WebSocket server with basic message handling
5. Database schema and migrations

### Phase 2: Voice Pipeline (Week 2)
1. OpenAI Whisper integration
2. Audio streaming (client → server)
3. Real-time transcription
4. TTS for agent responses

### Phase 3: AI Orchestration (Week 3)
1. Claude Sonnet 4.5 integration
2. Intent parsing
3. Code generation with context
4. Conversation history management

### Phase 4: Sandbox & Preview (Week 4)
1. E2B integration
2. Custom template (Next.js 15 + Tailwind 4 + Shadcn)
3. File operations
4. Dev server management
5. Preview URL delivery

### Phase 5: Polish (Week 5)
1. Checkpoint system
2. Undo functionality
3. Error handling
4. State machine refinement
5. End-to-end testing

---

## Open Questions

1. **TTS Integration**: Consider OpenAI TTS or ElevenLabs for agent voice responses
2. **E2B template**: Need to create custom template with pre-installed Next.js 15 stack
3. **iOS audio format**: Confirm audio format compatibility (PCM 16-bit, 16kHz)
4. **Clerk iOS SDK**: Verify WebSocket token flow works on iOS
5. **Sandbox persistence**: Strategy for handling 24h expiration (auto-recreate? warn user?)

---

## API Keys Required

| Service | Where to Get | Notes |
|---------|--------------|-------|
| Clerk | clerk.com | Free tier available |
| Anthropic (Claude) | console.anthropic.com | Requires approval |
| OpenAI | platform.openai.com | For Whisper STT |
| E2B | e2b.dev | Free tier available |

---

**Document Status:** Ready for implementation

**Next Steps:**
1. Get API keys (OpenAI, Claude, E2B, Clerk)
2. Set up Railway project
3. Create E2B template with Next.js 15 stack
4. Begin Phase 1 implementation

---

*Last Updated: 2025-12-31*
