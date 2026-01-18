# Spoken Reality - Implementation Plan

**Version:** 1.0
**Last Updated:** 2025-12-30
**Timeline:** Estimated 12-16 weeks to MVP

**⚠️ Note:** This plan is historical. See `PROJECT_STATUS.md` for current implementation status as of January 2026. The core features have been implemented and the app is in beta testing.

---

## Overview

This plan breaks down the implementation of Spoken Reality into **5 major phases**, from design through launch. Each phase includes specific deliverables, dependencies, and success criteria.

---

## Phase 0: Design & Architecture (Weeks 1-2)

**Goal:** Complete visual design and finalize technical architecture before writing code.

### 0.1 Figma Design System (Week 1)

#### Design Deliverables

**Project Setup:**
- [ ] Create Figma project: "Spoken Reality - iOS App"
- [ ] Set up design system library
- [ ] Define color palette (based on presentation: dark backgrounds, #FF6B4A accent)
- [ ] Define typography scale (SF Pro for iOS native feel)
- [ ] Create component library (buttons, inputs, cards, etc.)

**Screen Designs (High-Fidelity):**

1. **Home / Project List Screen**
   - [ ] Empty state (first-time user)
   - [ ] Project grid/list view
   - [ ] Project card design (thumbnail, title, last edited)
   - [ ] Navigation bar with "New Project" button
   - [ ] Pull-to-refresh interaction

2. **Project Creation Flow**
   - [ ] "New Project" modal/sheet
   - [ ] Project name input screen
   - [ ] Initial template selection (for post-MVP, show single option grayed out)

3. **Main Development View**
   - [ ] Full-screen WebView layout
   - [ ] Floating mic button (bottom-right)
   - [ ] Mic button states: idle, recording, processing
   - [ ] Visual progress indicator (subtle top bar or overlay)
   - [ ] Tab bar for Output/Database views

4. **Voice Interaction States**
   - [ ] Mic button pressed (hold-to-talk state)
   - [ ] "Listening..." indicator
   - [ ] "Processing..." state
   - [ ] Error states (voice failed, network error)

5. **Backend Monitoring Dashboard**
   - [ ] Database browser table view
   - [ ] Table row detail view
   - [ ] Schema view
   - [ ] Empty states

6. **Code Inspection View**
   - [ ] Code viewer with syntax highlighting
   - [ ] File tree navigation
   - [ ] Search functionality
   - [ ] "Back to Output" button

7. **Settings & Export**
   - [ ] Project settings screen
   - [ ] Export to GitHub flow
   - [ ] Delete project confirmation

8. **Onboarding (Minimal)**
   - [ ] First-launch permissions screen (microphone)
   - [ ] Optional: Quick tip overlay on first project

#### Design Specifications
- [ ] Create iOS design specs (spacing, sizing, safe areas)
- [ ] Interaction prototypes in Figma (mic button, tab switching)
- [ ] Accessibility considerations (VoiceOver labels)
- [ ] Dark mode only (matches brand)

#### Deliverable
- [ ] Complete Figma file with all screens
- [ ] Design system documentation
- [ ] Prototype for key flows
- [ ] Export assets for iOS development

---

### 0.2 Technical Architecture Deep-Dive (Week 1-2)

**Backend Architecture:**
- [ ] Design cloud infrastructure diagram
- [ ] Define API endpoints and contracts
- [ ] Plan database schema for user projects
- [ ] Design workspace provisioning system
- [ ] Plan Vite dev server deployment architecture
- [ ] Security model (authentication, workspace isolation)

**iOS Architecture:**
- [ ] Define app architecture (MVVM, TCA, or SwiftUI + Combine)
- [ ] Plan local data persistence (CoreData vs SQLite)
- [ ] Design networking layer
- [ ] Plan WebView integration approach
- [ ] Audio recording & Grok API integration strategy

**Integration Points:**
- [ ] Grok Voice API evaluation and testing
- [ ] Code generation pipeline design
- [ ] WebView ↔ Native communication protocol
- [ ] Real-time update mechanism (WebSocket vs polling)

#### Deliverables
- [ ] Architecture documentation (diagrams + decisions)
- [ ] API specification (OpenAPI/Swagger)
- [ ] Database schema ERD
- [ ] Technology selection confirmation

---

### 0.3 Development Environment Setup (Week 2)

**iOS Setup:**
- [ ] Create Xcode project (Swift, iOS 16+)
- [ ] Set up project structure (folders, groups)
- [ ] Configure Swift Package Manager dependencies
- [ ] Set up linting (SwiftLint)
- [ ] Configure CI/CD (GitHub Actions for builds)

**Backend Setup:**
- [ ] Choose cloud provider (AWS, GCP, or fly.io/Railway)
- [ ] Set up staging environment
- [ ] Configure PostgreSQL database (managed service)
- [ ] Set up Node.js/TypeScript backend service
- [ ] Configure environment variables and secrets
- [ ] Set up monitoring (logs, errors, metrics)

**Development Tools:**
- [ ] Local development workflow (how to run backend locally)
- [ ] API mocking for iOS development
- [ ] TestFlight setup for distribution

#### Deliverables
- [ ] iOS app builds successfully
- [ ] Backend deploys to staging
- [ ] CI/CD pipeline functional
- [ ] Development documentation (README)

---

## Phase 1: Foundation (Weeks 3-5)

**Goal:** Build the basic iOS app shell and establish core infrastructure.

### 1.1 iOS App Shell (Week 3)

**Home Screen:**
- [ ] Implement navigation structure (SwiftUI NavigationStack)
- [ ] Build project list view
- [ ] Implement empty state UI
- [ ] Add "New Project" flow (stub for now)
- [ ] Local project data model (CoreData/SQLite)

**Basic WebView:**
- [ ] Integrate WKWebView
- [ ] Full-screen layout with safe area handling
- [ ] Basic URL loading (test with example.com)
- [ ] Handle loading states

**Floating Mic Button:**
- [ ] Create custom mic button component
- [ ] Position in bottom-right corner
- [ ] Basic touch handlers (tap, hold)
- [ ] Animation states (idle, active, processing)

#### Deliverable
- [ ] iOS app with basic navigation and WebView
- [ ] Can create and view projects (local only)
- [ ] Mic button UI complete (no functionality yet)

---

### 1.2 Voice Input Integration (Week 4)

**Microphone Permissions:**
- [ ] Request microphone access
- [ ] Handle permission denied state
- [ ] Microphone permission UI/UX

**Audio Recording:**
- [ ] Implement AVAudioRecorder integration
- [ ] Record while mic button is held
- [ ] Stop recording on release
- [ ] Audio file management (temp storage)

**Grok Voice API Integration:**
- [ ] Sign up for Grok API access
- [ ] Implement API client (Swift)
- [ ] Send audio file to Grok
- [ ] Receive transcription + response
- [ ] Handle API errors and retries

**Basic Voice Flow:**
- [ ] User holds mic → record audio
- [ ] Release → upload to Grok
- [ ] Display "Processing..." indicator
- [ ] Show response (text overlay for now)

#### Deliverable
- [ ] Voice recording works end-to-end
- [ ] Grok API integration functional
- [ ] Basic voice → text → response flow

---

### 1.3 Backend Infrastructure (Week 5)

**User Authentication:**
- [ ] Implement Spoken Reality auth service
- [ ] User registration endpoint
- [ ] Login endpoint (email/password or magic link)
- [ ] JWT token generation and validation
- [ ] iOS authentication flow

**Project Management API:**
- [ ] Create project endpoint
- [ ] List projects endpoint
- [ ] Get project details endpoint
- [ ] Delete project endpoint
- [ ] Project database schema

**Workspace Provisioning:**
- [ ] Design workspace allocation system
- [ ] Create Vite dev server template
- [ ] Implement workspace creation
- [ ] Basic Next.js scaffold generation
- [ ] Workspace cleanup on delete

#### Deliverable
- [ ] Backend API functional
- [ ] User can register, login, create projects
- [ ] Projects stored in cloud database
- [ ] Basic workspace provisioning works

---

## Phase 2: Core Loop (Weeks 6-9)

**Goal:** Implement the voice → code → WebView update loop.

### 2.1 Code Generation Pipeline (Week 6)

**Grok Integration for Code:**
- [ ] Design prompt engineering for code generation
- [ ] Test Grok's ability to generate Next.js code
- [ ] Implement code generation endpoint
- [ ] Handle streaming responses (if available)
- [ ] Code validation and error handling

**Next.js Template:**
- [ ] Create base Next.js project structure
- [ ] Include Prisma + PostgreSQL setup
- [ ] Include Tailwind + Shadcn/UI
- [ ] Configure for Vite dev server
- [ ] Environment variable management

**File System Management:**
- [ ] Implement file CRUD operations
- [ ] Safe file writing (atomic operations)
- [ ] File tree representation
- [ ] Git integration (automatic commits)

#### Deliverable
- [ ] Grok can generate Next.js code from voice
- [ ] Code is written to workspace file system
- [ ] Basic validation prevents broken code

---

### 2.2 WebView Live Updates (Week 7)

**Vite Dev Server Integration:**
- [ ] Deploy Vite dev server per workspace
- [ ] Configure HMR (Hot Module Replacement)
- [ ] Expose dev server URL to iOS app
- [ ] Handle dev server lifecycle (start, stop, restart)

**iOS WebView Updates:**
- [ ] Load dev server URL in WebView
- [ ] Implement WebSocket connection for updates
- [ ] Handle HMR events from Vite
- [ ] Auto-refresh on code changes
- [ ] Loading states during updates

**Progress Indicators:**
- [ ] Visual progress bar during code generation
- [ ] Subtle animation during updates
- [ ] Error state UI

#### Deliverable
- [ ] Voice → Grok → Code → WebView pipeline works
- [ ] WebView updates automatically when code changes
- [ ] Sub-second updates for simple changes

---

### 2.3 Basic CRUD Generation (Week 8-9)

**CRUD Pattern Recognition:**
- [ ] Prompt engineering for CRUD operations
- [ ] Generate Prisma schema from voice
- [ ] Generate database migrations
- [ ] Generate API routes (Next.js API)
- [ ] Generate UI components (tables, forms)

**Database Integration:**
- [ ] PostgreSQL database per workspace
- [ ] Prisma migration execution
- [ ] Seed data generation
- [ ] Database connection management

**Testing CRUD Generation:**
- [ ] Test: "Create a products table with name and price"
- [ ] Test: "Add a form to create new products"
- [ ] Test: "Show all products in a table"
- [ ] Test: "Add delete functionality"

#### Deliverable
- [ ] Can generate complete CRUD dashboards via voice
- [ ] Database schema + migrations working
- [ ] Basic CRUD operations functional

---

## Phase 3: Production Features (Weeks 10-12)

**Goal:** Add authentication, testing, export, and monitoring.

### 3.1 Authentication System (Week 10)

**Built-in Auth Service:**
- [ ] Implement user registration UI in generated apps
- [ ] Implement login UI in generated apps
- [ ] Session management (JWT)
- [ ] Protected routes in generated apps
- [ ] Password reset flow

**Code Generation for Auth:**
- [ ] Prompt patterns for "add authentication"
- [ ] Generate auth pages automatically
- [ ] Generate protected API routes
- [ ] Generate user profile pages

#### Deliverable
- [ ] Can say "add authentication" and get full auth system
- [ ] Generated apps have functional login/register

---

### 3.2 Backend Monitoring Dashboard (Week 11)

**Database Browser:**
- [ ] Fetch database schema via API
- [ ] Display tables in iOS app
- [ ] Table row list view
- [ ] Row detail view (editable)
- [ ] Create/update/delete rows from iOS

**iOS Database Browser UI:**
- [ ] Tab bar for Output vs Database views
- [ ] Table selection screen
- [ ] Row list with search/filter
- [ ] Row edit modal
- [ ] Schema visualization

#### Deliverable
- [ ] Can switch to Database tab and browse data
- [ ] Can edit data directly from iOS app

---

### 3.3 Visual Testing & Export (Week 12)

**Visual Testing:**
- [ ] Implement interaction recording
- [ ] User says "remember this as a test"
- [ ] Record WebView interactions
- [ ] Generate Playwright test code
- [ ] Include tests in exported repo

**Code Export:**
- [ ] Implement "export to GitHub" flow
- [ ] Generate complete repository structure
- [ ] Include README with setup instructions
- [ ] Include .env.example
- [ ] Create downloadable ZIP
- [ ] (Optional) Direct GitHub repo creation via API

**Code Inspection:**
- [ ] Add code viewer to iOS app
- [ ] Syntax highlighting
- [ ] File tree navigation
- [ ] "Show me the code" voice command

#### Deliverable
- [ ] Visual testing records interactions
- [ ] Can export complete, runnable repository
- [ ] Code inspection view functional

---

## Phase 4: Conversational Features (Week 13)

**Goal:** Implement checkpoints, context management, and iteration.

### 4.1 Conversational Checkpoints

**Checkpoint System:**
- [ ] Detect feature completion
- [ ] Create automatic checkpoints
- [ ] Store checkpoint metadata (timestamp, description)
- [ ] Snapshot workspace state (code + database)

**Checkpoint Restoration:**
- [ ] "Go back to before I added X" command
- [ ] Restore code state from checkpoint
- [ ] Restore database state (if needed)
- [ ] Show checkpoint history

**RAG Implementation:**
- [ ] Set up vector database (Pinecone, Weaviate, or pgvector)
- [ ] Vectorize conversation history
- [ ] Store conversation + context
- [ ] Retrieve relevant history for context

#### Deliverable
- [ ] Automatic checkpoints after each feature
- [ ] Can restore to previous checkpoint via voice
- [ ] Conversation history persists

---

## Phase 5: Polish & Launch (Weeks 14-16)

**Goal:** Error handling, onboarding, testing, and launch preparation.

### 5.1 Error Handling & Edge Cases (Week 14)

**Error Handling:**
- [ ] Voice API failure handling
- [ ] Code generation failure (invalid syntax)
- [ ] Workspace creation failures
- [ ] Network error handling
- [ ] Rate limiting and quotas

**Text Input Fallback:**
- [ ] Add text input option
- [ ] Keyboard appears when voice unavailable
- [ ] Same processing pipeline for text

**Edge Cases:**
- [ ] App backgrounding during voice recording
- [ ] Dev server crashes
- [ ] Database connection failures
- [ ] Long operations (timeout handling)

#### Deliverable
- [ ] Robust error handling throughout app
- [ ] Graceful degradation for all failure modes

---

### 5.2 Onboarding & UX Polish (Week 15)

**Minimal Onboarding:**
- [ ] Microphone permission request screen
- [ ] Quick tip overlay (optional)
- [ ] First project creation guidance

**UX Improvements:**
- [ ] Smooth animations and transitions
- [ ] Haptic feedback for mic button
- [ ] Loading states polish
- [ ] Empty states for all screens
- [ ] Accessibility labels (VoiceOver)

**Performance Optimization:**
- [ ] WebView memory management
- [ ] Image optimization
- [ ] Reduce app bundle size
- [ ] Network request optimization

#### Deliverable
- [ ] Polished, production-ready UX
- [ ] Smooth onboarding experience
- [ ] Performance optimized

---

### 5.3 Testing & Launch Prep (Week 16)

**Testing:**
- [ ] Unit tests for critical paths
- [ ] Integration tests (API)
- [ ] E2E tests (iOS UI)
- [ ] Load testing (workspace provisioning)
- [ ] Security audit

**Alpha Testing:**
- [ ] Recruit 10-20 engineers for alpha
- [ ] TestFlight distribution
- [ ] Collect feedback
- [ ] Fix critical bugs
- [ ] Iterate on UX

**Launch Preparation:**
- [ ] App Store assets (screenshots, description)
- [ ] App Store review preparation
- [ ] Marketing website (landing page)
- [ ] Documentation (help docs)
- [ ] Privacy policy and terms of service

**Monitoring & Analytics:**
- [ ] Set up error tracking (Sentry)
- [ ] Set up analytics (Mixpanel/Amplitude)
- [ ] Performance monitoring
- [ ] Usage metrics dashboard

#### Deliverable
- [ ] Alpha tested and validated
- [ ] App Store ready
- [ ] Monitoring in place
- [ ] Launch plan finalized

---

## Phase 6: Launch & Iteration (Week 17+)

### Public Launch

**App Store Launch:**
- [ ] Submit to App Store review
- [ ] Launch announcement (Twitter/X, HN, communities)
- [ ] Direct outreach to target engineers
- [ ] Press outreach (TechCrunch, Product Hunt)

**Post-Launch:**
- [ ] Monitor crash reports and errors
- [ ] Respond to user feedback
- [ ] Weekly iterations based on usage data
- [ ] Community building (Discord server)

**Success Metrics Tracking:**
- [ ] Track engineer adoption rate
- [ ] Monitor projects created
- [ ] Monitor projects exported
- [ ] Track retention (7-day, 30-day)
- [ ] Collect NPS scores

---

## Resource Requirements

### Team Structure (Suggested)

**Minimum Team:**
- 1x iOS Engineer (Swift/SwiftUI)
- 1x Backend Engineer (Node.js/TypeScript)
- 1x Product Designer (Figma)
- 1x Product Manager / Founder (you)

**Ideal Team:**
- 1x Senior iOS Engineer
- 1x Senior Backend Engineer
- 1x ML/AI Engineer (Grok integration, prompt engineering)
- 1x Product Designer
- 1x Product Manager

### Technology Stack Summary

**iOS:**
- Swift 5.9+
- SwiftUI
- Combine
- WKWebView
- AVFoundation (audio)

**Backend:**
- Node.js + TypeScript
- Express or Fastify
- Prisma ORM
- PostgreSQL
- Redis (caching)
- Docker (workspace isolation)

**Infrastructure:**
- Cloud provider (AWS/GCP/Fly.io)
- Vector database (Pinecone or pgvector)
- CDN (CloudFlare)
- CI/CD (GitHub Actions)

**External APIs:**
- Grok Voice API
- (Optional) GitHub API for direct repo creation

---

## Risk Mitigation

### Top Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Grok API doesn't meet quality bar | Medium | Critical | Early testing in Phase 0; have backup plan for Claude/GPT-4 |
| Generated code quality issues | High | Critical | Extensive testing, human review, open source templates |
| Voice UX doesn't scale | Medium | High | Text input fallback, code inspection on-demand |
| Workspace provisioning too slow | Medium | Medium | Optimize infrastructure, use faster cloud providers |
| iOS App Store rejection | Low | High | Follow guidelines strictly, prepare for review |
| Security vulnerabilities | Medium | Critical | Security audit, penetration testing |

---

## Success Criteria (MVP)

**Technical:**
- ✅ Sub-second voice-to-visual latency achieved
- ✅ Can generate working CRUD dashboard from voice
- ✅ Generated code is production-grade (passes engineer review)
- ✅ Can export complete, runnable Next.js repository
- ✅ App works smoothly on iPhone (iOS 16+)

**Business:**
- ✅ 50+ engineers use the app
- ✅ 10+ projects exported and deployed to production
- ✅ 80%+ of engineers return within 7 days
- ✅ Average rating 4.5+ stars
- ✅ Engineers voluntarily share on Twitter/communities

---

## Next Steps

1. **Immediate (This Week):**
   - [ ] Start Figma designs (Phase 0.1)
   - [ ] Evaluate Grok Voice API (sign up, test)
   - [ ] Decide on cloud provider
   - [ ] Assemble team (if not solo)

2. **Week 2:**
   - [ ] Complete Figma designs
   - [ ] Finalize architecture decisions
   - [ ] Set up development environments

3. **Week 3:**
   - [ ] Begin Phase 1 implementation
   - [ ] Start with iOS app shell

---

**End of Implementation Plan**

This plan is a living document and should be updated as implementation progresses and new information emerges.
