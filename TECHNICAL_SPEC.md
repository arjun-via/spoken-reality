# Spoken Reality - Technical Specification

**Version:** 1.0
**Last Updated:** 2025-12-30
**Status:** Planning / Pre-Development

---

## Executive Summary

**Vision Statement:**
Voice-first mobile development environment that generates production-grade web apps in real-time.

**Core Principle:**
Output is primary. Agent is ambient. Code is invisible.

**The Problem:**
Current AI coding tools are fundamentally broken:
- **Code-lite tools** (Lovable, Replit, Bolt): Great for prototypes, collapse at production
- **AI-augmented IDEs** (Cursor, Windsurf, Copilot): Bolt AI onto old paradigms, still assume humans read/write/edit code
- **Desktop-first design**: Everything assumes keyboard + text editor, nothing designed for voice or mobile-native

**The Question:**
If code is invisible infrastructure, what does the interface even look like?

**The Answer:**
A mobile app where engineers speak their intentions, watch production-quality applications build in real-time, and export standard code to deploy anywhere.

---

## Product Overview

### Design Pillars

#### 1. 🎤 Voice-First Creation
- Speak intentions, not prompts
- Voice transcription via OpenAI Whisper
- Natural conversation, not commands
- Push-to-talk interaction model (reactive, not proactive)

#### 2. 📱 Mobile-Native Architecture
- Build from anywhere
- Single screen architecture (development environment, not output)
- Output is primary — live WebView updates
- Native iOS app (Swift)

#### 3. ⚡ Production-Grade from Day One
- Industrial strength architecture
- Proper error handling (FAIL IS FAIL - no silent fallbacks)
- Scalability built-in
- Engineers approve first — generated code must pass engineering review

### Target Audience

**Primary:** Engineers and technical users who understand production code

**Success Metric:** Engineer adoption rate (if engineers who understand production code approve and return, product succeeds)

**Go-to-Market Philosophy:** Win engineers first. If it satisfies those who know production code, it satisfies anyone.

---

## Technical Architecture

### System Architecture Overview

```
[iOS App (Swift)]
    ↓ (voice input)
[OpenAI Whisper]
    ↓ (transcription)
[Anthropic Claude]
    ↓ (code generation)
[E2B Sandbox]
    ↓ (Next.js dev server)
[WebView in iOS App]
```

**Data Flow:** Direct pipeline for minimal latency
- User voice input → OpenAI Whisper (speech-to-text)
- Transcription → Anthropic Claude (code generation)
- Generated code → E2B sandbox (Next.js dev server)
- Dev server → WebView with HMR (hot module replacement)
- WebView always interactive, updates stream in real-time

### Infographic Architecture

**Purpose:** Generate interactive repository visualizations for exploration

```
[iOS App]
    ↓ (GitHub URL)
[Backend /api/infographic/generate]
    ↓ (Cerebras API call)
[Cerebras GLM 4.7]
    ↓ (analysis + JSON)
[iOS App - Interactive View]
```

**Components:**
- **Input:** GitHub repository URL
- **AI Model:** Cerebras GLM 4.7 (fast, cost-effective)
- **Output:** Hierarchical JSON for iOS drill-down navigation
- **Features:** Pinch-to-zoom, search, code annotations, GitHub links
- **Cost:** ~$0.10 per repository analysis

### Infrastructure

#### Code Generation
- **Platform:** Centralized cloud service (standard SaaS architecture)
- **STT Model:** OpenAI Whisper (speech-to-text)
- **AI Model:** Anthropic Claude (code generation)
- **Latency Target:** Fast voice-to-visual-update

#### Development Environments
- **Type:** Persistent cloud project workspaces
- **Architecture:** Each project gets isolated environment (Vite dev server + PostgreSQL database)
- **State:** Environments persist between sessions
- **Cleanup:** Immediate deletion with export prompt on project deletion

#### Context Management
- **Strategy:** Infinite context via RAG (Retrieval Augmented Generation)
- **Storage:** Vector database stores conversation history only
- **Retrieval:** Relevant past conversation retrieved as needed when context exceeds model limits

---

## Technology Stack

### MVP Stack (Opinionated & Fixed)

**Frontend:**
- Next.js (React framework)
- Tailwind CSS (styling)
- Shadcn/UI (component library)

**Backend:**
- Next.js API Routes (serverless functions)
- Prisma (ORM)
- PostgreSQL (database)

**Development:**
- Vite dev server (HMR, fast refresh)
- Playwright (E2E testing from visual testing)

**Authentication:**
- Spoken Reality provides built-in auth service
- Integrated authentication solution (similar to Supabase/Clerk model)

**Secrets Management:**
- Read-only API access to password managers (1Password, Bitwarden)
- OAuth handshake for secure access
- System never stores raw secrets, only references

**Design System:**
- Single beautiful default theme (high quality, limited customization)
- Ensures consistent production-grade aesthetics

### Mobile Application

**Platform:** Native iOS only (Swift)
**Minimum Target:** iOS 16+
**Distribution:** TestFlight → App Store

---

## User Experience & Interface Design

### iOS App Interface

#### Primary View Layout
```
┌─────────────────────────┐
│                         │
│                         │
│      WebView            │
│    (fills screen)       │
│                         │
│                         │
│    [Floating Mic Btn]   │  ← Bottom-right corner
│                         │
└─────────────────────────┘
```

**Key Principles:**
- Output is truly primary: WebView occupies full screen
- Tap-and-hold floating mic button to speak
- Visual progress indicators during build operations (no verbal narration for quick changes)
- WebView remains interactive during updates (hot reload is seamless)

#### Navigation Structure

**Home Screen:**
- Visual project grid/list
- Tap to open project
- Standard iOS navigation patterns

**Project View:**
- WebView (frontend output) — default view
- Backend monitoring dashboard (accessible via tab/button)
- Code view (on-demand, accessible via menu)

#### Backend Monitoring Dashboard

**Type:** Database browser embedded in WebView
**Features:**
- View tables, rows, schema
- Inline editing of data
- Live database state during development
- Essentially a built-in admin panel

### Voice Interaction Model

#### Push-to-Talk Mechanics
- Hold floating mic button to record
- Release to submit
- Sub-second processing + visual update

#### Error Correction
- **Strategy:** Fast correction after the fact
- System executes immediately (optimistic execution)
- User sees wrong result, says "no, I meant X"
- Correction is faster than upfront confirmation

#### Conversation Features
- Natural language, not commands
- Agent is reactive, not proactive (only speaks when spoken to)
- No unsolicited suggestions or interruptions

### Debugging & Code Inspection

#### Default Mode: Code Invisible
- Users build by describing features, seeing results
- Code is infrastructure, not interface

#### On-Demand Code Access
- User can say "show me the code" anytime
- Code view overlay appears
- Engineers can inspect to build trust
- Critical for "engineers approve first" principle

#### Error Handling
- Code shown on-demand when debugging needed
- Clear error messages surfaced in UI
- "FAIL IS FAIL" policy: no silent fallbacks, explicit failures only

---

## Core Features & Capabilities

### Conversational Development

#### Version Control & History
- **Model:** Conversational checkpoints
- **Trigger:** Automatic after each complete feature
- **Usage:** User says "go back to before I added payments" - system restores checkpoint
- **Implementation:** Full state snapshots at each checkpoint

#### Iteration & Changes
- Forward-only corrections (user describes change, system applies)
- Intelligent full rebuild for major refactors
- System handles architectural changes ("switch from REST to GraphQL")

### Testing

#### Visual Testing
- Users interact with WebView normally
- Say "remember this as a test" while using app
- System records interactions as Playwright E2E tests
- Tests included in exported repository

#### Test Generation
- Automatic test generation from recorded interactions
- Production-grade test coverage from day one

### Schema & Database Management

#### Schema Evolution
- **Strategy:** Automatic migrations via Prisma
- Additive changes applied automatically
- System generates and applies migrations safely
- Data preservation during schema changes

#### Development Data
- Production data from start (no separate dev/test data)
- Users connect real data sources from beginning
- Realistic development environment

### Code Export & Deployment

#### Export Format
- Complete repository ready to clone
- Full Next.js repo structure
- package.json, .env.example, comprehensive README
- Proper git history maintained
- No vendor lock-in: standard code, deploy anywhere

#### Export Trigger
- User says "export to GitHub"
- System creates downloadable repository
- Code is production-ready Next.js application

#### Code Quality
- Production-grade from day one
- Proper architecture, error handling, security
- Engineers can inspect and approve quality
- **This is the biggest risk:** if generated code quality isn't excellent, trust breaks

---

## Development Workflow

### Typical User Session

1. **Open App** → Visual project list
2. **Select/Create Project** → WebView opens with current state
3. **Hold Mic Button** → Speak feature request
4. **Watch Updates** → Visual progress indicator, WebView updates live in <1 second
5. **Interact & Test** → Use the app directly in WebView
6. **Iterate** → Speak additional changes, system applies
7. **Test Recording** → Say "remember this as a test" during interaction
8. **Export** → Say "export to GitHub" when ready

### Key User Flows

#### First-Time User (Aha Moment)
- User opens app
- Says "create a product dashboard"
- Working dashboard appears in <10 seconds
- **This is the magic:** instant gratification proves the paradigm

#### Adding a Feature
```
User: "Add a search bar to the products table"
System: [Visual progress indicator]
WebView: [Search bar appears above table, functional immediately]
User: [Tests search, works correctly]
```

#### Debugging
```
User: "Why isn't the delete button working?"
System: [Inspects code, identifies issue]
System: "The delete API route is missing authorization. Should I add it?"
User: "Yes"
System: [Fixes and updates]
```

#### Exporting
```
User: "Export this to GitHub"
System: "I've prepared a complete Next.js repository. What should I name it?"
User: "product-dashboard"
System: [Creates download link]
System: "Repository ready. It includes all code, tests, README, and environment setup."
```

---

## MVP Scope & Roadmap

### MVP Definition: Single Template App Type

**App Type:** CRUD Dashboard / Admin Panel

**Rationale:**
- Proves production-grade capability
- Clear success criteria (can engineers build real tools?)
- Common business need (admin panels, internal tools)
- Complex enough to validate system

**MVP Capabilities:**

✅ **In Scope:**
- Voice-to-code for CRUD operations
- Database schema design via voice
- Table views with sorting/filtering
- Forms for create/edit operations
- Basic charts/visualizations
- Authentication (via built-in SR auth service)
- Visual testing (Playwright)
- Code export to GitHub
- Backend database browser
- Conversational checkpoints
- On-demand code inspection
- Sub-second voice latency

❌ **Explicitly Out of Scope (V1):**
- Real-time multiplayer/gaming applications
- Blockchain/web3 applications
- Native mobile apps (iOS/Android native)
- Multi-user collaboration (single-player only)
- Custom tech stacks (opinionated stack only)
- Advanced integrations (can add, but not focus)

### Technical Risks

#### Highest Priority Risk
**Generated code quality isn't production-grade**

**Mitigation:**
- Extensive testing of generated code patterns
- Engineer review of common patterns before launch
- Focus on narrow use case (CRUD dashboards) to ensure quality
- Allow code inspection to build trust
- Open source parts of generated code for transparency

#### Other Risks
- Voice transcription latency/quality (backup: text input fallback)
- Voice UX breakdown for complex apps (backup: on-demand code access)
- Cultural resistance to code invisibility (backup: trust-building via inspection)

---

## Go-to-Market Strategy

### Primary Tactics

#### 1. Direct Outreach to Engineering Teams
- Target CTOs and engineering managers at startups
- Offer personalized demos to teams
- Pilot programs with early adopters
- Focus on teams building internal tools

#### 2. GitHub Presence + Open Source
- Open source parts of the generated code templates
- Showcase code quality publicly
- Build trust through transparency
- Demonstrate production-grade output

### Launch Strategy

**Phase 1: Private Alpha**
- Hand-selected engineers (10-20)
- Focus on feedback and iteration
- Validate generated code quality
- Refine voice UX

**Phase 2: Invite-Only Beta**
- Expand to 100-200 engineers
- TestFlight distribution
- Community building (Discord/Slack)
- Case studies from early adopters

**Phase 3: Public Launch**
- App Store release
- Content marketing (technical blog posts)
- Developer community presence (Twitter/X, HN)

---

## Advanced Features & Capabilities

### Performance Optimization
- **Strategy:** Automatic optimization only
- System handles code splitting, caching, lazy loading
- Users don't think about performance
- Production-grade performance built-in

### Unknown Integrations
- **Strategy:** Agent learns in real-time
- User requests integration with unknown service/package
- System researches documentation on the fly
- Incorporates new integrations during conversation

### Dependency Management
- **Strategy:** Automatic updates, system handles breaking changes
- Dependencies update automatically
- Agent refactors code for breaking changes without user involvement
- Security patches auto-apply

### Secret Management (Production)
- Integration with password managers (1Password, Bitwarden)
- Read-only API access via OAuth
- User says "use my Stripe API key"
- System pulls from vault securely

### Latency Fallback
- **Primary:** OpenAI Whisper (fast transcription)
- **Fallback:** Text input when voice unavailable/slow
- Graceful degradation without breaking workflow

---

## Success Metrics & KPIs

### Primary Metric
**Engineer Adoption Rate**
- % of engineers who use once and return
- If engineers approve and come back, product succeeds

### Secondary Metrics
- Time from idea to first working app
- Time from start to production deployment
- Code quality scores (automated analysis)
- Test coverage of generated applications
- Engineer satisfaction with code quality
- Projects exported to GitHub

### Validation Criteria (MVP Success)
- 50+ engineers build real CRUD dashboards
- 80%+ return within 7 days
- 5+ projects exported and deployed to production
- Generated code passes code review standards
- Sub-second voice-to-visual latency achieved

---

## Open Questions & Future Considerations

### Post-MVP Considerations

**Multi-User Collaboration:**
- Real-time multi-voice sessions
- Code review workflows
- Team project management

**Additional App Types:**
- Landing pages + marketing sites
- E-commerce platforms
- Internal tools beyond CRUD
- API-first applications

**Platform Expansion:**
- Android version (React Native or native)
- Desktop companion app
- Web version for accessibility

**Tech Stack Flexibility:**
- Support for alternative frameworks (Remix, SvelteKit)
- Pluggable backend options (Supabase, Firebase)
- User choice vs maintained quality

---

## Appendix: Technical Decisions Summary

| Category | Decision | Rationale |
|----------|----------|-----------|
| **Voice STT** | OpenAI Whisper | Industry standard, high accuracy, cost-effective |
| **AI Model** | Anthropic Claude | Best code generation quality |
| **Mobile Platform** | Native iOS (Swift) | Fastest to TestFlight, best performance, Apple-first strategy |
| **Frontend Stack** | Next.js + Tailwind + Shadcn/UI | Industry standard, production-grade, great DX |
| **Backend Stack** | Next.js API + Prisma + PostgreSQL | Integrated full-stack, type-safe, scales well |
| **Dev Environment** | Vite dev server in cloud | Fast HMR, persistent workspaces |
| **Testing** | Playwright (visual recording) | Modern, reliable, Next.js-native |
| **Context Strategy** | RAG with vector DB | Infinite conversation history |
| **Version Control** | Conversational checkpoints | Natural for voice-first interface |
| **Code Export** | Complete Git repository | No lock-in, standard deployment |
| **Auth** | Built-in SR auth service | Faster MVP, better integration |
| **Design System** | Single opinionated theme | Quality over flexibility |
| **MVP App Type** | CRUD Dashboard | Proves production capability |

---

## Implementation Priorities

### Phase 0: Foundation (Pre-MVP)
1. iOS app shell with WebView + mic button
2. OpenAI Whisper integration for voice transcription
3. Basic code generation pipeline (Next.js scaffold)
4. E2B sandbox provisioning
5. Vite dev server deployment

### Phase 1: Core Loop
1. Voice → code → WebView update flow
2. Conversational checkpoint system
3. On-demand code inspection
4. Basic CRUD generation (models, routes, UI)

### Phase 2: Production Features
1. Built-in authentication service
2. Database browser in WebView
3. Visual testing + Playwright generation
4. Code export to GitHub

### Phase 3: Polish & Launch
1. Error handling and debugging UX
2. Automatic migrations
3. Password manager integration
4. Onboarding flow
5. Alpha testing with engineers

---

**Document Status:** Complete and ready for development planning

**Next Steps:**
1. Technical architecture deep-dive
2. iOS app wireframes and design
3. Voice API evaluation and testing
4. Infrastructure cost modeling
5. Alpha tester recruitment plan
