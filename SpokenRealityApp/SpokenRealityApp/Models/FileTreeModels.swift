import Foundation

// MARK: - File Tree Item Model

enum FileTreeItem: Identifiable, Hashable {
    case folder(name: String, children: [FileTreeItem], isExpanded: Bool)
    case file(name: String, content: String)

    var id: String {
        switch self {
        case .folder(let name, _, _):
            return "folder_\(name)"
        case .file(let name, _):
            return "file_\(name)"
        }
    }

    var name: String {
        switch self {
        case .folder(let name, _, _):
            return name
        case .file(let name, _):
            return name
        }
    }

    var isFolder: Bool {
        if case .folder = self { return true }
        return false
    }
}

// MARK: - Sample File Tree Data

extension FileTreeItem {
    static let sampleFileTree: [FileTreeItem] = [
        .folder(name: "src", children: [
            .folder(name: "app", children: [
                .file(name: "page.tsx", content: samplePageTSX),
                .file(name: "layout.tsx", content: sampleLayoutTSX),
                .file(name: "globals.css", content: sampleCSS)
            ], isExpanded: true),
            .folder(name: "components", children: [
                .file(name: "Button.tsx", content: sampleButtonTSX),
                .file(name: "Card.tsx", content: sampleCardTSX),
                .file(name: "Header.tsx", content: sampleHeaderTSX)
            ], isExpanded: false),
            .folder(name: "lib", children: [
                .file(name: "utils.ts", content: sampleUtilsTS),
                .file(name: "api.ts", content: sampleAPITS)
            ], isExpanded: false)
        ], isExpanded: true),
        .folder(name: "public", children: [
            .file(name: "favicon.ico", content: "// Binary file")
        ], isExpanded: false),
        .file(name: "package.json", content: samplePackageJSON),
        .file(name: "tsconfig.json", content: sampleTSConfig)
    ]

    // Sample code contents
    static let samplePageTSX = """
export default function Page() {
  return (
    <div className="container">
      <h1>Welcome to Spoken Reality</h1>
      <p>Your app is live!</p>
      <Button onClick={() => alert('Hello!')}>
        Click me
      </Button>
    </div>
  )
}
"""

    static let sampleLayoutTSX = """
import './globals.css'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
"""

    static let sampleCSS = """
:root {
  --background: #0a0a0a;
  --foreground: #ffffff;
  --accent: #ff6b4a;
}

body {
  background: var(--background);
  color: var(--foreground);
  font-family: system-ui, sans-serif;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}
"""

    static let sampleButtonTSX = """
interface ButtonProps {
  children: React.ReactNode
  onClick?: () => void
}

export function Button({ children, onClick }: ButtonProps) {
  return (
    <button
      onClick={onClick}
      className="px-4 py-2 bg-accent text-white rounded-lg"
    >
      {children}
    </button>
  )
}
"""

    static let sampleCardTSX = """
interface CardProps {
  title: string
  description: string
}

export function Card({ title, description }: CardProps) {
  return (
    <div className="p-6 bg-secondary rounded-lg">
      <h3 className="text-xl font-bold">{title}</h3>
      <p className="text-gray-400">{description}</p>
    </div>
  )
}
"""

    static let sampleHeaderTSX = """
export function Header() {
  return (
    <header className="flex items-center justify-between p-4">
      <h1 className="text-2xl font-bold">My App</h1>
      <nav>
        <a href="/">Home</a>
        <a href="/about">About</a>
      </nav>
    </header>
  )
}
"""

    static let sampleUtilsTS = """
export function formatDate(date: Date): string {
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

export function cn(...classes: string[]): string {
  return classes.filter(Boolean).join(' ')
}
"""

    static let sampleAPITS = """
const API_URL = process.env.NEXT_PUBLIC_API_URL

export async function fetchData(endpoint: string) {
  const response = await fetch(`${API_URL}${endpoint}`)
  if (!response.ok) {
    throw new Error('Failed to fetch')
  }
  return response.json()
}
"""

    static let samplePackageJSON = """
{
  "name": "my-app",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  }
}
"""

    static let sampleTSConfig = """
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true
  }
}
"""
}
