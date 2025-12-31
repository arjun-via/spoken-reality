# Spoken Reality - SwiftUI Implementation Guide

**Approach:** Code-First, Design in SwiftUI
**Timeline:** Working prototype in 1-2 weeks

---

## Phase 1: Project Setup (30 minutes)

### Step 1: Create Xcode Project

1. **Open Xcode** (download from Mac App Store if needed)
2. **Create New Project:**
   - File → New → Project
   - Choose: **iOS → App**
   - Click Next

3. **Project Configuration:**
   ```
   Product Name: SpokenReality
   Team: Your Apple Developer Account (or None for now)
   Organization Identifier: com.yourdomain
   Interface: SwiftUI
   Language: Swift
   Storage: None (we'll add later)
   Include Tests: ☑️ (checked)
   ```

4. **Save Location:**
   - Choose a location (e.g., ~/Development/spoken-reality-ios)
   - ☑️ Create Git repository on my Mac
   - Click Create

### Step 2: Project Structure

Create this folder structure in Xcode:

```
SpokenReality/
├── App/
│   ├── SpokenRealityApp.swift     (main app entry)
│   └── ContentView.swift           (root view)
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ProjectCard.swift
│   ├── Development/
│   │   ├── DevelopmentView.swift  (main screen)
│   │   ├── WebView.swift
│   │   ├── MicButton.swift
│   │   └── VoiceRecorder.swift
│   └── Database/
│       └── DatabaseView.swift
├── Core/
│   ├── Theme/
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   └── Spacing.swift
│   └── Components/
│       ├── FloatingButton.swift
│       └── ProgressBar.swift
├── Models/
│   └── Project.swift
└── Services/
    ├── VoiceService.swift
    └── APIService.swift
```

**To create folders in Xcode:**
- Right-click on SpokenReality folder → New Group
- Name it, then drag files into it

---

## Phase 2: Design System in Code (1 hour)

### File: `Core/Theme/Colors.swift`

```swift
import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let bgPrimary = Color(hex: "0A0A0A")
    static let bgSecondary = Color(hex: "1A1A1A")
    static let bgTertiary = Color(hex: "2A2A2A")

    // MARK: - Text
    static let textPrimary = Color(hex: "FFFFFF")
    static let textSecondary = Color(hex: "888888")
    static let textTertiary = Color(hex: "666666")

    // MARK: - Accent
    static let accentPrimary = Color(hex: "FF6B4A")
    static let accentHover = Color(hex: "FF8B6A")
    static let success = Color(hex: "4AFF6B")
    static let error = Color(hex: "FF4A4A")
    static let warning = Color(hex: "FFA54A")

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

### File: `Core/Theme/Typography.swift`

```swift
import SwiftUI

extension Font {
    // MARK: - Typography Scale
    static let titleLarge = Font.system(size: 34, weight: .bold)
    static let title = Font.system(size: 28, weight: .bold)
    static let headline = Font.system(size: 22, weight: .semibold)
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let small = Font.system(size: 11, weight: .regular)
}
```

### File: `Core/Theme/Spacing.swift`

```swift
import Foundation

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

---

## Phase 3: Core Components (2 hours)

### File: `Core/Components/FloatingButton.swift`

```swift
import SwiftUI

struct FloatingButton: View {
    enum ButtonState {
        case idle
        case recording
        case processing
        case error
        case success
    }

    @State private var state: ButtonState = .idle
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                // Pulsing ring (recording state)
                if state == .recording {
                    Circle()
                        .stroke(Color.accentPrimary.opacity(0.5), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(scale)
                        .opacity(2 - scale)
                }

                // Icon
                icon
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(state == .idle ? 1.0 : 0.95)
        .animation(.spring(response: 0.3), value: state)
        .onChange(of: state) { newState in
            handleStateChange(newState)
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .idle: return .accentPrimary
        case .recording: return .accentPrimary
        case .processing: return .accentPrimary
        case .error: return .error
        case .success: return .success
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .idle, .recording:
            Image(systemName: "mic.fill")
        case .processing:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
        case .success:
            Image(systemName: "checkmark")
        }
    }

    private func handleStateChange(_ newState: ButtonState) {
        switch newState {
        case .recording:
            startPulseAnimation()
        case .success, .error:
            // Auto-reset to idle after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                state = .idle
            }
        default:
            break
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            scale = 1.3
        }
    }

    // Public methods to control state
    func setState(_ newState: ButtonState) {
        state = newState
    }
}

struct FloatingButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 40) {
                FloatingButton(action: {})
                    .onAppear {
                        // Preview different states
                    }
            }
        }
    }
}
```

### File: `Core/Components/ProgressBar.swift`

```swift
import SwiftUI

struct ProgressBar: View {
    @State private var progress: CGFloat = 0
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.bgSecondary)
                    .frame(height: 2)

                // Progress
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.accentPrimary, .accentHover],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 2)
                    .animation(.linear(duration: 0.3), value: progress)
            }
        }
        .frame(height: 2)
    }

    func start() {
        isAnimating = true
        animateProgress()
    }

    func complete() {
        withAnimation(.easeOut(duration: 0.2)) {
            progress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            reset()
        }
    }

    func reset() {
        progress = 0
        isAnimating = false
    }

    private func animateProgress() {
        guard isAnimating else { return }
        withAnimation(.linear(duration: 0.5)) {
            progress = min(progress + 0.1, 0.9)
        }
        if progress < 0.9 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateProgress()
            }
        }
    }
}
```

---

## Phase 4: WebView Component (1 hour)

### File: `Features/Development/WebView.swift`

```swift
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL?
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(Color.bgPrimary)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = url, webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}
```

---

## Phase 5: Main Development View (2 hours)

### File: `Features/Development/DevelopmentView.swift`

```swift
import SwiftUI

enum DevelopmentTab {
    case output
    case database
}

struct DevelopmentView: View {
    @State private var selectedTab: DevelopmentTab = .output
    @State private var isLoading = false
    @State private var showProgress = false
    @State private var devServerURL: URL? = URL(string: "https://example.com")

    // For mic button
    @State private var isRecording = false
    @State private var micButtonState: FloatingButton.ButtonState = .idle

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar at top
                if showProgress {
                    ProgressBar()
                        .transition(.opacity)
                }

                // Main content area
                TabView(selection: $selectedTab) {
                    // Output tab (WebView)
                    outputView
                        .tag(DevelopmentTab.output)

                    // Database tab
                    databaseView
                        .tag(DevelopmentTab.database)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom tab bar
                tabBar
            }

            // Floating mic button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingButton {
                        handleMicTap()
                    }
                    .padding(.trailing, Spacing.lg)
                    .padding(.bottom, 80) // Above tab bar
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Output View (WebView)

    private var outputView: some View {
        ZStack {
            if let url = devServerURL {
                WebView(url: url, isLoading: $isLoading)
            } else {
                emptyWebViewState
            }

            if isLoading {
                loadingOverlay
            }
        }
    }

    private var emptyWebViewState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary)

            Text("Hold the mic and speak")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text("Try: 'Create a product dashboard'")
                .font(.body)
                .foregroundColor(.textSecondary)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                    .scaleEffect(1.5)

                Text("Building your app...")
                    .font(.body)
                    .foregroundColor(.textPrimary)
            }
        }
    }

    // MARK: - Database View

    private var databaseView: some View {
        VStack {
            Text("Database Browser")
                .font(.title)
                .foregroundColor(.textPrimary)

            Spacer()

            Text("Coming soon")
                .font(.body)
                .foregroundColor(.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(
                icon: "app.fill",
                title: "Output",
                tab: .output
            )

            tabBarItem(
                icon: "cylinder.fill",
                title: "Database",
                tab: .database
            )
        }
        .frame(height: 50)
        .background(Color.bgSecondary)
    }

    private func tabBarItem(icon: String, title: String, tab: DevelopmentTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))

                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selectedTab == tab ? .accentPrimary : .textSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func handleMicTap() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        micButtonState = .recording

        // TODO: Start actual audio recording

        // Simulate recording and processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            stopRecording()
        }
    }

    private func stopRecording() {
        isRecording = false
        micButtonState = .processing
        showProgress = true

        // TODO: Send audio to Grok API

        // Simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            processComplete()
        }
    }

    private func processComplete() {
        showProgress = false
        micButtonState = .success

        // TODO: Reload WebView with new code
        // For now, just simulate success

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            micButtonState = .idle
        }
    }
}

struct DevelopmentView_Previews: PreviewProvider {
    static var previews: some View {
        DevelopmentView()
    }
}
```

---

## Phase 6: Home View (1 hour)

### File: `Models/Project.swift`

```swift
import Foundation

struct Project: Identifiable {
    let id: UUID
    var name: String
    var lastEdited: Date
    var thumbnailURL: URL?

    init(id: UUID = UUID(), name: String, lastEdited: Date = Date(), thumbnailURL: URL? = nil) {
        self.id = id
        self.name = name
        self.lastEdited = lastEdited
        self.thumbnailURL = thumbnailURL
    }
}
```

### File: `Features/Home/ProjectCard.swift`

```swift
import SwiftUI

struct ProjectCard: View {
    let project: Project
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Thumbnail
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bgTertiary)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.textTertiary)
                    )

                // Project name
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                // Last edited
                Text(relativeTime(from: project.lastEdited))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(Spacing.sm)
            .background(Color.bgSecondary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
```

### File: `Features/Home/HomeView.swift`

```swift
import SwiftUI

struct HomeView: View {
    @State private var projects: [Project] = [
        Project(name: "Product Dashboard", lastEdited: Date().addingTimeInterval(-3600)),
        Project(name: "Admin Panel", lastEdited: Date().addingTimeInterval(-7200)),
        Project(name: "E-commerce Store", lastEdited: Date().addingTimeInterval(-86400)),
    ]

    @State private var selectedProject: Project?
    @State private var showDevelopmentView = false

    let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                if projects.isEmpty {
                    emptyState
                } else {
                    projectGrid
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createNewProject) {
                        Image(systemName: "plus")
                            .foregroundColor(.accentPrimary)
                    }
                }
            }
            .navigationDestination(isPresented: $showDevelopmentView) {
                if selectedProject != nil {
                    DevelopmentView()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var projectGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(projects) { project in
                    ProjectCard(project: project) {
                        selectProject(project)
                    }
                }
            }
            .padding(Spacing.md)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 64))
                .foregroundColor(.textSecondary)

            Text("No projects yet")
                .font(.title)
                .foregroundColor(.textPrimary)

            Text("Create your first app with voice")
                .font(.body)
                .foregroundColor(.textSecondary)

            Button(action: createNewProject) {
                Text("New Project")
                    .font(.bodyLarge)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.accentPrimary)
                    .cornerRadius(12)
            }
            .padding(.top, Spacing.md)
        }
    }

    private func selectProject(_ project: Project) {
        selectedProject = project
        showDevelopmentView = true
    }

    private func createNewProject() {
        let newProject = Project(name: "New Project \(projects.count + 1)")
        projects.insert(newProject, at: 0)
        selectProject(newProject)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
```

---

## Phase 7: App Entry Point

### File: `App/SpokenRealityApp.swift`

```swift
import SwiftUI

@main
struct SpokenRealityApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
```

---

## Testing Your App

### Run in Simulator (Cmd + R)

1. Select iPhone 14 Pro simulator (Product → Destination → iPhone 14 Pro)
2. Press Cmd + R or click Play button
3. App should launch showing HomeView

### Test Flow:

1. **Home Screen:**
   - See empty state or project grid
   - Tap "+" to create project

2. **Development View:**
   - See WebView (loading example.com for now)
   - Floating mic button in bottom-right
   - Tap mic button → See recording animation
   - Progress bar appears at top
   - Success state, then back to idle

### SwiftUI Preview:

Add this to any view file:
```swift
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
            .preferredColorScheme(.dark)
    }
}
```

Then click "Resume" in the canvas (right side of Xcode)

---

## Next Steps

### Week 1: Core UI (You are here!)
- ✅ Project setup
- ✅ Design system
- ✅ Core components
- ✅ Main screens (Home, Development)
- ⏭️ TODO: Add microphone recording
- ⏭️ TODO: Integrate Grok API

### Week 2: Voice Integration
- Add AVFoundation for audio recording
- Integrate Grok Voice API
- Handle voice → code flow
- Add authentication

### Week 3: Backend Integration
- Connect to backend API
- Workspace provisioning
- WebView updates

---

## Pro Tips

**SwiftUI Live Preview:**
- Option + Cmd + P to refresh preview
- Option + Cmd + Return to toggle preview

**Hot Reload:**
- SwiftUI auto-updates on save
- Much faster than full rebuild

**Debugging:**
- Add `print("Debug: \(variable)")` anywhere
- View console: View → Debug Area → Show Debug Area (Cmd + Shift + Y)

**Keyboard Shortcuts:**
- Cmd + R: Run
- Cmd + B: Build
- Cmd + . : Stop
- Cmd + Shift + O: Quick open file

---

## Resources

**SwiftUI Documentation:**
- https://developer.apple.com/documentation/swiftui/

**Tutorials:**
- Apple's SwiftUI Tutorials: https://developer.apple.com/tutorials/swiftui
- Hacking with Swift: https://www.hackingwithswift.com/quick-start/swiftui

**Community:**
- SwiftUI Lab: https://swiftui-lab.com
- Reddit r/SwiftUI: https://reddit.com/r/SwiftUI

---

**You now have a working Spoken Reality iOS app shell!**

Next, I'll help you add voice recording and Grok API integration.
