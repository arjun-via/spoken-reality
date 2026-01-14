# Interactive Infographic Feature

**Visualize GitHub repository architectures as nested, expandable boxes on iOS.**

This feature allows you to explore the structure of any GitHub repository through an interactive, hierarchical visualization. Starting from high-level phases, you can drill down through steps, files, functions, and ultimately view the actual code.

---

## ✨ Features

- **Nested Box Visualization**: Repository structure displayed as expandable/collapsible boxes
- **Hierarchical Levels**: REPO → PHASE → STEP → FILE → FUNCTION → CODE
- **Color-Coded Node Types**: Each level has distinct colors for easy identification
- **Inline Code Display**: View actual code snippets at the deepest level
- **GitHub Links**: Direct links to view code on GitHub
- **Data Flow Visualization**: See inputs, outputs, and connections between components
- **Annotations**: Explanatory comments on code blocks

---

## 📱 How to Use

### In the App

1. **Open a project** (or create a new one)
2. **Swipe DOWN** from the main development view (or tap the purple "↓ Info" button)
3. **Load a JSON file**:
   - Tap a sample button ("California Law Chatbot" or "HTTPie CLI")
   - Or tap the folder icon to load your own JSON file
4. **Tap "View Infographic"** to see the nested visualization
5. **Interact**:
   - Tap any box to expand/collapse it
   - Use "Expand All" / "Collapse All" buttons in the toolbar
   - Tap GitHub links to view code online

### Node Types & Colors

| Type | Color | Description |
|------|-------|-------------|
| REPO | Blue | Repository root |
| PHASE | Purple | High-level pipeline phases |
| STEP | Green | Individual processing steps |
| FILE | Yellow/Gold | Source code files |
| FUNCTION | Pink | Functions/methods |
| CODE | Red | Actual code blocks |

---

## 🔧 Generating JSON Files

To create infographic JSON files for your own repositories, use the `repo2interactive.py` script from the `github-to-viamobile` project:

```bash
cd /path/to/github-to-viamobile
python repo2interactive.py https://github.com/owner/repo-name
```

**Output**: `repo2interactive_output/repo-name_interactive.json`

Transfer this JSON file to your iOS device and load it in the app.

---

## 📁 File Structure

```
SpokenRealityApp/
├── Models/
│   └── InfographicModels.swift      # Data models for JSON decoding
├── Features/
│   └── Infographic/
│       ├── InfographicBrowserView.swift  # File loader/browser
│       └── InfographicView.swift         # Nested box visualization
└── Resources/
    ├── California-Law-Chatbot_interactive.json  # Sample data
    └── cli_interactive.json                      # Sample data
```

---

## 📊 JSON Schema

The infographic JSON follows this hierarchical structure:

```json
{
  "version": "2.0",
  "schema": "interactive-infographic",
  "repo_url": "https://github.com/owner/repo",
  "repo_name": "repo-name",
  "repo_summary": "Brief description",
  "pipeline_overview": "What this repo does",
  "generated_at": "2026-01-14T12:00:00Z",
  "root": {
    "id": "root",
    "type": "repo",
    "label": "Repository Name",
    "description": "Description",
    "children": [
      {
        "id": "phase-1",
        "type": "phase",
        "label": "Ingestion",
        "children": [...]
      }
    ]
  }
}
```

### Node Types

- **repo**: Repository root (only one)
- **phase**: High-level pipeline phases (e.g., Ingestion, Processing, Output)
- **step**: Individual processing steps within a phase
- **file**: Source code files
- **function**: Functions/methods within files
- **code_block**: Actual code snippets with annotations

### Metadata Types

Each node type can have specific metadata:

- `phase_metadata`: `phase_id`, `phase_purpose`
- `step_metadata`: `source_nodes`, `target_nodes`, `process_script`, `notes`, `connections`
- `file_metadata`: `file_path`, `language`, `github_url`, `line_count`
- `function_metadata`: `function_name`, `signature`, `docstring`, `line_start`, `line_end`, `github_url`
- `code_metadata`: `code`, `language`, `annotations`, `line_start`, `line_end`, `github_url`

---

## 🎨 Visual Design

The visualization follows the app's dark theme with:

- **Dark backgrounds** (`#0A0A0A`, `#1A1A1A`, `#2A2A2A`)
- **Accent color** for interactive elements (`#FF6B4A`)
- **Colored borders** for each node type
- **Rounded corners** and subtle shadows
- **SF Symbols** for icons

---

## 🔗 Integration

The Infographic feature is integrated into the main `DevelopmentView`:

- **Swipe DOWN** from the main screen to access
- **Toolbar button** ("↓ Info") for quick access
- **Full-screen cover** for the detailed visualization

---

## 📝 Version History

- **v1.0** (2026-01-14): Initial implementation
  - Nested box visualization
  - Sample data bundled
  - File picker for custom JSON
  - Expand/collapse functionality
  - Code display with annotations
