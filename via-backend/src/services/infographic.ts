/**
 * Infographic Generation Service
 * 
 * Generates interactive hierarchical JSON from GitHub repositories
 * using GLM-4.7 via Cerebras.
 * 
 * This service:
 * 1. Fetches actual file contents from GitHub API
 * 2. Passes real code to the LLM for analysis
 * 3. Generates hierarchical infographic JSON with correct file paths
 */

import { logger } from '../utils/logger.js';

// Configuration - Using Cerebras directly
const CEREBRAS_API_URL = 'https://api.cerebras.ai/v1/chat/completions';
const DEFAULT_MODEL = 'zai-glm-4.7';
const GITHUB_API_BASE = 'https://api.github.com';

// File extensions to include in analysis
const SOURCE_EXTENSIONS = [
  '.py', '.js', '.ts', '.tsx', '.jsx', '.swift', '.kt', '.java',
  '.go', '.rs', '.rb', '.php', '.c', '.cpp', '.h', '.hpp',
  '.cs', '.scala', '.clj', '.ex', '.exs', '.vue', '.svelte'
];

// Files to skip
const SKIP_PATTERNS = [
  'node_modules', '__pycache__', '.git', 'dist', 'build',
  'venv', '.env', 'package-lock.json', 'yarn.lock',
  '.min.js', '.bundle.js', 'test', 'tests', 'spec', '__tests__'
];

// Max file size to fetch (50KB)
const MAX_FILE_SIZE = 50 * 1024;

// Max total content to send to LLM (chars) - reduced to avoid token limits
const MAX_TOTAL_CONTENT = 30000;

// Phase colors for consistent styling
const PHASE_COLORS: Record<string, { background: string; accent: string; icon: string }> = {
  '1. Ingestion': { background: '#E8F4FD', accent: '#4A90D9', icon: 'arrow.down.doc' },
  '2. Cleaning & Normalization': { background: '#FFF3E0', accent: '#FF9800', icon: 'wand.and.stars' },
  '3. Feature Engineering': { background: '#F3E5F5', accent: '#9C27B0', icon: 'cpu' },
  '4. Modeling / Computation': { background: '#E8F5E9', accent: '#4CAF50', icon: 'brain' },
  '5. Optimization / Post-Processing': { background: '#FFF8E1', accent: '#FFC107', icon: 'slider.horizontal.3' },
  '6. Reporting / Export': { background: '#E3F2FD', accent: '#2196F3', icon: 'square.and.arrow.up' },
};

// Types
interface InfographicNode {
  id: string;
  type: string;
  label: string;
  description?: string;
  visual_hint?: {
    icon?: string;
    color?: string;
    badge?: string;
  };
  children: InfographicNode[];
  phase_metadata?: Record<string, unknown>;
  step_metadata?: Record<string, unknown>;
  file_metadata?: Record<string, unknown>;
  function_metadata?: Record<string, unknown>;
  code_metadata?: Record<string, unknown>;
  connections?: Array<{ target_id: string; label?: string; direction?: string }>;
}

interface InfographicData {
  version: string;
  schema: string;
  repo_url: string;
  repo_name: string;
  repo_summary: string;
  pipeline_overview?: string;
  generated_at: string;
  root: InfographicNode;
}

// GitHub API types
interface GitHubTreeItem {
  path: string;
  mode: string;
  type: 'blob' | 'tree';
  sha: string;
  size?: number;
  url: string;
}

interface GitHubTree {
  sha: string;
  url: string;
  tree: GitHubTreeItem[];
  truncated: boolean;
}

interface GitHubContent {
  name: string;
  path: string;
  sha: string;
  size: number;
  content?: string;
  encoding?: string;
}

interface RepoFile {
  path: string;
  content: string;
  size: number;
  language: string;
}

/**
 * Parse owner and repo from GitHub URL
 */
function parseGitHubUrl(url: string): { owner: string; repo: string } | null {
  const match = url.match(/github\.com\/([^\/]+)\/([^\/]+)/);
  if (!match) return null;
  return { owner: match[1], repo: match[2].replace(/\.git$/, '') };
}

/**
 * Detect language from file extension
 */
function detectLanguage(path: string): string {
  const ext = path.substring(path.lastIndexOf('.')).toLowerCase();
  const langMap: Record<string, string> = {
    '.py': 'python',
    '.js': 'javascript',
    '.ts': 'typescript',
    '.tsx': 'typescript',
    '.jsx': 'javascript',
    '.swift': 'swift',
    '.kt': 'kotlin',
    '.java': 'java',
    '.go': 'go',
    '.rs': 'rust',
    '.rb': 'ruby',
    '.php': 'php',
    '.c': 'c',
    '.cpp': 'cpp',
    '.h': 'c',
    '.hpp': 'cpp',
    '.cs': 'csharp',
    '.scala': 'scala',
    '.vue': 'vue',
    '.svelte': 'svelte',
  };
  return langMap[ext] || 'text';
}

/**
 * Check if a file should be included in analysis
 */
function shouldIncludeFile(path: string, size?: number): boolean {
  // Check extension
  const hasSourceExt = SOURCE_EXTENSIONS.some(ext => path.toLowerCase().endsWith(ext));
  if (!hasSourceExt) return false;
  
  // Check skip patterns
  const shouldSkip = SKIP_PATTERNS.some(pattern => path.toLowerCase().includes(pattern.toLowerCase()));
  if (shouldSkip) return false;
  
  // Check size
  if (size && size > MAX_FILE_SIZE) return false;
  
  return true;
}

/**
 * Fetch repository file tree from GitHub API
 */
async function fetchRepoTree(owner: string, repo: string): Promise<GitHubTreeItem[]> {
  const url = `${GITHUB_API_BASE}/repos/${owner}/${repo}/git/trees/main?recursive=1`;
  logger.info(`[GitHub] Fetching tree: ${url}`);
  
  const response = await fetch(url, {
    headers: {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'InfographicViewer/1.0',
    },
  });
  
  if (!response.ok) {
    // Try 'master' branch if 'main' fails
    const masterUrl = `${GITHUB_API_BASE}/repos/${owner}/${repo}/git/trees/master?recursive=1`;
    logger.info(`[GitHub] main branch failed, trying master: ${masterUrl}`);
    const masterResponse = await fetch(masterUrl, {
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'InfographicViewer/1.0',
      },
    });
    
    if (!masterResponse.ok) {
      // Check if repo exists at all (to distinguish private vs non-existent)
      const repoCheckUrl = `${GITHUB_API_BASE}/repos/${owner}/${repo}`;
      const repoCheckResponse = await fetch(repoCheckUrl, {
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'InfographicViewer/1.0',
        },
      });
      
      if (repoCheckResponse.status === 404) {
        throw new Error(`PRIVATE_OR_NOT_FOUND: The repository "${owner}/${repo}" is either private or does not exist. Only public repositories are supported.`);
      }
      
      throw new Error(`GitHub API error: ${response.status} - Could not fetch repository tree`);
    }
    
    const data = await masterResponse.json() as GitHubTree;
    return data.tree;
  }
  
  const data = await response.json() as GitHubTree;
  return data.tree;
}

/**
 * Fetch file content from GitHub API
 */
async function fetchFileContent(owner: string, repo: string, path: string): Promise<string | null> {
  const url = `${GITHUB_API_BASE}/repos/${owner}/${repo}/contents/${path}`;
  
  const response = await fetch(url, {
    headers: {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'InfographicViewer/1.0',
    },
  });
  
  if (!response.ok) {
    logger.warn(`[GitHub] Failed to fetch ${path}: ${response.status}`);
    return null;
  }
  
  const data = await response.json() as GitHubContent;
  
  if (data.content && data.encoding === 'base64') {
    return Buffer.from(data.content, 'base64').toString('utf-8');
  }
  
  return null;
}

/**
 * Fetch all relevant source files from a GitHub repository
 */
async function fetchRepoFiles(repoUrl: string): Promise<{ files: RepoFile[]; fileList: string[] }> {
  const parsed = parseGitHubUrl(repoUrl);
  if (!parsed) {
    throw new Error('Invalid GitHub URL format');
  }
  
  const { owner, repo } = parsed;
  logger.info(`[GitHub] Fetching files for ${owner}/${repo}`);
  
  // Get file tree
  const tree = await fetchRepoTree(owner, repo);
  logger.info(`[GitHub] Found ${tree.length} items in tree`);
  
  // Filter to source files
  const sourceFiles = tree.filter(item => 
    item.type === 'blob' && shouldIncludeFile(item.path, item.size)
  );
  logger.info(`[GitHub] Filtered to ${sourceFiles.length} source files`);
  
  // Sort by likely importance (entry points first, then by size)
  const priorityFiles = ['main', 'index', 'app', 'server', 'cli', '__main__'];
  sourceFiles.sort((a, b) => {
    const aName = a.path.toLowerCase();
    const bName = b.path.toLowerCase();
    const aPriority = priorityFiles.findIndex(p => aName.includes(p));
    const bPriority = priorityFiles.findIndex(p => bName.includes(p));
    if (aPriority !== -1 && bPriority === -1) return -1;
    if (bPriority !== -1 && aPriority === -1) return 1;
    if (aPriority !== -1 && bPriority !== -1) return aPriority - bPriority;
    return (a.size || 0) - (b.size || 0); // Smaller files first (often more important)
  });
  
  // Fetch file contents (limit to avoid rate limits and token limits)
  const files: RepoFile[] = [];
  let totalContent = 0;
  const maxFiles = 20;
  
  for (const item of sourceFiles.slice(0, maxFiles)) {
    if (totalContent >= MAX_TOTAL_CONTENT) {
      logger.info(`[GitHub] Reached content limit at ${totalContent} chars`);
      break;
    }
    
    const content = await fetchFileContent(owner, repo, item.path);
    if (content) {
      const truncatedContent = content.slice(0, MAX_TOTAL_CONTENT - totalContent);
      files.push({
        path: item.path,
        content: truncatedContent,
        size: item.size || truncatedContent.length,
        language: detectLanguage(item.path),
      });
      totalContent += truncatedContent.length;
      logger.info(`[GitHub] Fetched ${item.path} (${truncatedContent.length} chars)`);
    }
  }
  
  // Also return full file list for reference
  const fileList = sourceFiles.map(f => f.path);
  
  logger.info(`[GitHub] Fetched ${files.length} files, ${totalContent} total chars`);
  return { files, fileList };
}

/**
 * Build the analysis prompt for the LLM with actual file contents
 */
function buildAnalysisPromptWithFiles(repoUrl: string, files: RepoFile[], fileList: string[]): string {
  // Build file contents section
  let fileContentsSection = '';
  if (files.length > 0) {
    fileContentsSection = `
================================================================================
ACTUAL FILE CONTENTS FROM THE REPOSITORY
================================================================================

The following are the ACTUAL source files from this repository. Use ONLY these files
and their exact paths in your analysis. Do NOT invent file paths or code.

`;
    for (const file of files) {
      fileContentsSection += `
--- FILE: ${file.path} (${file.language}) ---
${file.content}
--- END FILE ---

`;
    }
    
    // Add list of all files for reference
    if (fileList.length > files.length) {
      fileContentsSection += `
--- ADDITIONAL FILES IN REPOSITORY (not shown) ---
${fileList.filter(f => !files.some(ff => ff.path === f)).join('\n')}
--- END FILE LIST ---

`;
    }
  }

  return `
You are a Principal Systems Architect with expertise in code analysis. Your task is to analyze the GitHub repository at:
${repoUrl}

You must produce a HIERARCHICAL JSON structure that an iOS app can use for interactive drill-down navigation.
The user will tap on elements to zoom in and see more detail, recursively, until they reach the actual code.
${fileContentsSection}
================================================================================
ANALYSIS INSTRUCTIONS
================================================================================

1. **ANALYZE THE PROVIDED CODE**
   - Study the actual source files provided above
   - Understand the project structure and dependencies
   - Identify the programming language(s) used

2. **IDENTIFY ENTRY POINTS**
   - Find main entry points from the provided files
   - Identify CLI entry points, web routes, or event handlers
   - Note which files are the "starting points" of execution

3. **TRACE EXECUTION FLOW**
   - Follow the code execution path from entry points
   - Map out which functions call which other functions
   - Identify data transformations and I/O operations

4. **EXTRACT RELEVANT CODE**
   - For each function/class, use the EXACT code from the files provided above
   - Include ONLY the relevant functions, not entire files
   - Use the EXACT file paths from the provided files

5. **BUILD THE HIERARCHY**
   Create a tree with these levels (use as many as appropriate):
   
   Level 0: REPO (root)
      └── Level 1: PHASE (pipeline phases like Ingestion, Processing, Output)
             └── Level 2: STEP (specific processing steps)
                    └── Level 3: FILE (source files - USE EXACT PATHS FROM PROVIDED FILES)
                           └── Level 4: FUNCTION (functions/classes)
                                  └── Level 5: CODE_BLOCK (actual code FROM PROVIDED FILES)

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

{
  "version": "2.0",
  "schema": "interactive-infographic",
  "repo_url": "${repoUrl}",
  "repo_name": "short-name",
  "repo_summary": "1-3 sentence description",
  "pipeline_overview": "1-2 sentence pipeline summary",
  "generated_at": "${new Date().toISOString()}",
  "root": {
    "id": "root",
    "type": "repo",
    "label": "Repository Name",
    "description": "Short description",
    "visual_hint": {
      "icon": "appropriate_sf_symbol",
      "color": "#hexcolor"
    },
    "children": [
      // Array of phase nodes
    ]
  }
}

================================================================================
NODE STRUCTURE
================================================================================

Each node in the tree MUST have:

{
  "id": "unique-id",           // e.g., "phase-1", "step-1.1", "func-main"
  "type": "node_type",         // One of: repo, phase, step, file, function, code_block
  "label": "Display Name",     // Short name for UI
  "description": "Brief desc", // 5-15 words
  "visual_hint": {
    "icon": "sf_symbol_name",  // SF Symbol for iOS (e.g., "terminal", "doc.text", "function")
    "color": "#hexcolor",      // Hex color for styling
    "badge": "optional"        // Optional badge like "Entry Point", "External API"
  },
  "children": []               // Array of child nodes (empty for leaf nodes)
}

ADDITIONAL FIELDS BY NODE TYPE:

For "phase" nodes, add:
  "phase_metadata": {
    "phase_id": "1",
    "phase_purpose": "Purpose description"
  }

For "step" nodes, add:
  "step_metadata": {
    "step_id": "1.1",
    "source_nodes": ["input1", "input2"],
    "target_nodes": ["output1"],
    "process_script": "path/to/script.py",
    "notes": "Optional notes about decision logic"
  },
  "connections": [
    {"target_id": "step-1.2", "label": "passes data", "direction": "outgoing"}
  ]

For "file" nodes, add:
  "file_metadata": {
    "file_path": "relative/path/file.py",
    "language": "python",
    "github_url": "https://github.com/.../blob/main/path/file.py",
    "line_count": 100
  }

For "function" nodes, add:
  "function_metadata": {
    "function_name": "function_name",
    "file_path": "relative/path/file.py",
    "line_start": 10,
    "line_end": 50,
    "github_url": "https://github.com/.../blob/main/path/file.py#L10-L50",
    "signature": "def function_name(args):",
    "docstring": "Function docstring if available"
  }

For "code_block" nodes (LEAF NODES), add:
  "code_metadata": {
    "code": "actual\\nsource\\ncode\\nhere",
    "language": "python",
    "file_path": "relative/path/file.py",
    "line_start": 10,
    "line_end": 50,
    "github_url": "https://github.com/.../blob/main/path/file.py#L10-L50",
    "annotations": [
      {"line": 3, "comment": "Explanation of what this line does"}
    ]
  }

================================================================================
CRITICAL RULES
================================================================================

1. **REAL CODE ONLY**: Use ONLY code from the files provided above. Do NOT make up code or file paths.

2. **EXACT FILE PATHS**: The file_path fields MUST match the exact paths from the provided files above.

3. **RELEVANT FUNCTIONS**: Only include functions that are part of the main execution flow.
   Skip utility functions, tests, and configuration unless they're critical.

4. **PROPER HIERARCHY**: Every step should drill down to files, then functions, then code.
   The iOS app will let users tap to zoom in at each level.

5. **GITHUB URLS**: Generate correct GitHub URLs with line numbers for code blocks:
   Format: https://github.com/owner/repo/blob/main/path/file.py#L10-L50

6. **CONNECTIONS**: Add "connections" to step nodes to show data flow between steps.

7. **SF SYMBOLS**: Use valid SF Symbol names for icons:
   - terminal, doc.text, function, gearshape, arrow.down.doc
   - play.fill, list.bullet.rectangle, wand.and.stars
   - chevron.left.forwardslash.chevron.right (for code)

8. **COLORS**: Use a consistent color palette:
   - Phase backgrounds: Light pastels (#E8F4FD, #FFF3E0, #E8F5E9, etc.)
   - Step boxes: Saturated versions (#4A90D9, #FF9800, #4CAF50, etc.)
   - Code: Language-specific (#3776AB for Python, #F7DF1E for JS, etc.)

9. **EMPTY CHILDREN**: Leaf nodes (code_block) MUST have "children": []

10. **VALID JSON**: All strings must be properly escaped:
    - Newlines as \\n
    - Tabs as \\t  
    - Quotes as \\"
    - Backslashes as \\\\

================================================================================
OUTPUT FORMAT
================================================================================

- Respond with VALID JSON ONLY
- Do NOT wrap in markdown code blocks
- Do NOT include any explanation or commentary
- The response must be directly parseable as JSON
- Escape special characters in code strings properly

================================================================================
`;
}

/**
 * Extract JSON from a response that may contain markdown or other text
 */
function extractJsonFromResponse(raw: string): string {
  let text = raw.trim();
  
  // Try to find JSON within markdown code blocks
  if (text.includes('```')) {
    const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch) {
      text = jsonMatch[1].trim();
    }
  }
  
  // Find raw JSON (first { to last })
  const jsonStart = text.indexOf('{');
  const jsonEnd = text.lastIndexOf('}');
  if (jsonStart !== -1 && jsonEnd !== -1 && jsonEnd > jsonStart) {
    return text.slice(jsonStart, jsonEnd + 1);
  }
  
  return text;
}

/**
 * Sanitize JSON string by escaping unescaped control characters inside string values
 */
function sanitizeJsonString(raw: string): string {
  // This is a simplified sanitizer - it attempts to fix common issues
  // where LLMs output raw newlines/tabs inside JSON string values
  
  let result = '';
  let inString = false;
  let escaped = false;
  
  for (let i = 0; i < raw.length; i++) {
    const char = raw[i];
    
    if (escaped) {
      result += char;
      escaped = false;
      continue;
    }
    
    if (char === '\\') {
      result += char;
      escaped = true;
      continue;
    }
    
    if (char === '"') {
      inString = !inString;
      result += char;
      continue;
    }
    
    if (inString) {
      // Replace raw control characters with escaped versions
      if (char === '\n') {
        result += '\\n';
      } else if (char === '\r') {
        result += '\\r';
      } else if (char === '\t') {
        result += '\\t';
      } else if (char.charCodeAt(0) < 32) {
        // Other control characters
        result += '\\u' + char.charCodeAt(0).toString(16).padStart(4, '0');
      } else {
        result += char;
      }
    } else {
      result += char;
    }
  }
  
  return result;
}

/**
 * Attempt to repair common JSON issues from LLM output
 */
function repairJson(raw: string): string {
  let text = raw;
  
  // First, sanitize control characters in strings
  text = sanitizeJsonString(text);
  
  // Try to parse - if it works, we're done
  try {
    JSON.parse(text);
    return text;
  } catch (e) {
    // Continue with repairs
  }
  
  // Fix trailing commas in arrays and objects
  text = text.replace(/,\s*([}\]])/g, '$1');
  
  // Fix missing commas between array elements (common LLM mistake)
  // Look for patterns like: } { or ] [ or " " (without comma)
  text = text.replace(/}\s*{/g, '},{');
  text = text.replace(/]\s*\[/g, '],[');
  text = text.replace(/"\s*"/g, '","');
  text = text.replace(/}\s*"/g, '},"');
  text = text.replace(/"\s*{/g, '",{');
  text = text.replace(/]\s*"/g, '],"');
  text = text.replace(/"\s*\[/g, '",[');
  text = text.replace(/}\s*\[/g, '},[');
  text = text.replace(/]\s*{/g, '],{');
  
  // Fix numbers followed by strings without comma
  text = text.replace(/(\d)\s*"/g, '$1,"');
  text = text.replace(/(\d)\s*{/g, '$1,{');
  text = text.replace(/(\d)\s*\[/g, '$1,[');
  
  // Fix true/false/null followed by other values without comma
  text = text.replace(/(true|false|null)\s*"/g, '$1,"');
  text = text.replace(/(true|false|null)\s*{/g, '$1,{');
  text = text.replace(/(true|false|null)\s*\[/g, '$1,[');
  
  // Fix unescaped quotes inside strings (very common LLM issue)
  // This is tricky - we need to find strings and escape internal quotes
  text = fixUnescapedQuotesInStrings(text);
  
  // Fix truncated JSON by closing open brackets/braces
  text = closeTruncatedJson(text);
  
  return text;
}

/**
 * Fix unescaped quotes inside JSON string values
 */
function fixUnescapedQuotesInStrings(json: string): string {
  // This attempts to fix cases where the LLM outputs:
  // "code": "print("hello")"  -> should be "code": "print(\"hello\")"
  
  let result = '';
  let i = 0;
  
  while (i < json.length) {
    // Find start of a string value (after a colon)
    if (json[i] === ':') {
      result += json[i];
      i++;
      
      // Skip whitespace
      while (i < json.length && /\s/.test(json[i])) {
        result += json[i];
        i++;
      }
      
      // Check if this is a string value
      if (i < json.length && json[i] === '"') {
        result += json[i]; // Opening quote
        i++;
        
        // Process string content
        while (i < json.length) {
          if (json[i] === '\\' && i + 1 < json.length) {
            // Already escaped character - keep as is
            result += json[i] + json[i + 1];
            i += 2;
          } else if (json[i] === '"') {
            // Check if this is the end of the string
            // Look ahead to see if next non-whitespace is , or } or ]
            let lookAhead = i + 1;
            while (lookAhead < json.length && /\s/.test(json[lookAhead])) {
              lookAhead++;
            }
            if (lookAhead >= json.length || /[,}\]]/.test(json[lookAhead])) {
              // This is the closing quote
              result += json[i];
              i++;
              break;
            } else {
              // This is an unescaped quote inside the string - escape it
              result += '\\"';
              i++;
            }
          } else if (json[i] === '\n' || json[i] === '\r' || json[i] === '\t') {
            // Raw control characters - escape them
            if (json[i] === '\n') result += '\\n';
            else if (json[i] === '\r') result += '\\r';
            else if (json[i] === '\t') result += '\\t';
            i++;
          } else {
            result += json[i];
            i++;
          }
        }
      } else {
        // Not a string value, continue normally
      }
    } else {
      result += json[i];
      i++;
    }
  }
  
  return result;
}

/**
 * Close truncated JSON by adding missing brackets/braces
 */
function closeTruncatedJson(json: string): string {
  const stack: string[] = [];
  let inString = false;
  let escaped = false;
  
  for (let i = 0; i < json.length; i++) {
    const char = json[i];
    
    if (escaped) {
      escaped = false;
      continue;
    }
    
    if (char === '\\') {
      escaped = true;
      continue;
    }
    
    if (char === '"') {
      inString = !inString;
      continue;
    }
    
    if (!inString) {
      if (char === '{') stack.push('}');
      else if (char === '[') stack.push(']');
      else if (char === '}' || char === ']') {
        if (stack.length > 0 && stack[stack.length - 1] === char) {
          stack.pop();
        }
      }
    }
  }
  
  // Close any unclosed brackets/braces
  while (stack.length > 0) {
    json += stack.pop();
  }
  
  return json;
}

/**
 * Infer node type based on depth
 */
function inferNodeType(depth: number): string {
  const types = ['repo', 'phase', 'step', 'file', 'function', 'code_block'];
  return types[Math.min(depth, types.length - 1)];
}

/**
 * Get default visual hint for a node type
 */
function getDefaultVisualHint(nodeType: string, label: string): { icon: string; color: string } {
  const defaults: Record<string, { icon: string; color: string }> = {
    repo: { icon: 'folder', color: '#4A90D9' },
    phase: { icon: 'rectangle.stack', color: '#E8F4FD' },
    step: { icon: 'arrow.right.circle', color: '#4A90D9' },
    file: { icon: 'doc.text', color: '#6E7681' },
    function: { icon: 'function', color: '#3776AB' },
    code_block: { icon: 'chevron.left.forwardslash.chevron.right', color: '#3776AB' },
  };
  
  // Special handling for phases
  if (nodeType === 'phase') {
    for (const [phaseName, styling] of Object.entries(PHASE_COLORS)) {
      if (label.includes(phaseName.split('.')[1]?.trim() || phaseName)) {
        return { icon: styling.icon, color: styling.background };
      }
    }
  }
  
  return defaults[nodeType] || { icon: 'questionmark.circle', color: '#757575' };
}

/**
 * Generate GitHub URL for a file with optional line numbers
 */
function generateGithubUrl(repoUrl: string, filePath: string, lineStart?: number, lineEnd?: number): string {
  const base = repoUrl.replace(/\/$/, '');
  let url = `${base}/blob/main/${filePath}`;
  
  if (lineStart !== undefined) {
    if (lineEnd !== undefined && lineEnd !== lineStart) {
      url += `#L${lineStart}-L${lineEnd}`;
    } else {
      url += `#L${lineStart}`;
    }
  }
  
  return url;
}

/**
 * Recursively enhance a node with proper styling and validation
 */
function enhanceNode(node: InfographicNode, repoUrl: string, depth: number = 0): InfographicNode {
  // Ensure required fields
  if (!node.id) {
    node.id = `node-${depth}-${Math.random().toString(36).slice(2, 8)}`;
  }
  if (!node.type) {
    node.type = inferNodeType(depth);
  }
  if (!node.label) {
    node.label = 'Unknown';
  }
  if (!node.children) {
    node.children = [];
  }
  
  // Add visual hints if missing
  if (!node.visual_hint) {
    node.visual_hint = getDefaultVisualHint(node.type, node.label);
  }
  
  // ALWAYS regenerate GitHub URLs to ensure correctness (LLM often gets them wrong)
  // For file nodes
  if (node.type === 'file' && node.file_metadata) {
    const meta = node.file_metadata as Record<string, unknown>;
    if (meta.file_path) {
      meta.github_url = generateGithubUrl(repoUrl, meta.file_path as string);
    }
  }
  
  // For function nodes
  if (node.type === 'function' && node.function_metadata) {
    const meta = node.function_metadata as Record<string, unknown>;
    if (meta.file_path) {
      meta.github_url = generateGithubUrl(
        repoUrl,
        meta.file_path as string,
        meta.line_start as number | undefined,
        meta.line_end as number | undefined
      );
    }
  }
  
  // For code_block nodes
  if (node.type === 'code_block' && node.code_metadata) {
    const meta = node.code_metadata as Record<string, unknown>;
    if (meta.file_path) {
      meta.github_url = generateGithubUrl(
        repoUrl,
        meta.file_path as string,
        meta.line_start as number | undefined,
        meta.line_end as number | undefined
      );
    }
  }
  
  // Recursively enhance children
  node.children = node.children.map(child => enhanceNode(child, repoUrl, depth + 1));
  
  return node;
}

/**
 * Validate and enhance the generated JSON
 */
function validateAndEnhanceJson(data: InfographicData, repoUrl: string): InfographicData {
  // Ensure required top-level fields
  if (!data.version) data.version = '2.0';
  if (!data.schema) data.schema = 'interactive-infographic';
  if (!data.repo_url) data.repo_url = repoUrl;
  if (!data.generated_at) data.generated_at = new Date().toISOString();
  
  // Validate and enhance the tree structure
  if (data.root) {
    data.root = enhanceNode(data.root, repoUrl);
  }
  
  return data;
}

/**
 * Calculate statistics about the generated JSON
 */
function calculateStatistics(data: InfographicData): Record<string, number> {
  const stats = {
    total_nodes: 0,
    phases: 0,
    steps: 0,
    files: 0,
    functions: 0,
    code_blocks: 0,
    max_depth: 0,
    total_code_lines: 0,
  };
  
  function countNodes(node: InfographicNode, depth: number = 0): void {
    stats.total_nodes++;
    stats.max_depth = Math.max(stats.max_depth, depth);
    
    switch (node.type) {
      case 'phase': stats.phases++; break;
      case 'step': stats.steps++; break;
      case 'file': stats.files++; break;
      case 'function': stats.functions++; break;
      case 'code_block':
        stats.code_blocks++;
        if (node.code_metadata && typeof (node.code_metadata as Record<string, unknown>).code === 'string') {
          stats.total_code_lines += ((node.code_metadata as Record<string, unknown>).code as string).split('\n').length;
        }
        break;
    }
    
    for (const child of node.children) {
      countNodes(child, depth + 1);
    }
  }
  
  if (data.root) {
    countNodes(data.root);
  }
  
  return stats;
}

/**
 * Generate an interactive infographic from a GitHub repository
 * Includes retry logic for intermittent LLM failures
 */
export async function generateInfographic(
  repoUrl: string,
  cerebrasApiKey: string,
  model: string = DEFAULT_MODEL
): Promise<{ data: InfographicData; stats: Record<string, number> }> {
  const MAX_RETRIES = 2;
  let lastError: Error | null = null;
  
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      logger.info(`[Infographic] Attempt ${attempt}/${MAX_RETRIES} for: ${repoUrl}`);
      return await generateInfographicInternal(repoUrl, cerebrasApiKey, model);
    } catch (error) {
      lastError = error as Error;
      logger.warn(`[Infographic] Attempt ${attempt} failed: ${lastError.message}`);
      
      // Don't retry for certain errors
      if (lastError.message.includes('private or does not exist') ||
          lastError.message.includes('Invalid GitHub URL') ||
          lastError.message.includes('Rate limited')) {
        throw lastError;
      }
      
      if (attempt < MAX_RETRIES) {
        logger.info(`[Infographic] Retrying in 2 seconds...`);
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    }
  }
  
  throw lastError || new Error('Failed to generate infographic');
}

/**
 * Internal implementation of infographic generation
 */
async function generateInfographicInternal(
  repoUrl: string,
  cerebrasApiKey: string,
  model: string = DEFAULT_MODEL
): Promise<{ data: InfographicData; stats: Record<string, number> }> {
  logger.info(`[Infographic] Starting generation for: ${repoUrl}`);
  logger.info(`[Infographic] Using model: ${model} (Cerebras)`);
  logger.info(`[Infographic] API key present: ${!!cerebrasApiKey}, length: ${cerebrasApiKey?.length || 0}`);
  
  // Validate URL
  if (!repoUrl.includes('github.com')) {
    throw new Error('Invalid GitHub URL. Use format: https://github.com/owner/repo');
  }
  
  // Fetch actual file contents from GitHub
  logger.info(`[Infographic] Fetching repository files from GitHub...`);
  let files: RepoFile[] = [];
  let fileList: string[] = [];
  try {
    const repoData = await fetchRepoFiles(repoUrl);
    files = repoData.files;
    fileList = repoData.fileList;
    logger.info(`[Infographic] Successfully fetched ${files.length} files (${fileList.length} total in repo)`);
  } catch (error) {
    const errorMessage = (error as Error).message;
    // Check if this is a private repo error - don't proceed, throw to user
    if (errorMessage.includes('PRIVATE_OR_NOT_FOUND')) {
      logger.error(`[Infographic] Repository is private or not found`);
      throw new Error('This repository is private or does not exist. Only public GitHub repositories are supported.');
    }
    logger.warn(`[Infographic] Failed to fetch repo files: ${errorMessage}`);
    logger.warn(`[Infographic] Proceeding without file contents (LLM will attempt to fetch)`);
  }
  
  // Build prompt with actual file contents
  const prompt = buildAnalysisPromptWithFiles(repoUrl, files, fileList);
  logger.info(`[Infographic] Prompt built (${prompt.length} chars, ${files.length} files included)`);
  
  // Call Cerebras directly
  const response = await fetch(CEREBRAS_API_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${cerebrasApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.1,
      max_tokens: 16000,
    }),
  });
  
  logger.info(`[Infographic] Cerebras HTTP status: ${response.status}`);
  
  if (response.status === 429) {
    throw new Error('Rate limited. Please wait a moment and try again.');
  }
  
  if (!response.ok) {
    const errorText = await response.text();
    logger.error(`[Infographic] Cerebras error (${response.status}): ${errorText}`);
    logger.error(`[Infographic] Request was for model: ${model}`);
    throw new Error(`Cerebras API error: ${response.status} - ${errorText.slice(0, 200)}`);
  }
  
  const resultText = await response.text();
  logger.info(`[Infographic] Raw response length: ${resultText.length}`);
  
  let result: {
    choices?: Array<{ message?: { content?: string } }>;
    error?: { message?: string };
  };
  
  try {
    result = JSON.parse(resultText);
  } catch (e) {
    logger.error(`[Infographic] Failed to parse Cerebras response: ${resultText.slice(0, 500)}`);
    throw new Error('Invalid response from Cerebras API');
  }
  
  if (result.error) {
    throw new Error(`OpenRouter error: ${result.error.message}`);
  }
  
  if (!result.choices?.[0]?.message?.content) {
    throw new Error('No response from model');
  }
  
  const rawContent = result.choices[0].message.content;
  logger.info(`[Infographic] Received response (${rawContent.length} chars)`);
  
  // Extract JSON
  let jsonString = extractJsonFromResponse(rawContent);
  logger.info(`[Infographic] Extracted JSON candidate (${jsonString.length} chars)`);
  
  // Try to parse, with multiple repair attempts
  let parsed: InfographicData;
  const parseAttempts = [
    { name: 'direct', fn: () => JSON.parse(jsonString) },
    { name: 'sanitized', fn: () => JSON.parse(sanitizeJsonString(jsonString)) },
    { name: 'repaired', fn: () => JSON.parse(repairJson(jsonString)) },
  ];
  
  let lastError: Error | null = null;
  for (const attempt of parseAttempts) {
    try {
      parsed = attempt.fn();
      logger.info(`[Infographic] JSON parsed successfully (${attempt.name})`);
      break;
    } catch (e) {
      lastError = e as Error;
      logger.warn(`[Infographic] Parse attempt '${attempt.name}' failed: ${lastError.message}`);
    }
  }
  
  if (!parsed!) {
    logger.error(`[Infographic] All JSON parse attempts failed`);
    logger.error(`[Infographic] First 500 chars: ${jsonString.slice(0, 500)}`);
    logger.error(`[Infographic] Last 500 chars: ${jsonString.slice(-500)}`);
    
    // Log the specific position of the error if available
    const posMatch = lastError?.message.match(/position (\d+)/);
    if (posMatch) {
      const pos = parseInt(posMatch[1]);
      logger.error(`[Infographic] Around error position: ...${jsonString.slice(Math.max(0, pos - 50), pos + 50)}...`);
    }
    
    throw new Error(`Failed to parse JSON from model response: ${lastError?.message}`);
  }
  
  // Validate and enhance
  logger.info(`[Infographic] Validating and enhancing JSON...`);
  const enhanced = validateAndEnhanceJson(parsed, repoUrl);
  
  // Calculate stats
  const stats = calculateStatistics(enhanced);
  logger.info(`[Infographic] Generation complete. Stats: ${JSON.stringify(stats)}`);
  
  return { data: enhanced, stats };
}
