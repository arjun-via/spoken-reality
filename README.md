# Spoken Reality

**Tagline:** "Speak it. Build it. Ship it."

A voice-first, mobile-native development environment where users speak their intentions and production-grade applications are built in real-time.

## Overview

Spoken Reality is a revolutionary coding platform that prioritizes voice interaction over traditional text-based development. The system consists of:

- **iOS App** (SpokenRealityApp): Native SwiftUI app for iPhone/iPad
- **Backend** (via-backend): Node.js/Express server on Railway with WebSocket support
- **E2B Sandboxes**: Ephemeral cloud VMs for running generated Next.js applications

## Core Principles

1. **Voice-First Creation**: Speak intentions, not prompts (sub-second latency via Grok Voice API)
2. **Mobile-Native Architecture**: Build from anywhere with single-screen design
3. **Output is Primary**: Live WebView updates, code is invisible until you want to see it
4. **Production-Grade from Day One**: Industrial strength architecture, proper error handling

## Architecture

### iOS App (`SpokenRealityApp/`)
- **Language**: Swift 6.0, SwiftUI
- **Deployment Target**: iOS 17.0+
- **Features**:
  - Voice input with audio recording
  - Real-time WebSocket communication
  - Live preview via WKWebView
  - Code inspection
  - Git status view
  - Database browser
  - Settings & onboarding

### Backend (`via-backend/`)
- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js
- **Hosting**: Railway (Production)
- **Features**:
  - WebSocket server for real-time communication
  - Claude AI integration for code generation
  - E2B sandbox management
  - Sandbox pre-warming for fast first builds
  - Session management
  - Checkpoint system

### Key Technologies
- **Voice**: Grok Voice API (planned)
- **AI**: Anthropic Claude (Claude Agent SDK)
- **Sandboxes**: E2B Code Interpreter
- **Generated Apps**: Next.js 15 + React 19 + Tailwind CSS
- **Deployment**: Railway for backend, TestFlight for iOS

## Getting Started

### Prerequisites
- Xcode 16.2+ (for iOS development)
- Node.js 18+ (for backend)
- Railway account (for deployment)
- Apple Developer account (for iOS testing)

### Backend Setup

1. Navigate to backend directory:
```bash
cd via-backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```env
ANTHROPIC_API_KEY=your_key_here
E2B_API_KEY=your_key_here
PORT=3000
```

4. Build and run:
```bash
npm run build
npm start
```

### iOS App Setup

1. Open the Xcode project:
```bash
open SpokenRealityApp/SpokenRealityApp.xcodeproj
```

2. Update `WebSocketService.swift` with your backend URL

3. Build and run on device or simulator

## Project Structure

```
.
├── README.md                    # This file
├── CLAUDE.md                    # AI assistant guidance
├── PROJECT_STATUS.md            # Current project state
├── TECHNICAL_SPEC.md           # Detailed technical specification
│
├── SpokenRealityApp/           # iOS Application
│   ├── SpokenRealityApp/
│   │   ├── App/                # App entry point
│   │   ├── Core/               # Reusable components & theme
│   │   ├── Features/           # Feature modules
│   │   ├── Models/             # Data models
│   │   └── Services/           # Services (WebSocket, Audio)
│   └── SpokenRealityApp.xcodeproj/
│
└── via-backend/                # Backend Server
    ├── src/
    │   ├── config/             # Configuration
    │   ├── routes/             # HTTP routes
    │   ├── services/           # Core services
    │   ├── utils/              # Utilities
    │   └── ws/                 # WebSocket handlers
    ├── package.json
    └── tsconfig.json
```

## Features

### Current
- ✅ Voice command recording
- ✅ Real-time code generation via Claude
- ✅ Live Next.js preview in WebView
- ✅ Code inspection with syntax highlighting
- ✅ Sandbox pre-warming for fast builds
- ✅ Session persistence
- ✅ Auto-retry and error handling

### Planned
- ⏳ Grok Voice API integration
- ⏳ Real-time streaming narrative updates
- ⏳ Multi-turn conversation context
- ⏳ Git integration (commit/push)
- ⏳ Database integration
- ⏳ Collaborative features

## Deployment

### Backend (Railway)
The backend auto-deploys from `main` branch on GitHub.

### iOS (TestFlight)
1. Archive the app in Xcode
2. Distribute to App Store Connect
3. Submit for TestFlight testing

## Development Guidelines

See `CLAUDE.md` for AI assistant guidelines including:
- Error handling policy (FAIL IS FAIL)
- Code quality standards
- File management rules
- Documentation requirements

## License

Proprietary - All rights reserved

## Contact

Project Owner: Arjun Divecha
