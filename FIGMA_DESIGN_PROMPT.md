# Figma Design Prompt for Spoken Reality

Use this prompt with Figma AI, or as a brief for a designer.

---

## Project Brief

**App Name:** Spoken Reality
**Platform:** iOS (iPhone)
**Target OS:** iOS 16+
**Design Style:** Modern, minimal, dark theme, production-grade

**Tagline:** "Speak it. Build it. Ship it."

**Core Principle:** Output is primary. Agent is ambient. Code is invisible.

---

## Design Prompt

Create a comprehensive iOS app design system and screens for Spoken Reality, a voice-first mobile development environment where engineers speak their intentions and watch production-grade web applications build in real-time.

### Brand Identity

**Visual Style:**
- **Dark Theme Only:** Deep blacks (#0A0A0A) and dark grays (#1A1A1A)
- **Accent Color:** Vibrant coral (#FF6B4A) - use sparingly for CTAs and highlights
- **Typography:** SF Pro (iOS native) - clean, readable, professional
- **Mood:** Futuristic, minimal, powerful, ambient
- **References:** Think Vercel's dashboard aesthetic meets Arc Browser's spatial design

**Key Visual Metaphors:**
- The output (WebView) should feel like a window into reality being spoken into existence
- Floating mic button should feel ambient, almost invisible until needed
- Progress should be subtle, never intrusive
- Everything should feel fast and responsive

---

## Design System Components

### 1. Color Palette

**Backgrounds:**
- Primary Background: `#0A0A0A` (pitch black)
- Secondary Background: `#1A1A1A` (dark gray)
- Tertiary Background: `#2A2A2A` (medium gray)

**Text:**
- Primary Text: `#FFFFFF` (white)
- Secondary Text: `#888888` (gray)
- Tertiary Text: `#666666` (darker gray)

**Accent:**
- Primary Accent: `#FF6B4A` (coral)
- Accent Hover: `#FF8B6A` (lighter coral)
- Success: `#4AFF6B` (green)
- Error: `#FF4A4A` (red)
- Warning: `#FFA54A` (orange)

### 2. Typography Scale

**SF Pro Display:**
- Title Large: 34pt, Bold (page titles)
- Title: 28pt, Bold (section titles)
- Headline: 22pt, Semibold (card titles)
- Body Large: 17pt, Regular (main content)
- Body: 15pt, Regular (secondary content)
- Caption: 13pt, Regular (metadata)
- Small: 11pt, Regular (fine print)

### 3. Components to Design

**Buttons:**
- Primary button (coral with white text)
- Secondary button (outlined white)
- Ghost button (text only)
- Floating action button (for mic)

**Cards:**
- Project card (with thumbnail, title, metadata)
- Empty state card
- Error state card

**Inputs:**
- Text field (dark with white text)
- Search bar
- Voice input indicator

**Navigation:**
- Tab bar (iOS bottom tabs)
- Navigation bar (iOS top nav)
- Modal sheets

**Indicators:**
- Progress bar (subtle, top of screen)
- Loading spinner
- Pulse animation (for mic listening)
- Success/error toasts

---

## Screen Designs (8 Screens)

### Screen 1: Home / Project List

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Back    Projects         (+)     │ ← Nav bar
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────┐  ┌─────────────┐ │
│  │             │  │             │ │
│  │  Project 1  │  │  Project 2  │ │ ← Project cards
│  │  [Preview]  │  │  [Preview]  │ │   (grid layout)
│  │             │  │             │ │
│  └─────────────┘  └─────────────┘ │
│                                     │
│  ┌─────────────┐  ┌─────────────┐ │
│  │  Project 3  │  │  Project 4  │ │
│  └─────────────┘  └─────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

**Details:**
- Navigation bar: "Projects" title, "+" button top-right
- Grid of project cards (2 columns)
- Each card shows:
  - Thumbnail (screenshot of app)
  - Project name
  - "Last edited X mins ago"
- Empty state (first time):
  - Centered icon + text
  - "Create your first project"
  - Subtle "+" button or CTA

**States to Design:**
- Empty state (no projects)
- 1-3 projects
- Full grid (6+ projects)
- Pull-to-refresh indicator

---

### Screen 2: Main Development View

**Layout:**
```
┌─────────────────────────────────────┐
│ [Subtle progress bar - 2px height]  │ ← Progress indicator (top)
├─────────────────────────────────────┤
│                                     │
│                                     │
│         [WebView Content]           │
│       (Shows live app here)         │
│                                     │
│                                     │
│                                     │
│                                     │
│                     [🎤]            │ ← Floating mic button
│                                     │ │  (bottom-right corner)
├─────────────────────────────────────┤
│     Output        Database          │ ← Tab bar (bottom)
└─────────────────────────────────────┘
```

**Key Elements:**

**Floating Mic Button:**
- Position: Bottom-right, 24px from edges
- Size: 64x64pt circle
- Background: Coral (#FF6B4A) with subtle shadow
- Icon: Microphone (SF Symbol: mic.fill)
- States:
  - **Idle:** Solid coral, static
  - **Held/Recording:** Pulsing animation (scale + glow)
  - **Processing:** Spinner animation inside button
  - **Error:** Brief red flash + shake

**Progress Indicator:**
- Thin bar at very top of screen (2px)
- Coral color
- Animated gradient slide during processing
- Only visible during code generation

**Tab Bar:**
- iOS standard bottom tab bar
- Two tabs: "Output" (default), "Database"
- Active tab: white icon + text
- Inactive tab: gray icon + text

**WebView:**
- Full screen (minus tab bar and safe areas)
- Shows the generated app in real-time
- Fully interactive (scrollable, clickable)
- Loading state: subtle spinner centered

---

### Screen 3: Voice Interaction States

Design the mic button states as separate artboards:

**State 1: Idle**
- Coral circle, microphone icon, subtle shadow

**State 2: Listening (Held)**
- Pulsing scale animation (show 3 frames)
- Glowing ring around button
- Text overlay: "Listening..." (above button)

**State 3: Processing**
- Spinner inside button
- Text overlay: "Processing..." (above button)

**State 4: Success Flash**
- Brief green checkmark animation
- Quick scale up then fade

**State 5: Error**
- Red shake animation
- Error icon briefly
- Text overlay: "Try again" (above button)

**Design each as a separate frame showing the animation key frames.**

---

### Screen 4: Backend Monitoring Dashboard (Database Tab)

**Layout:**
```
┌─────────────────────────────────────┐
│  Database                           │ ← Nav title
├─────────────────────────────────────┤
│  🔍 Search tables...                │ ← Search bar
├─────────────────────────────────────┤
│                                     │
│  Tables                             │
│  ├─ Users            (45 rows)      │
│  ├─ Products         (128 rows)     │
│  ├─ Orders           (89 rows)      │
│  └─ Categories       (12 rows)      │
│                                     │
│  [Selected: Products]               │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ ID  │ Name    │ Price  │... │   │
│  ├─────┼─────────┼────────┼────┤   │ ← Table view
│  │ 1   │ Widget  │ $29.99 │... │   │
│  │ 2   │ Gadget  │ $49.99 │... │   │
│  │ 3   │ Tool    │ $19.99 │... │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

**Details:**
- Left sidebar: List of database tables
- Right side: Selected table data
- Search bar at top
- Each row is tappable (opens detail view)
- Empty state: "No tables yet"

---

### Screen 5: Code Inspection View

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Back to Output      [Export]     │ ← Nav bar
├─────────────────────────────────────┤
│  File Tree         │  Code Preview  │
│                    │                │
│  📁 src            │  function Page │ ← Split view
│   📁 app           │    return (    │
│    📄 page.tsx     │      <div>     │
│   📁 components    │        ...     │
│    📄 Button.tsx   │      </div>    │
│   📁 lib           │    )          │
│                    │  }             │
└────────────────────┴────────────────┘
```

**Details:**
- Split view: file tree (30%) + code viewer (70%)
- Syntax highlighting (use standard dark theme colors)
- Line numbers
- File tree is collapsible
- Tap file to view code
- "Export" button top-right

---

### Screen 6: Project Settings & Export

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Back    Settings                 │
├─────────────────────────────────────┤
│                                     │
│  Project Name                       │
│  ┌───────────────────────────────┐ │
│  │ My Dashboard                  │ │ ← Text field
│  └───────────────────────────────┘ │
│                                     │
│  Export                             │
│  ┌───────────────────────────────┐ │
│  │ Export to GitHub         →    │ │ ← Button
│  └───────────────────────────────┘ │
│                                     │
│  Danger Zone                        │
│  ┌───────────────────────────────┐ │
│  │ Delete Project                │ │ ← Destructive button
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

**Export Flow:**
- Tap "Export to GitHub"
- Sheet appears: "Export ready"
- Shows download button
- Success message: "Repository exported successfully"

**Delete Confirmation:**
- Alert dialog
- "Delete [Project Name]?"
- "This cannot be undone. Export first?"
- Buttons: "Cancel", "Export & Delete", "Delete"

---

### Screen 7: Onboarding (Minimal)

**Screen 7a: Microphone Permission**
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│           [🎤 Large Icon]           │
│                                     │
│     Spoken Reality needs            │
│     microphone access               │
│                                     │
│     Speak your app into existence   │
│     and watch it build live         │
│                                     │
│     [Allow Microphone]              │ ← Primary button
│                                     │
└─────────────────────────────────────┘
```

**Screen 7b: Optional Tip (First Project)**
```
┌─────────────────────────────────────┐
│                                     │
│  [WebView with semi-transparent     │
│   overlay and spotlight on mic btn] │
│                                     │
│   ┌─────────────────────────────┐  │
│   │  Hold mic to speak          │  │ ← Tooltip
│   │  Release to build           │  │
│   │                             │  │
│   │  Try: "Create a product     │  │
│   │  dashboard"                 │  │
│   │                             │  │
│   │          [Got it]           │  │
│   └─────────────────────────────┘  │
│                     [🎤]            │ ← Highlighted
└─────────────────────────────────────┘
```

---

### Screen 8: Empty States & Errors

Design various empty/error states:

**Empty Project List:**
- Large icon (microphone or sparkle)
- "No projects yet"
- "Create your first app with voice"
- "+ New Project" button

**WebView Loading:**
- Centered subtle spinner
- "Building your app..."

**WebView Error:**
- Centered error icon
- "Something went wrong"
- "Try speaking your request again"
- Small "View logs" link

**No Database Tables:**
- Database icon
- "No tables yet"
- "Describe your data model to get started"

**Voice Error:**
- "Couldn't hear that"
- "Hold the mic and speak clearly"
- "Try again" button

---

## Component Library

Create a comprehensive component library including:

### Atoms
- [ ] Buttons (5 variants: primary, secondary, ghost, icon, FAB)
- [ ] Text styles (7 styles: matching typography scale)
- [ ] Icons (mic, database, code, export, settings, error, success)
- [ ] Input fields (text, search)
- [ ] Badges (count, status)
- [ ] Progress indicators (bar, spinner, pulse)

### Molecules
- [ ] Project card
- [ ] Database table row
- [ ] Code file tree item
- [ ] Toast notification
- [ ] Modal sheet header
- [ ] Tab bar item

### Organisms
- [ ] Navigation bar
- [ ] Tab bar
- [ ] Project grid
- [ ] Database browser
- [ ] Code viewer

---

## Interaction & Animation Specs

**Micro-interactions:**
- Mic button press: Scale 0.95, haptic feedback
- Mic button release: Scale 1.05 → 1.0, submit action
- Recording pulse: Scale 1.0 → 1.1 → 1.0 (infinite loop, 1.5s duration)
- Processing spinner: Rotate 360° (1s duration, infinite)
- Success flash: Scale 1.0 → 1.2 → 0, opacity 1 → 0 (0.5s)
- Tab switch: Crossfade 0.2s
- Modal present: Slide up with spring animation

**Timing:**
- Quick actions: 0.2s (tab switch, button tap)
- Medium actions: 0.3s (modal present, card flip)
- Slow actions: 0.5s (page transition)

---

## Responsive Design

**iPhone Sizes to Design:**
- iPhone 14 Pro (6.1", 393x852pt) - Primary design target
- iPhone SE (4.7", 375x667pt) - Compact size test
- iPhone 14 Pro Max (6.7", 430x932pt) - Large size test

**Safe Areas:**
- Respect iOS safe areas (notch, home indicator)
- Floating mic button: 24pt from safe area edges
- Tab bar: Use iOS standard positioning

---

## Accessibility

- [ ] All interactive elements 44x44pt minimum
- [ ] Text contrast ratio 4.5:1 minimum
- [ ] VoiceOver labels for all buttons
- [ ] Dynamic type support (text scales)
- [ ] Reduce motion alternative for animations

---

## Deliverables Checklist

**Design System:**
- [ ] Color palette with hex codes
- [ ] Typography scale defined
- [ ] Component library (atoms, molecules, organisms)
- [ ] Icon set (SF Symbols or custom)

**Screens:**
- [ ] Screen 1: Home / Project List (3 states)
- [ ] Screen 2: Main Development View
- [ ] Screen 3: Voice Interaction States (5 states)
- [ ] Screen 4: Backend Monitoring Dashboard
- [ ] Screen 5: Code Inspection View
- [ ] Screen 6: Project Settings & Export
- [ ] Screen 7: Onboarding (2 screens)
- [ ] Screen 8: Empty States & Errors (5 states)

**Prototypes:**
- [ ] Mic button interaction flow
- [ ] Project creation flow
- [ ] Tab switching animation
- [ ] Export flow

**Documentation:**
- [ ] Design system guidelines doc
- [ ] Animation timing specs
- [ ] Accessibility notes
- [ ] Export specs for developers

---

## Export Instructions

When design is complete, export:

1. **For Development:**
   - PNG assets @1x, @2x, @3x (iOS standard)
   - PDF vector icons
   - Design tokens (JSON with colors, spacing, etc)

2. **For Documentation:**
   - High-fidelity mockups (PNG, 2x)
   - Prototype video walkthrough
   - Figma shareable link (view-only)

3. **For Stakeholders:**
   - PDF presentation of key screens
   - Interactive prototype link

---

## Success Criteria

Your design is successful if:
- ✅ Output (WebView) feels primary, not the UI
- ✅ Mic button feels ambient, not intrusive
- ✅ Interactions feel fast and responsive
- ✅ Design looks production-grade, not prototypey
- ✅ Dark theme is consistent and polished
- ✅ Engineers would trust this tool with production work

---

**End of Figma Design Prompt**

Use this prompt to guide your design process in Figma. Start with the component library, then build out each screen systematically.
