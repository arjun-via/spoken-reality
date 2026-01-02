/**
 * AI Orchestrator
 * 
 * Handles intent parsing and code generation via Claude Sonnet 4.5.
 * Uses direct Anthropic API with tool use for sandbox operations.
 * 
 * Model: claude-sonnet-4-5-20250929
 * Context: 200K tokens
 * Cost: $3/1M input, $15/1M output
 */

import Anthropic from '@anthropic-ai/sdk';
import { env } from '../config/env.js';
import { logger } from '../utils/logger.js';
import { AIError } from '../utils/errors.js';
import * as SandboxManager from './SandboxManager.js';

// Initialize Anthropic client
const anthropic = new Anthropic({
  apiKey: env.ANTHROPIC_API_KEY,
});

// Model to use
const MODEL = 'claude-sonnet-4-5-20250929'; // Claude Sonnet 4.5

// ============================================
// TYPES
// ============================================

export interface ProjectFile {
  path: string;
  content: string;
}

export interface AgentResult {
  success: boolean;
  files: ProjectFile[];
  explanation: string;
  needsClarification: boolean;
  clarificationQuestion?: string;
  error?: string;
}

// ============================================
// TOOL DEFINITIONS
// ============================================

const tools: Anthropic.Tool[] = [
  {
    name: 'write_file',
    description: 'Write a file to the project. Use this to create or update files.',
    input_schema: {
      type: 'object' as const,
      properties: {
        path: {
          type: 'string',
          description: 'File path relative to project root (e.g., "app/page.tsx")',
        },
        content: {
          type: 'string',
          description: 'Complete file content',
        },
      },
      required: ['path', 'content'],
    },
  },
  {
    name: 'read_file',
    description: 'Read a file from the project to understand existing code.',
    input_schema: {
      type: 'object' as const,
      properties: {
        path: {
          type: 'string',
          description: 'File path relative to project root',
        },
      },
      required: ['path'],
    },
  },
  {
    name: 'list_files',
    description: 'List files in a directory to understand project structure.',
    input_schema: {
      type: 'object' as const,
      properties: {
        path: {
          type: 'string',
          description: 'Directory path (defaults to root if empty)',
        },
      },
      required: [],
    },
  },
  {
    name: 'run_command',
    description: 'Run a shell command (e.g., npm install). Do NOT use for long-running commands like npm run dev.',
    input_schema: {
      type: 'object' as const,
      properties: {
        command: {
          type: 'string',
          description: 'Shell command to run',
        },
      },
      required: ['command'],
    },
  },
];

// ============================================
// SYSTEM PROMPT
// ============================================

const SYSTEM_PROMPT = `You are Via, an AI assistant for voice-first app development. You help users build production-grade Next.js applications.

## Your Capabilities
You have tools to:
1. write_file - Create or update files
2. read_file - Read existing files
3. list_files - List directory contents
4. run_command - Run shell commands (npm install, etc.)

## Tech Stack (MUST USE THESE EXACT VERSIONS)
- Next.js 14.2.5 (App Router)
- TypeScript 5
- Tailwind CSS 3.4 (NOT v4!)
- React 18.2

## CRITICAL: Tailwind CSS Configuration
You MUST use Tailwind CSS v3 configuration. DO NOT use @tailwindcss/postcss.

postcss.config.mjs MUST be:
\`\`\`js
const config = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
export default config;
\`\`\`

tailwind.config.ts MUST be:
\`\`\`ts
import type { Config } from 'tailwindcss';
const config: Config = {
  content: ['./app/**/*.{js,ts,jsx,tsx}', './components/**/*.{js,ts,jsx,tsx}'],
  theme: { extend: {} },
  plugins: [],
};
export default config;
\`\`\`

package.json devDependencies MUST include:
"tailwindcss": "^3.4.0",
"postcss": "^8",
"autoprefixer": "^10"

## CRITICAL: Data and APIs
- NEVER fetch from external APIs (Yahoo Finance, Alpha Vantage, etc.) - they will fail in sandbox
- ALWAYS use realistic mock/sample data embedded directly in the code
- For charts/graphs, include 20-50 data points of realistic sample data
- For stock data, use realistic historical values (not random numbers)
- Data should look real and be immediately visible when the app loads

Example for stock data:
\`\`\`ts
const sampleData = [
  { date: '2024-01', price: 4769.83 },
  { date: '2024-02', price: 5096.27 },
  // ... more realistic data points
];
\`\`\`

## Important Rules
1. Write complete, working code - no placeholders or TODOs
2. Keep files under 300 lines
3. Use 'use client' only when needed (for hooks, event handlers)
4. NEVER run "npm run dev" or other long-running commands
5. After writing files, provide a brief explanation
6. NEVER use @tailwindcss/postcss - use the standard tailwindcss package
7. NEVER use fetch() to get data from external APIs - always use inline sample data

## Response Format
After completing the task, end with a brief natural language explanation of what you built. This will be spoken to the user.

If the request is unclear, ask a clarifying question instead of guessing.`;

// ============================================
// TOOL EXECUTION
// ============================================

async function executeTool(
  projectId: string,
  toolName: string,
  toolInput: Record<string, unknown>
): Promise<string> {
  logger.info('Executing tool', { toolName, toolInput });

  try {
    switch (toolName) {
      case 'write_file': {
        const { path, content } = toolInput as { path: string; content: string };
        await SandboxManager.writeFiles(projectId, [{ path, content }]);
        return `Successfully wrote file: ${path}`;
      }

      case 'read_file': {
        const { path } = toolInput as { path: string };
        const content = await SandboxManager.readFile(projectId, path);
        return content;
      }

      case 'list_files': {
        const { path } = toolInput as { path?: string };
        const files = await SandboxManager.listFiles(projectId, path || '/');
        return files.join('\n');
      }

      case 'run_command': {
        const { command } = toolInput as { command: string };
        
        // Block long-running commands
        if (command.includes('npm run dev') || command.includes('npm start') || command.includes('yarn dev')) {
          return 'Error: Cannot run long-running commands. The dev server will be started automatically.';
        }
        
        const output = await SandboxManager.runCommand(projectId, command);
        return output;
      }

      default:
        return `Unknown tool: ${toolName}`;
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Tool execution failed';
    logger.error('Tool execution failed', { toolName, error: message });
    return `Error: ${message}`;
  }
}

// ============================================
// MAIN AGENT FUNCTION
// ============================================

/**
 * Process a user command using Claude with tools
 */
export async function processCommand(
  projectId: string,
  command: string,
  existingFiles?: ProjectFile[],
  onProgress?: (state: string, message: string) => void
): Promise<AgentResult> {
  logger.info('Processing command', { projectId, command });

  const writtenFiles: ProjectFile[] = [];
  let explanation = '';

  try {
    // Build initial context
    let userMessage = command;
    if (existingFiles && existingFiles.length > 0) {
      userMessage += `\n\nExisting project files:\n${existingFiles.map(f => `- ${f.path}`).join('\n')}`;
    }

    // Start conversation
    const messages: Anthropic.MessageParam[] = [
      { role: 'user', content: userMessage },
    ];

    // Agentic loop - let Claude use tools until done
    let iterations = 0;
    const maxIterations = 20;

    while (iterations < maxIterations) {
      iterations++;
      logger.debug('Agent iteration', { iteration: iterations });

      onProgress?.('EXECUTING', `Working... (step ${iterations})`);

      // Call Claude
      const response = await anthropic.messages.create({
        model: MODEL,
        max_tokens: 8192,
        system: SYSTEM_PROMPT,
        tools,
        messages,
      });

      logger.debug('Claude response', { stopReason: response.stop_reason });

      // Process response content
      const assistantContent: Anthropic.ContentBlock[] = [];
      
      for (const block of response.content) {
        assistantContent.push(block);

        if (block.type === 'text') {
          explanation = block.text;
        }

        if (block.type === 'tool_use') {
          logger.info('Tool use requested', { tool: block.name });
          onProgress?.('EXECUTING', `Using ${block.name}...`);

          // Track written files
          if (block.name === 'write_file') {
            const input = block.input as { path: string; content: string };
            writtenFiles.push({ path: input.path, content: input.content });
          }
        }
      }

      // Add assistant message to history
      messages.push({ role: 'assistant', content: assistantContent });

      // Check if done
      if (response.stop_reason === 'end_turn') {
        logger.info('Agent completed', { iterations, filesWritten: writtenFiles.length });
        break;
      }

      // Handle tool use
      if (response.stop_reason === 'tool_use') {
        const toolResults: Anthropic.ToolResultBlockParam[] = [];

        for (const block of response.content) {
          if (block.type === 'tool_use') {
            const result = await executeTool(
              projectId,
              block.name,
              block.input as Record<string, unknown>
            );
            toolResults.push({
              type: 'tool_result',
              tool_use_id: block.id,
              content: result,
            });
          }
        }

        // Add tool results to conversation
        messages.push({ role: 'user', content: toolResults });
      }
    }

    if (iterations >= maxIterations) {
      logger.warn('Agent hit max iterations', { maxIterations });
    }

    return {
      success: true,
      files: writtenFiles,
      explanation,
      needsClarification: false,
    };

  } catch (error) {
    logger.error('Agent error', error);
    
    return {
      success: false,
      files: writtenFiles,
      explanation: '',
      needsClarification: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

// ============================================
// LEGACY FUNCTIONS (for backward compatibility)
// ============================================

export interface Intent {
  type: 'create' | 'modify' | 'delete' | 'query' | 'command';
  target?: string;
  action?: string;
  details?: string;
  confidence: number;
  needsClarification: boolean;
  clarificationQuestion?: string;
}

export interface CodeGenResult {
  files: Array<{
    path: string;
    content: string;
    action: 'create' | 'update' | 'delete';
  }>;
  explanation: string;
  checkpoint: boolean;
}

export interface Message {
  role: 'user' | 'assistant';
  content: string;
}

/**
 * Parse user intent from transcription
 * @deprecated Use processCommand instead
 */
export async function parseIntent(
  transcription: string,
  _conversationHistory: Message[] = []
): Promise<Intent> {
  const lowerText = transcription.toLowerCase();
  
  let type: Intent['type'] = 'command';
  if (lowerText.includes('create') || lowerText.includes('add') || lowerText.includes('new') || lowerText.includes('build')) {
    type = 'create';
  } else if (lowerText.includes('change') || lowerText.includes('modify') || lowerText.includes('update')) {
    type = 'modify';
  } else if (lowerText.includes('delete') || lowerText.includes('remove')) {
    type = 'delete';
  } else if (lowerText.includes('what') || lowerText.includes('show') || lowerText.includes('list')) {
    type = 'query';
  }

  return {
    type,
    target: transcription,
    action: transcription,
    details: undefined,
    confidence: 0.8,
    needsClarification: false,
    clarificationQuestion: undefined,
  };
}

/**
 * Generate code based on intent
 * @deprecated Use processCommand instead
 */
export async function generateCode(
  intent: Intent,
  existingFiles: ProjectFile[] = [],
  _conversationHistory: Message[] = []
): Promise<CodeGenResult> {
  const result = await processCommand(
    'default-project',
    intent.target || intent.action || '',
    existingFiles
  );

  return {
    files: result.files.map(f => ({
      path: f.path,
      content: f.content,
      action: 'create' as const,
    })),
    explanation: result.explanation,
    checkpoint: true,
  };
}

/**
 * Generate clarification question
 * @deprecated The agent handles clarification internally
 */
export async function generateClarification(
  _intent: Intent,
  ambiguity: string
): Promise<string> {
  return `Could you clarify: ${ambiguity}`;
}
