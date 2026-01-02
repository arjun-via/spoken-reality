# Via: Spoken Reality — Project Context

*Last updated: December 31, 2025*

---

## Core Vision

**Via** is a voice-first, mobile-native application that lets users build software—websites, systems, full production applications—by describing what they want, not how to code it.

**Tagline:** "Speak it. Build it. Ship it."

**Framework:** "Spoken Reality" — Your ability to verbalize a concept becomes reality through AI-mediated creation.

### Key Differentiators

- **Industrial-strength from day one** — Not a prototype tool like Lovable or Bolt. Production-grade systems, proper architecture, error handling, scalability.
- **Mobile-native** — Not a desktop tool adapted for mobile. Designed from scratch for mobile constraints and affordances.
- **Voice-first** — Speech is the primary interface. Not typing prompts, but speaking intentions. "Add rate limiting to auth" not `/add-rate-limiting auth`.
- **Code invisible** — Code only surfaces on explicit request. It's infrastructure, like the engine in a car. Users interact with intent and outcomes.

### Unoccupied Market Position

The intersection of **voice-first + mobile-native + code-invisible + production-grade** has no serious competitor:

- Lovable/Bolt/v0 = code-lite, tops out at prototypes
- Cursor/Claude Code = code-centric power tools, still assume humans edit text
- No one combines all four principles

---

## Product Vision: Conductor

**The real unlock:** This isn't just an app builder. It's a **role transformation engine** for serious engineers.

### The Insight

Senior software engineers are **architects trapped laying bricks**. They have the experience, judgment, and system-thinking ability to operate at architecture level, but they're stuck in implementation:

- Only 2.3 hours per day of focused work due to meetings and context switching
- Debugging line-by-line instead of system thinking
- Context locked in their heads
- Can't operate at the level they've earned

### The Vision

Transform them from **coders to conductors**:

- Speak intent instead of writing code
- Diagnose system behavior instead of debugging line-by-line
- Ask and be told instead of reading code to understand
- Direct evolution instead of laying bricks

The AI is the **first chair** — technically excellent, capable of independent execution, following your direction.

### Market Strategy

**Start with serious engineers to prove production quality, then expand to general users.**

Why this works:

- Forces the system to be genuinely industrial-grade
- Engineers understand what production code looks like
- If it satisfies engineers, it satisfies anyone
- Earn credibility with the hard audience first

### Unified Product (Vibe Coding + System Evolution)

Both vibe coders and senior engineers are doing the same activity: **conducting AI to manifest their intent.**

|                    | Vibe Coder                | Senior Engineer             |
| ------------------ | ------------------------- | --------------------------- |
| **Starting point** | Idea                      | Existing system             |
| **Primary action** | "Build me a landing page" | "Add rate limiting to auth" |
| **AI role**        | Build it                  | Evolve it                   |
| **Evaluation**     | Does it work?             | Did it break anything?      |
| **Interaction**    | Describe what I want      | Describe what should change |

Same interface. Same conductor relationship. Same dialogue-driven interaction.

A vibe coder who succeeds becomes a senior engineer maintaining a system. The tool grows with them.

---

## UI Architecture

### Core Principle

**Output is primary. Agent is ambient. Code is invisible.**

### Single Screen with Three Layers

No navigation between separate views. Everything on one screen with layered interactions:

```
┌─────────────────────────────────────────┐
│                                         │
│            THE STAGE/OUTPUT             │
│     (Adaptive visualization of          │
│      what you're conducting)            │
│                                         │
├─────────────────────────────────────────┤
│  ◉ Agent status   Agent is working  🎤  │
│              THE PODIUM                 │
│          (Command interface)            │
└─────────────────────────────────────────┘
```

#### Layer 1: The Stage (Adaptive Output)

What you're conducting, visualized in the most useful form for the current task:

1. **Landscape View** — Mission view of the whole system
   - Services, components, connections, health status
   - Recent changes feed
   - Economic metrics (cost, tokens, latency)
   - Touch point to navigate and zoom

2. **Component View** — Zoomed into specific area
   - The piece currently being modified
   - Related dependencies
   - Change history for this component

3. **Live Preview** — For new app building
   - WebView showing the live application
   - Real-time updates as agent works
   - Tap to interact and test

4. **Code View** — On demand, read-only
   - The actual implementation as evidence
   - Shows what the agent built
   - Pulled up by "Show me the code"

#### Layer 2: The Podium (Agent Bar)

Persistent bottom bar, always visible:

- **State indicator** (listening/working/done/error)
- **One-line status** (current action)
- **Mic button** with waveform visualization
- **Expandable** for full conversation history and action items

**Expanded state shows:**

- Conversation history (user → agent → action items)
- Current task breakdown
- Live action items with progress

**Key design principle:** Agent is present but not dominant. Never interrupts output view.

#### Layer 3: Sheets (On Demand)

Slide up over output when needed:

- **Code sheet** — "Show me the code"
- **History sheet** — "What did you do?"
- **Settings** — Configuration

---

## Agent State Machine

Seven core states with defined transitions:

| State            | Visual                   | Purpose                             | Duration          |
| ---------------- | ------------------------ | ----------------------------------- | ----------------- |
| **IDLE**         | Soft pulsing glow        | Ready, listening for input          | Variable          |
| **LISTENING**    | Pulsing green + waveform | Capturing user speech               | <10s              |
| **INTERPRETING** | Spinning arc             | Parsing intent                      | <1s for simple    |
| **CLARIFYING**   | Question mark            | Agent needs more info               | User responds     |
| **PLANNING**     | Spinning arc             | Breaking down task                  | 0.5-2s            |
| **EXECUTING**    | Progress ring            | Writing code, making changes        | Variable          |
| **PRESENTING**   | Green checkmark          | Showing results, awaiting feedback  | Until user speaks |
| **ERROR**        | Red pulse                | Something failed, offering recovery | Until user acts   |

### Critical Design Decisions

- **1.5 second silence threshold** for end-of-utterance
- **Checkpoint + halt on "stop"** — not immediate abort
- **Errors must be actionable** with concrete next steps
- **Implicit confirmation:** new request implies previous work accepted (but needs clear communication)

---

## Voice Commands (MVP)

Minimal set for v1:

| Command               | Action                          |
| --------------------- | ------------------------------- |
| "Stop"                | Halt execution, save checkpoint |
| "Undo"                | Revert last change              |
| "Show me the code"    | Slide up code sheet             |
| "What are you doing?" | Agent speaks current status     |
| "Done" / "Looks good" | Accept and return to idle       |
| Any new request       | Implicitly accept previous work |

---

## Gestures (MVP)

| Gesture               | Action               |
| --------------------- | -------------------- |
| Tap Output            | Start listening      |
| Long-press element    | "Tell me about this" |
| Swipe up on Agent bar | Expand history       |
| Swipe left on Output  | Undo                 |
| Swipe right on Output | Redo                 |

---

## Technology Stack

### Voice Pipeline

**Primary: Grok Voice Agent API**

- $0.05/min flat rate (cheaper than OpenAI Realtime)
- <1 second time-to-first-audio
- #1 on Big Bench Audio benchmark
- Native LiveKit integration
- Compatible with OpenAI Realtime API spec

**Transport:** LiveKit Agents (de facto standard)

**Alternative:** OpenAI Realtime API (gpt-realtime) — more mature but 2x cost

### Code Execution

**Primary: E2B Sandboxes**

- <200ms startup, no cold starts
- Sessions up to 24 hours
- ~$0.05/hour per vCPU
- Battle-tested for AI agent workloads

### LLM Models

- **Code generation:** Claude Sonnet 4.5 (fast, excellent for code)
- **Planning/reasoning:** Claude Opus 4.5 (for complex decisions)
- **Fast operations:** Claude Haiku 4.5 (simple changes)
- **Alternative:** GPT-5.2-Codex and GPT-5.1 for code

### Backend Architecture

**Two approaches (both explored):**

1. **Claude Agent SDK approach (recommended for MVP)**
   - Handles agentic loop (reasoning, planning, tool use)
   - Built-in conversation memory
   - Streaming support for real-time updates
   - Maps naturally to agent states
   - Architecture: `Voice → STT → Claude Agent SDK → Code Gen → E2B → TTS → Voice`

2. **Custom orchestration**
   - More control over state transitions
   - Longer to implement
   - Better for production hardening

**Key consideration:** Opus is slower than Sonnet. For MVP, Sonnet 4.5 in the SDK might be better (fast, still excellent at coding).

### iOS Development

- **Framework:** SwiftUI (primary), UIKit for complex interactions
- **IDE:** Xcode 26 (now has built-in Claude integration via MCP)
- **Design tools:** Figma → Locofy/Anima for SwiftUI generation
- **Animations:** SwiftUI native + Lottie for complex motion
- **Development workflow:** Edit Xcode projects in Cursor, keep Xcode open for builds/previews

### Mobile Framework Options

- **React Native** — Cross-platform, good WebView support
- **Flutter** — Similar tradeoffs, strong WebView support

---

## Key Technical Challenges

### 1. WebView State Persistence

**Challenge:** Hot reloads must preserve scroll position, form state, user interaction context.

**Status:** Needs prototyping early. Bridge between "code changed" → "WebView reloads" needs to be bulletproof, especially on slower connections.

### 2. Latency Budget (2.6 seconds target)

- Grok STT: <1s (time-to-first-audio)
- Interpretation: <1s
- Code generation: 600ms (for simple tasks — may be too optimistic)
- Execution + TTS: remaining time

**Issue:** 600ms for code generation only works for simple tasks. Complex changes will exceed budget.

**Solution:** Progressive rendering — generate skeleton code first (50ms), render, refine in background.

### 3. Interaction Disambiguation

**Challenge:** If user taps Output to start listening, but the product itself is interactive (tappable buttons, form fields), how do you prevent accidental interactions?

**Solution:** Toggle mode or subtle visual indicator for "voice input mode" vs "testing mode".

### 4. Clarification UX

**Challenge:** When agent needs clarification (e.g., "Google OAuth or GitHub OAuth?"), do you:

- Interrupt with spoken question? (breaks flow)
- Show visual prompt while listening? (how to handle overlapping intent?)
- Wait silently? (user might think it crashed)

**Status:** Critical UX decision. Needs user research early.

### 5. Implicit Confirmation

**Challenge:** New request signals previous work accepted, but needs to be absolutely clear to users.

**Solution:** Brief visual confirmation when work accepted ("✓ Done" in agent bar), or explicit confirmation for first few interactions, then switch to implicit.

---

## MVP Scope

### What's In

- ✅ Single-screen architecture
- ✅ Agent bar with state indicators
- ✅ WebView for live output
- ✅ Voice input via Grok
- ✅ Code generation and execution
- ✅ "Show me the code" sheet
- ✅ Error handling with actionable options
- ✅ Basic voice commands (Stop, Undo, Done)
- ✅ Implicit confirmation on new requests
- ✅ History sheet (expandable agent bar)

### What's Out

- ❌ Separate screens for different views
- ❌ Code editing (read-only view only)
- ❌ Multi-file navigation
- ❌ Project switching
- ❌ Collaboration features
- ❌ Offline mode
- ❌ Economic monitoring (added post-MVP)

---

## Economic Metrics (Post-MVP, but Design For)

Serious builders care about the cost of using AI in production:

**Track and visualize:**

- **Real-time cost** (per session, per change)
- **Token usage** (input, output, reasoning)
- **Model economics** (which model for which task)
- **Performance tradeoffs** (faster vs cheaper)
- **Cost optimization** (when to use Haiku vs Sonnet vs Opus)

**Display in Control Room:**

- Daily/weekly cost trends
- Cost per component
- Token burn rate
- Model distribution (% Opus, Sonnet, Haiku)

**Agent capabilities:**

- "Cost optimized this 40% by using Sonnet for code gen"
- "Switching to Haiku for this would save $8/day"

---

## Next Steps / Prototype Priorities

1. **WebView hot-reload pipeline** — Simple example: "add a button" → watch it appear
2. **Test Grok Voice API latency** — Real network conditions, full round-trip
3. **Build state machine test harness** — Validate all transitions before UI
4. **User study on clarification UX** — Interrupt vs visual prompt vs silent wait
5. **Prototype the Control Room visualization** — System map, component view, zoom mechanics

---

## Competitive Landscape (December 2025)

**AI Coding Tools:**

- Cursor: $1B ARR, $29.3B valuation, acquired Graphite
- Claude Code: $1B run-rate, acquired Bun, Slack integration
- Windsurf: Acquired by OpenAI for $3B, Wave 11 added voice
- OpenAI Codex: GPT-5.2-Codex (Dec 18), Agent Skills

**App Builders:**

- Lovable: $6.6B valuation, 25M projects
- Bolt: Known token burn issues
- v0: Frontend only, SOC 2 certified
- Antigravity: Free preview, unique multi-agent parallelism

**Key insight:** No one has combined voice-first + mobile-native + code-invisible + production-grade.

---

## Reference Documents

- **UI Specification:** `/voice-coding-app-ui-overview.md` — Single-screen architecture, agent states, gestures
- **Agent Bar Spec:** `/agent-bar-figma-component-spec.md` — Detailed component spec, animations, accessibility
- **Vision One-Pager:** Conductor concept, role transformation, unified market

---

## Design Principles

1. **Output is never navigated away from** — Always the base layer
2. **Voice-first, tap-fallback** — Everything speakable, but tappable too
3. **Code is read-only** — Describe changes verbally, don't edit text
4. **Agent is ambient** — Always present but not dominant
5. **Errors are actionable** — Always offer concrete next steps
6. **No artificial modality switching** — Stay in conversation mode
7. **Mobile-first constraints** — Design for small screen, fast interactions, limited processing

---

## Known Unknowns

- [ ] Will 600ms code gen budget work? (Probably only for simple tasks)
- [ ] How do users prefer clarification UX? (Research needed)
- [ ] What's the mental model for zooming in control room? (Needs prototyping)
- [ ] How fast is Grok in real networks? (Field testing needed)
- [ ] Does implicit confirmation feel natural? (User research)
- [ ] What's the ideal agent bar height/visibility? (A/B test)
- [ ] How often should we show economic metrics? (Usage patterns)

---

## Development Workflow

**iOS Development:**

1. Edit Xcode project files in Claude Code
2. Keep Xcode open for live preview + compilation feedback
3. Use compiler as feedback mechanism for iteration
4. Snapshot testing for visual feedback loops
5. SwiftUI canvas for design feedback

**Backend Development:**

1. Use Claude Agent SDK for agentic orchestration
2. E2B sandboxes for code execution
3. Streaming for real-time status updates
4. Memory across sessions for context

**Design-to-Code:**

1. Figma for design
2. Locofy/Anima for SwiftUI generation
3. Refine generated output as needed

---

## Related Concepts

- **Spoken Reality** — The core framework: "Your ability to verbalize a concept becomes reality"
- **The Control Room** — Visualization metaphor for system/app being built
- **The Stage** — Adaptive output layer showing what you're conducting
- **The Podium** — Agent bar as command interface
- **The Orchestra** — AI as capable first chair following human direction
- **Code Invisibility** — Code as infrastructure, not interface
- **Conducting** — The interaction model: human sets direction, AI handles execution

---

*This document should grow as the project evolves. Reference specific chats by including key decisions and their rationale. Keep it high-level enough for context setting, detailed enough to guide implementation.*