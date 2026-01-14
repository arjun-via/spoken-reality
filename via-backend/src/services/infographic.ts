/**
 * Infographic Generation Service
 * 
 * Generates interactive hierarchical JSON from GitHub repositories
 * using Claude Opus 4.5 via OpenRouter.
 * 
 * This is a TypeScript port of the repo2interactive.py logic.
 */

import { logger } from '../utils/logger.js';

// Configuration
const OPENROUTER_API_URL = 'https://openrouter.ai/api/v1/chat/completions';
const DEFAULT_MODEL = 'moonshotai/kimi-k2-0905';

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

/**
 * Build the analysis prompt for the LLM
 */
function buildAnalysisPrompt(repoUrl: string): string {
  return `
You are a Principal Systems Architect with expertise in code analysis. Your task is to analyze the GitHub repository at:
${repoUrl}

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

9. **VALID JSON**: All strings must be properly escaped:
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
  
  return text;
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
  
  // Enhance GitHub URLs for code nodes
  if (node.type === 'code_block' && node.code_metadata) {
    const meta = node.code_metadata as Record<string, unknown>;
    if (!meta.github_url && meta.file_path) {
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
 */
export async function generateInfographic(
  repoUrl: string,
  openRouterApiKey: string,
  model: string = DEFAULT_MODEL
): Promise<{ data: InfographicData; stats: Record<string, number> }> {
  logger.info(`[Infographic] Starting generation for: ${repoUrl}`);
  logger.info(`[Infographic] Using model: ${model}`);
  logger.info(`[Infographic] API key present: ${!!openRouterApiKey}, length: ${openRouterApiKey?.length || 0}`);
  
  // Validate URL
  if (!repoUrl.includes('github.com')) {
    throw new Error('Invalid GitHub URL. Use format: https://github.com/owner/repo');
  }
  
  // Build prompt
  const prompt = buildAnalysisPrompt(repoUrl);
  logger.info(`[Infographic] Prompt built (${prompt.length} chars)`);
  
  // Call OpenRouter
  const response = await fetch(OPENROUTER_API_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openRouterApiKey}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://github.com/infographic-viewer',
      'X-Title': 'InfographicViewer',
    },
    body: JSON.stringify({
      model,
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.2,
      max_tokens: 32000,
    }),
  });
  
  logger.info(`[Infographic] OpenRouter HTTP status: ${response.status}`);
  
  if (response.status === 429) {
    throw new Error('Rate limited. Please wait a moment and try again.');
  }
  
  if (!response.ok) {
    const errorText = await response.text();
    logger.error(`[Infographic] OpenRouter error (${response.status}): ${errorText}`);
    logger.error(`[Infographic] Request was for model: ${model}`);
    throw new Error(`OpenRouter API error: ${response.status} - ${errorText.slice(0, 200)}`);
  }
  
  const result = await response.json() as {
    choices?: Array<{ message?: { content?: string } }>;
    error?: { message?: string };
  };
  
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
  
  // Try to parse, with repair fallback
  let parsed: InfographicData;
  try {
    parsed = JSON.parse(jsonString);
  } catch (e1) {
    logger.warn(`[Infographic] Initial parse failed: ${(e1 as Error).message}`);
    logger.warn(`[Infographic] Attempting JSON repair...`);
    try {
      const repaired = repairJson(jsonString);
      parsed = JSON.parse(repaired);
      logger.info(`[Infographic] Repaired JSON parsed successfully`);
    } catch (e2) {
      logger.error(`[Infographic] JSON parse failed after repair`);
      logger.error(`[Infographic] First 500 chars: ${jsonString.slice(0, 500)}`);
      logger.error(`[Infographic] Last 500 chars: ${jsonString.slice(-500)}`);
      throw new Error(`Failed to parse JSON from model response: ${(e2 as Error).message}`);
    }
  }
  
  // Validate and enhance
  logger.info(`[Infographic] Validating and enhancing JSON...`);
  const enhanced = validateAndEnhanceJson(parsed, repoUrl);
  
  // Calculate stats
  const stats = calculateStatistics(enhanced);
  logger.info(`[Infographic] Generation complete. Stats: ${JSON.stringify(stats)}`);
  
  return { data: enhanced, stats };
}
