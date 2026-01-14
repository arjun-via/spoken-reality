# repo2interactive - GitHub Repository to Interactive JSON

**Generate hierarchical JSON representations of GitHub repositories for the SpokenRealityApp Infographic feature.**

This tool uses Google's Gemini models via OpenRouter to analyze any GitHub repository and produce a structured JSON file that can be visualized as nested, expandable boxes in the iOS app.

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd Tools/repo2interactive
pip install -r requirements.txt
```

### 2. Set Up API Key

```bash
export OPENROUTER_API_KEY=your_key_here
```

Or use 1Password integration if configured.

### 3. Generate Interactive JSON

```bash
python repo2interactive.py https://github.com/owner/repo-name
```

**Output**: `repo2interactive_output/repo-name_interactive.json`

### 4. Use in iOS App

1. Copy the JSON file to `SpokenRealityApp/Resources/`
2. Rebuild the app
3. The file will appear in the sample buttons

Or load it directly via the file picker in the app.

---

## 📖 Usage

### Basic Usage

```bash
python repo2interactive.py https://github.com/ArjunDivecha/California-Law-Chatbot
```

### Custom Output Directory

```bash
python repo2interactive.py https://github.com/owner/repo --out-dir my_output
```

### Custom Model

```bash
python repo2interactive.py https://github.com/owner/repo --text-model google/gemini-3-flash-preview
```

---

## 📊 Output Structure

The generated JSON follows a hierarchical schema:

```
REPO (root)
├── PHASE (high-level stages)
│   ├── STEP (individual processes)
│   │   ├── FILE (source files)
│   │   │   ├── FUNCTION (methods/functions)
│   │   │   │   └── CODE_BLOCK (actual code with annotations)
```

See `schema/interactive_infographic_schema.json` for the full JSON schema.

---

## 📁 Files

```
repo2interactive/
├── repo2interactive.py          # Main script
├── prompts_interactive.py       # Prompt templates for Gemini
├── requirements.txt             # Python dependencies
├── schema/
│   ├── interactive_infographic_schema.json  # JSON schema
│   └── example_interactive.json             # Example output
└── repo2interactive_output/     # Generated JSON files
```

---

## 🎯 What It Captures

- ✅ Entry points and execution paths
- ✅ Data flow (inputs, outputs, connections)
- ✅ Pipeline phases
- ✅ Source files with language detection
- ✅ Functions with signatures and docstrings
- ✅ Code blocks with annotations
- ✅ GitHub URLs for direct linking
