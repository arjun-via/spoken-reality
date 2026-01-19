# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Spoken Reality** is a voice-first, mobile-native development environment where users speak their intentions and production-grade applications are built in real-time.

### Core Vision
- **Tagline**: "Speak it. Build it. Ship it."
- **Principle**: Output is primary. Agent is ambient. Code is invisible.
- **Philosophy**: Your ability to verbalize a concept becomes reality.

### Design Pillars

1. **🎤 Voice-First Creation**
   - Speak intentions, not prompts
   - Voice transcription via OpenAI Whisper
   - Natural conversation, not commands

2. **📱 Mobile-Native Architecture**
   - Build from anywhere
   - Single screen architecture
   - Output is primary — live WebView updates

3. **⚡ Production-Grade from Day One**
   - Industrial strength architecture
   - Proper error handling
   - Scalability built-in
   - Engineers approve first

### The Problem Being Solved

Current AI coding tools fall into three broken categories:
- **Code-lite tools** (Lovable, Replit, Bolt): Great for prototypes, collapse at production
- **AI-augmented IDEs** (Cursor, Windsurf, Copilot): Bolt AI onto old mental models, still assume humans read/write/edit code
- **Desktop-first design**: Everything assumes keyboard + text editor, nothing designed for voice or mobile-native

**Core Question**: If code is invisible infrastructure, what does the interface even look like?

## Development Principles

### Critical: Error Handling Policy
**FAIL IS FAIL - NO UNAUTHORIZED FALLBACKS**

- Always ask permission before implementing any fallback or graceful degradation
- Fail explicitly and loudly when something doesn't work as expected
- Never mask real errors with silent fallbacks
- Document any error handling strategy and get explicit approval first
- All errors must be surfaced with clear, actionable messages

This is especially critical for "production-grade from day one" — users must see what's wrong.

### Code Quality Standards

- **NO SIMULATED CODE** - if you can't make it work, say so
- **Ask before writing code during planning discussions**
- Keep files under 500 lines where possible
- Document everything clearly
- Production-grade architecture required from the start
- Engineers must approve the quality

### File Management
- **DO NOT DELETE FILES OR MOVE FILES WITHOUT EXPLICIT PERMISSION**
- **DO NOT DO ANYTHING NOT EXPLICITLY REQUESTED**

## Technical Environment

### System Specifications
- Running on M4 Max Mac with 128GB RAM
- Maximize use of memory, GPU, and parallelization
- Use MPS (Metal Performance Shaders) for PyTorch when available

### Key Technologies (Expected)
- **Voice**: OpenAI Whisper (speech-to-text)
- **Mobile**: Mobile-native architecture with WebView output
- **Backend**: Production-grade infrastructure

## Target Audience

**Primary**: Engineers and technical users who understand production code
**Go-to-Market Strategy**: Win engineers first. If it satisfies those who know production code, it satisfies anyone.

## Design Constraints

### What to Optimize For
1. Voice interaction quality (natural conversation, not commands)
2. Mobile-first experience (single screen architecture)
3. Real-time output visibility (WebView updates)
4. Production-grade code generation (proper architecture, error handling, scalability)
5. Speed (sub-second voice latency)

### What to Avoid
- Desktop-first thinking
- Code-as-primary-interface
- Prototype-only quality
- Command-based voice interaction
- Keyboard/text editor assumptions

## Project Status

**Current Phase**: Concept/Planning

The project currently consists of:
- Concept documentation (Concept.md - currently empty)
- Pitch deck (spoken-reality.pptx)

Next steps will involve:
- Technical architecture design
- Voice integration proof-of-concept
- Mobile app framework selection
- Backend infrastructure planning

---

Last Updated: 2025-12-30
