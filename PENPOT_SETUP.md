# Using Penpot for Spoken Reality Design

**Tool:** Penpot (Free Figma Alternative)
**Website:** https://penpot.app

---

## Quick Start with Penpot

### 1. Sign Up (2 minutes)
- Go to https://penpot.app
- Click "Get Started" → Create free account
- Or: Download desktop app from https://penpot.app/download

### 2. Create Project (5 minutes)
```
New Project → "Spoken Reality - iOS App"
  ↓
Create 3 Files:
  1. "Design System" (colors, typography, components)
  2. "Screens - Mobile" (iPhone screens)
  3. "Prototypes" (interactive flows)
```

### 3. Set Up Artboards
- Add new board → iPhone 14 Pro (393 x 852)
- Create additional sizes if needed:
  - iPhone SE: 375 x 667
  - iPhone 14 Pro Max: 430 x 932

---

## Design System in Penpot

### Colors (Create Color Library)

1. Click "+" → Color → Name colors:
```
Backgrounds:
- bg-primary: #0A0A0A
- bg-secondary: #1A1A1A
- bg-tertiary: #2A2A2A

Text:
- text-primary: #FFFFFF
- text-secondary: #888888
- text-tertiary: #666666

Accent:
- accent-primary: #FF6B4A
- accent-hover: #FF8B6A
- success: #4AFF6B
- error: #FF4A4A
- warning: #FFA54A
```

2. Save as "Spoken Reality Colors" library

### Typography (Create Text Styles)

1. Add text → Set font to "Inter" or "SF Pro" (if available)
2. Create text styles:
```
Title Large: 34pt, Bold
Title: 28pt, Bold
Headline: 22pt, Semibold
Body Large: 17pt, Regular
Body: 15pt, Regular
Caption: 13pt, Regular
Small: 11pt, Regular
```

3. Save each as reusable style

### Components (Create Component Library)

**Buttons:**
1. Draw rectangle → Round corners → Fill with coral
2. Add text "Button" → White color
3. Right-click → "Create Component" → Name "Primary Button"
4. Create variants: hover, pressed, disabled

**Floating Mic Button:**
1. Circle (64x64) → Fill coral (#FF6B4A)
2. Add mic icon (use Penpot icons or import)
3. Add shadow effect
4. Create component with states: idle, recording, processing

**Cards:**
1. Rounded rectangle (project card)
2. Add text elements
3. Create component

---

## Screen Design Process

### Screen 1: Home / Project List

**Steps:**
1. Create iPhone artboard (393x852)
2. Draw navigation bar (top)
3. Add "Projects" title + "+" button
4. Create project card component
5. Duplicate card 4 times (2x2 grid)
6. Add spacing between cards
7. Design empty state (centered icon + text)

### Screen 2: Main Development View

**Steps:**
1. New artboard (393x852)
2. Add tab bar at bottom (Output, Database)
3. Large rectangle for WebView area
4. Add floating mic button (bottom-right, 24px from edges)
5. Add thin progress bar at very top (2px)
6. Create component for mic button states

### Continue for all 8 screens...

---

## Prototyping in Penpot

1. Switch to "View" mode
2. Select element (e.g., mic button)
3. Add interaction:
   - Trigger: "On click"
   - Action: "Navigate to"
   - Destination: Next screen
4. Add transitions (slide, fade)

---

## Export Assets

When design is complete:

1. **For Development:**
   - Select element → Right-click → Export
   - Format: PNG @1x, @2x, @3x
   - Or SVG for vectors

2. **For Documentation:**
   - File → Export → Select artboards → PNG

3. **Share with Team:**
   - Click "Share" button → Get public link
   - Or export as PDF

---

## Penpot Tips

**Keyboard Shortcuts:**
- `R` - Rectangle
- `O` - Circle
- `T` - Text
- `V` - Move tool
- `Cmd/Ctrl + D` - Duplicate
- `Cmd/Ctrl + G` - Group

**Speed Tips:**
- Use components for repeated elements
- Create a color palette first
- Use grids and guides for alignment
- Use "Copy styles" for consistency

**Resources:**
- Penpot Docs: https://help.penpot.app
- Video Tutorials: https://www.youtube.com/c/Penpot
- Community: https://community.penpot.app

---

## Time Estimate

**Using Penpot:**
- Design System Setup: 4 hours
- Component Library: 6 hours
- 8 Screens: 12 hours (1.5 hrs each)
- Prototypes: 4 hours
- Polish & Export: 4 hours

**Total: ~30 hours (~4 days of focused work)**

---

## If You Get Stuck

**Alternative Quick Start:**
1. Do rough sketches on paper first
2. Take photos of sketches
3. Import into Penpot as reference
4. Trace over with proper components
5. Much faster than starting from blank canvas

---

**Next Steps:**
1. Sign up for Penpot
2. Create "Spoken Reality" project
3. Start with Design System (colors + typography)
4. Build 1-2 key screens first (Main Development View)
5. Share for feedback before completing all screens
