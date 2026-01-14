"""
================================================================================
PROMPTS_INTERACTIVE - Prompt Templates for Interactive Infographic Generation
================================================================================

This module contains the prompt templates used by repo2interactive.py to generate
hierarchical JSON with embedded code snippets.

The prompts are designed to:
1. Analyze repository structure and execution flow
2. Extract relevant code snippets (not full files)
3. Build a hierarchical tree suitable for iOS drill-down navigation

VERSION HISTORY:
    v1.0 - Initial version for interactive infographic generation

LAST UPDATED: 2026-01-14
================================================================================
"""


def build_hierarchical_analysis_prompt(repo_url: str) -> str:
    """
    Build the prompt for deep hierarchical analysis of a repository.
    
    This prompt instructs the model to:
    1. Analyze the full repository structure
    2. Trace execution flow from entry points
    3. Extract relevant code snippets
    4. Build a hierarchical tree with proper parent-child relationships
    
    Args:
        repo_url: Full GitHub repository URL
        
    Returns:
        Complete prompt string for the text model
    """
    
    prompt = f"""
You are a Principal Systems Architect with expertise in code analysis. Your task is to analyze the GitHub repository at:
{repo_url}

You must produce a HIERARCHICAL JSON structure that an iOS app can use for interactive drill-down navigation.
The user will tap on elements to zoom in and see more detail, recursively, until they reach the actual code.

================================================================================
ANALYSIS INSTRUCTIONS
================================================================================

1. **FETCH THE ENTIRE REPOSITORY**
   - Read all source files from the repository
   - Understand the project structure and dependencies
   - Identify the programming language(s) used

2. **IDENTIFY ENTRY POINTS**
   - Find main entry points (main.py, app.py, index.js, __main__.py, etc.)
   - Identify CLI entry points, web routes, or event handlers
   - Note which files are the "starting points" of execution

3. **TRACE EXECUTION FLOW**
   - Follow the code execution path from entry points
   - Map out which functions call which other functions
   - Identify data transformations and I/O operations

4. **EXTRACT RELEVANT CODE**
   - For each function/class you identify, extract the actual source code
   - Include ONLY the relevant functions, not entire files
   - Preserve proper indentation and formatting

5. **BUILD THE HIERARCHY**
   Create a tree with these levels (use as many as appropriate):
   
   Level 0: REPO (root)
      └── Level 1: PHASE (pipeline phases like Ingestion, Processing, Output)
             └── Level 2: STEP (specific processing steps)
                    └── Level 3: FILE (source files involved)
                           └── Level 4: FUNCTION (functions/classes)
                                  └── Level 5: CODE_BLOCK (actual code)

================================================================================
PHASE DEFINITIONS
================================================================================

Assign steps to these phases (use the ones that apply):

1. Ingestion - User input, API requests, loading config/data, reading files
2. Cleaning & Normalization - Validation, parsing, pre-processing
3. Feature Engineering - Data transformation, embedding generation, RAG retrieval
4. Modeling / Computation - Core logic, LLM calls, inference, business rules
5. Optimization / Post-Processing - Formatting, filtering, ranking, verification
6. Reporting / Export - Saving to DB, writing files, API response, UI display

================================================================================
JSON SCHEMA
================================================================================

Your output MUST be a single JSON object with this EXACT structure:

{{
  "version": "2.0",
  "schema": "interactive-infographic",
  "repo_url": "{repo_url}",
  "repo_name": "short-name",
  "repo_summary": "1-3 sentence description",
  "pipeline_overview": "1-2 sentence pipeline summary",
  "generated_at": "2026-01-14T00:00:00Z",
  "root": {{
    "id": "root",
    "type": "repo",
    "label": "Repository Name",
    "description": "Short description",
    "visual_hint": {{
      "icon": "appropriate_sf_symbol",
      "color": "#hexcolor"
    }},
    "children": [
      // Array of phase nodes
    ]
  }}
}}

================================================================================
NODE STRUCTURE
================================================================================

Each node in the tree MUST have:

{{
  "id": "unique-id",           // e.g., "phase-1", "step-1.1", "func-main"
  "type": "node_type",         // One of: repo, phase, step, file, function, code_block
  "label": "Display Name",     // Short name for UI
  "description": "Brief desc", // 5-15 words
  "visual_hint": {{
    "icon": "sf_symbol_name",  // SF Symbol for iOS (e.g., "terminal", "doc.text", "function")
    "color": "#hexcolor",      // Hex color for styling
    "badge": "optional"        // Optional badge like "Entry Point", "External API"
  }},
  "children": []               // Array of child nodes (empty for leaf nodes)
}}

ADDITIONAL FIELDS BY NODE TYPE:

For "phase" nodes, add:
  "phase_metadata": {{
    "phase_id": "1",
    "phase_purpose": "Purpose description"
  }}

For "step" nodes, add:
  "step_metadata": {{
    "step_id": "1.1",
    "source_nodes": ["input1", "input2"],
    "target_nodes": ["output1"],
    "process_script": "path/to/script.py",
    "notes": "Optional notes about decision logic"
  }},
  "connections": [
    {{"target_id": "step-1.2", "label": "passes data", "direction": "outgoing"}}
  ]

For "file" nodes, add:
  "file_metadata": {{
    "file_path": "relative/path/file.py",
    "language": "python",
    "github_url": "https://github.com/.../blob/main/path/file.py",
    "line_count": 100
  }}

For "function" nodes, add:
  "function_metadata": {{
    "function_name": "function_name",
    "file_path": "relative/path/file.py",
    "line_start": 10,
    "line_end": 50,
    "github_url": "https://github.com/.../blob/main/path/file.py#L10-L50",
    "signature": "def function_name(args):",
    "docstring": "Function docstring if available"
  }}

For "code_block" nodes (LEAF NODES), add:
  "code_metadata": {{
    "code": "actual\\nsource\\ncode\\nhere",
    "language": "python",
    "file_path": "relative/path/file.py",
    "line_start": 10,
    "line_end": 50,
    "github_url": "https://github.com/.../blob/main/path/file.py#L10-L50",
    "annotations": [
      {{"line": 3, "comment": "Explanation of what this line does"}}
    ]
  }}

================================================================================
CRITICAL RULES
================================================================================

1. **REAL CODE ONLY**: Extract actual code from the repository. Do NOT make up code.

2. **RELEVANT FUNCTIONS**: Only include functions that are part of the main execution flow.
   Skip utility functions, tests, and configuration unless they're critical.

3. **PROPER HIERARCHY**: Every step should drill down to files, then functions, then code.
   The iOS app will let users tap to zoom in at each level.

4. **GITHUB URLS**: Generate correct GitHub URLs with line numbers for code blocks:
   Format: https://github.com/owner/repo/blob/main/path/file.py#L10-L50

5. **CONNECTIONS**: Add "connections" to step nodes to show data flow between steps.

6. **SF SYMBOLS**: Use valid SF Symbol names for icons:
   - terminal, doc.text, function, gearshape, arrow.down.doc
   - play.fill, list.bullet.rectangle, wand.and.stars
   - chevron.left.forwardslash.chevron.right (for code)

7. **COLORS**: Use a consistent color palette:
   - Phase backgrounds: Light pastels (#E8F4FD, #FFF3E0, #E8F5E9, etc.)
   - Step boxes: Saturated versions (#4A90D9, #FF9800, #4CAF50, etc.)
   - Code: Language-specific (#3776AB for Python, #F7DF1E for JS, etc.)

8. **EMPTY CHILDREN**: Leaf nodes (code_block) MUST have "children": []

================================================================================
OUTPUT FORMAT
================================================================================

- Respond with VALID JSON ONLY
- Do NOT wrap in markdown code blocks
- Do NOT include any explanation or commentary
- The response must be directly parseable as JSON
- Escape special characters in code strings properly (newlines as \\n, quotes as \\", etc.)

================================================================================
"""
    
    return prompt


def build_code_extraction_prompt(repo_url: str, file_path: str, function_name: str) -> str:
    """
    Build a prompt to extract a specific function's code from a repository.
    
    This is used as a follow-up call if the main analysis doesn't include
    enough code detail.
    
    Args:
        repo_url: Full GitHub repository URL
        file_path: Path to the file within the repository
        function_name: Name of the function to extract
        
    Returns:
        Prompt string for code extraction
    """
    
    prompt = f"""
Extract the complete source code for the function "{function_name}" from the file "{file_path}" 
in the repository at {repo_url}.

Return a JSON object with this structure:
{{
  "function_name": "{function_name}",
  "file_path": "{file_path}",
  "line_start": <starting line number>,
  "line_end": <ending line number>,
  "code": "<complete function code with proper escaping>",
  "signature": "<function signature>",
  "docstring": "<docstring if present, null otherwise>",
  "language": "<programming language>"
}}

RULES:
- Extract the COMPLETE function including decorators, docstrings, and all code
- Properly escape special characters (newlines as \\n, quotes as \\", backslashes as \\\\)
- Include accurate line numbers
- Return ONLY valid JSON, no markdown or explanation
"""
    
    return prompt


# Color palette for consistent styling
PHASE_COLORS = {
    "1. Ingestion": {
        "background": "#E8F4FD",
        "accent": "#4A90D9",
        "icon": "arrow.down.doc"
    },
    "2. Cleaning & Normalization": {
        "background": "#FFF3E0",
        "accent": "#FF9800",
        "icon": "wand.and.stars"
    },
    "3. Feature Engineering": {
        "background": "#F3E5F5",
        "accent": "#9C27B0",
        "icon": "cpu"
    },
    "4. Modeling / Computation": {
        "background": "#E8F5E9",
        "accent": "#4CAF50",
        "icon": "brain"
    },
    "5. Optimization / Post-Processing": {
        "background": "#FFF8E1",
        "accent": "#FFC107",
        "icon": "slider.horizontal.3"
    },
    "6. Reporting / Export": {
        "background": "#E3F2FD",
        "accent": "#2196F3",
        "icon": "square.and.arrow.up"
    }
}

# Language-specific colors for code highlighting context
LANGUAGE_COLORS = {
    "python": "#3776AB",
    "javascript": "#F7DF1E",
    "typescript": "#3178C6",
    "java": "#ED8B00",
    "go": "#00ADD8",
    "rust": "#DEA584",
    "ruby": "#CC342D",
    "php": "#777BB4",
    "swift": "#FA7343",
    "kotlin": "#7F52FF",
    "c": "#A8B9CC",
    "cpp": "#00599C",
    "csharp": "#239120",
    "default": "#6E7681"
}


def get_phase_styling(phase_name: str) -> dict:
    """
    Get the visual styling for a phase based on its name.
    
    Args:
        phase_name: The phase name (e.g., "1. Ingestion")
        
    Returns:
        Dictionary with background, accent, and icon
    """
    return PHASE_COLORS.get(phase_name, {
        "background": "#F5F5F5",
        "accent": "#757575",
        "icon": "questionmark.circle"
    })


def get_language_color(language: str) -> str:
    """
    Get the color associated with a programming language.
    
    Args:
        language: Programming language name (lowercase)
        
    Returns:
        Hex color string
    """
    return LANGUAGE_COLORS.get(language.lower(), LANGUAGE_COLORS["default"])
