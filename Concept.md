> **Note:** This is a historical design document from early concept discussions. The implementation has evolved - we now use OpenAI Whisper for STT instead of Grok Voice, and Claude for code generation. See `PROJECT_STATUS.md` for current implementation details.

I've reviewed the voice-first mobile coding app UI overview and your project summary. This is a compelling vision—distilling the IDE down to its essence (output + voice) while keeping code as infrastructure rather than interface.

A few observations and questions as you move into implementation:

## On the Single-Screen Architecture

The decision to keep Output as the always-visible base layer is strong. It enforces the "output is primary" principle. A few implementation details worth thinking through early:

**Hot reload and state persistence:** When the user says "add login with Google," the WebView needs to update without losing scroll position, form state, or user interaction context. Have you thought through how to handle WebView state across agent operations? E2B sandboxes can handle this, but the bridge between "code changed" → "WebView reloads" needs to be bulletproof, especially on slower connections.

**Interaction disambiguation:** If the user taps the Output to start listening, but the product itself is interactive (tappable buttons, form fields), how do you prevent accidental interactions? You might need a toggle mode or a subtle visual indicator that you're in "voice input mode" vs. "testing mode."

## On Agent State Transitions

Your state machine is well-defined, but I notice a potential friction point: the CLARIFYING state. Voice interaction creates ambiguity that text-based IDEs can defer to the user. When the agent needs clarification ("Do you want Google OAuth or GitHub OAuth?"), does it:

- Interrupt with a spoken question (breaks flow)?
- Show a visual prompt while continuing to listen (how do you handle overlapping intent)?
- Wait silently for the user to respond (user might think it crashed)?

This feels like a critical UX decision early on.

## On the Latency Budget

Your 2.6s budget is realistic but tight, especially for code generation. A few thoughts:

- The 600ms you've allocated for "Code generation" assumes a small, focused task (e.g., "add a button"). For anything more complex, you'll exceed budget.
- Have you considered **progressive rendering**? E.g., the agent could generate skeleton code first (50ms), render it, then refine in the background?
- **Grok's <1s time-to-first-audio** is a huge advantage, but worth testing early—that metric might not account for the full round-trip you're implementing.

## On MVP Scope

Your MVP exclusions are disciplined. But I'd flag one: **implicit confirmation via new request.** This is clever ("saying something new means I accept the previous work"), but it needs to be absolutely clear to users. Consider:

- A brief visual confirmation when work is accepted ("✓ Done" in the agent bar)?
- Or explicit confirmation required for the first few interactions, then switching to implicit?

## Questions Worth Exploring Before Code

1. **Voice alone or voice + visual UI for complex tasks?** Your MVP is voice-first, but if a user wants to "add three different login methods," will voice suffice, or do you need a visual task breakdown?

2. **Error recovery:** When something fails (OAuth credentials missing, dependency conflict), your design shows actionable buttons. But how does voice interact with these? Does the user have to tap, or can they say "help me set up"?

3. **Context window:** As the session grows (longer conversation history, larger codebase), how does agent reasoning degrade? Do you need explicit checkpoints to reset context?

4. **Mobile-specific constraints:** React Native has good WebView support, but cross-platform compatibility (iOS vs. Android) for voice input and gesture handling varies. Have you tested LiveKit on both platforms?

## On Competitive Positioning

Your insight is sharp: **voice-first + mobile-native + code-invisible + production-grade is unoccupied.** But each of those is hard. The risk isn't market timing—it's execution. Windsurf already added voice (Wave 11), and they have desktop momentum. Your mobile advantage is real, but only if the UX feels 10x better, not just different.

The GTM strategy (start with software engineers, prove production quality, expand to general users) is solid. But it means your MVP can't have prototype-grade output. The first user's code needs to actually compile and run.

---

**Next steps I'd suggest:**
- Prototype the WebView hot-reload pipeline with a simple example (add a button → see it update)
- Test Grok Voice Agent API latency in your actual network conditions
- Build a state machine test harness to validate transitions before building UI
- Run a quick user study on the clarification UX (interruption vs. visual prompt vs. silent wait)

What's your timeline for getting to a functional prototype?


Yes, using the Claude Agent SDK for your MVP backend makes a lot of sense given this UI architecture. Here's why the fit is strong:

## Alignment with Your Agent States

The Claude Agent SDK maps naturally to your agent state machine:

| Your State | SDK Behavior |
|------------|--------------|
| LISTENING | Waiting for input |
| THINKING | Claude reasoning/planning |
| EXECUTING | Tool use (file writes, sandbox commands) |
| CLARIFYING | Claude asking follow-up questions |
| ERROR | Tool failures / validation issues |

## Simplified Architecture for MVP

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│  Voice In   │────▶│  Claude Agent    │────▶│  Sandbox    │
│  (LiveKit)  │     │  SDK             │     │  (WebView)  │
└─────────────┘     │                  │     └─────────────┘
                    │  Tools:          │           │
                    │  • write_file    │           │
                    │  • run_command   │◀──────────┘
                    │  • read_file     │      (feedback)
                    └──────────────────┘
```

You'd define a small set of tools the agent can use, and the SDK handles the agentic loop—deciding when to call tools, when to ask for clarification, when to present results.

## Why This Works for MVP

1. **No custom orchestration** — The SDK handles reasoning loops, retries, and tool chaining
2. **Streaming support** — You can stream responses to update the Agent Bar status in real-time
3. **Conversation memory** — Built-in context management for the expanded history view
4. **Code generation is Claude's strength** — No model fine-tuning needed

## One Consideration: Voice Latency

Your spec mentions "<1s latency" with Grok Voice Agent. The flow would be:

```
Voice → STT (LiveKit) → Claude Agent SDK → Tool execution → TTS
```

The Claude SDK call adds latency. For MVP, you might accept slightly higher latency (1-2s) to keep the architecture simple. Optimizations like speculative responses or streaming partial results can come later.

## Suggested MVP Backend Shape

```swift
// Pseudo-structure
struct AgentBackend {
    let claude: ClaudeAgentSDK
    let sandbox: SandboxClient  // e2b, CodeSandbox, or similar
    
    func process(userIntent: String) -> AsyncStream<AgentEvent> {
        // Stream events: thinking, executing, done, error
    }
}
```

Would you like me to sketch out what the tool definitions might look like, or explore the sandbox options (e2b, CodeSandbox, etc.) that would pair well with this setup?


