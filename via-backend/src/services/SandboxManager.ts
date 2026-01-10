/**
 * Sandbox Manager
 * 
 * Manages E2B sandbox lifecycle and file operations.
 * Each project gets its own sandbox for code execution and preview.
 * 
 * E2B Features:
 * - <200ms startup
 * - Session duration is configurable; we currently extend to 30 minutes per sandbox
 * - ~$0.10/hour per sandbox
 */

import { Sandbox } from '@e2b/code-interpreter';
import { env } from '../config/env.js';
import { logger } from '../utils/logger.js';
import { SandboxError } from '../utils/errors.js';

// Store active sandboxes by projectId
const sandboxes = new Map<string, {
  sandbox: Sandbox;
  projectId: string;
  url: string;
  createdAt: Date;
  expiresAt: Date;
}>();

// Sandbox configuration
const SANDBOX_TIMEOUT = 30 * 60 * 1000; // 30 minutes in ms

/**
 * Create or get existing sandbox for project
 */
export async function getOrCreateSandbox(projectId: string): Promise<{
  sandboxId: string;
  url: string;
}> {
  // Check if sandbox already exists and is not expired
  const existing = sandboxes.get(projectId);
  if (existing && existing.expiresAt > new Date()) {
    // Verify sandbox is still alive by checking if we can access it
    try {
      await existing.sandbox.files.list('/');
      // Extend remote sandbox TTL to avoid expiring while the user is still active.
      // If this fails, treat the sandbox as dead and recreate.
      await existing.sandbox.setTimeout(SANDBOX_TIMEOUT);
      logger.debug('Using existing sandbox', { projectId, sandboxId: existing.sandbox.sandboxId });
      return {
        sandboxId: existing.sandbox.sandboxId,
        url: existing.url,
      };
    } catch (error) {
      // Sandbox is dead, remove it and create a new one
      logger.warn('Existing sandbox is dead, creating new one', { projectId });
      sandboxes.delete(projectId);
    }
  }
  
  // Try to use a pre-warmed sandbox (much faster!)
  if (consumePrewarmedSandbox(projectId)) {
    const sandboxInfo = sandboxes.get(projectId)!;
    return {
      sandboxId: sandboxInfo.sandbox.sandboxId,
      url: sandboxInfo.url,
    };
  }
  
  logger.info('Creating new sandbox (no pre-warmed available)', { projectId });
  
  try {
    // Create new sandbox with 30-minute timeout
    // TODO: Use custom template with Next.js pre-installed
    const sandbox = await Sandbox.create({
      apiKey: env.E2B_API_KEY,
      timeoutMs: 30 * 60 * 1000, // 30 minutes
    });

    // Be explicit about TTL (guards against SDK defaults / option mismatches)
    await sandbox.setTimeout(SANDBOX_TIMEOUT);
    
    // Get the sandbox URL (for preview)
    // Note: E2B provides a URL for accessing the sandbox
    const url = `https://${sandbox.sandboxId}.e2b.dev`;
    
    // Store sandbox info
    sandboxes.set(projectId, {
      sandbox,
      projectId,
      url,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + SANDBOX_TIMEOUT),
    });
    
    logger.info('Sandbox created', { projectId, sandboxId: sandbox.sandboxId, url });
    
    return {
      sandboxId: sandbox.sandboxId,
      url,
    };
  } catch (error) {
    logger.error('Failed to create sandbox', error);
    throw new SandboxError('Failed to create code execution environment');
  }
}

/**
 * Write files to sandbox
 */
export async function writeFiles(
  projectId: string,
  files: Array<{ path: string; content: string }>
): Promise<string> {
  let sandboxInfo = sandboxes.get(projectId);
  if (!sandboxInfo) {
    // Try to create a new sandbox
    logger.warn('Sandbox not found, creating new one', { projectId });
    await getOrCreateSandbox(projectId);
    sandboxInfo = sandboxes.get(projectId);
    if (!sandboxInfo) {
      return 'Error: Failed to create sandbox';
    }
  }
  
  logger.info('Writing files to sandbox', { projectId, fileCount: files.length });
  
  try {
    for (const file of files) {
      await sandboxInfo.sandbox.files.write(file.path, file.content);
      logger.debug('File written', { projectId, path: file.path });
    }
    return 'Files written successfully';
  } catch (error: any) {
    // Check if sandbox timed out
    if (error.message?.includes('sandbox was not found') || error.message?.includes('timeout')) {
      logger.warn('Sandbox timed out, recreating...', { projectId });
      // Remove stale sandbox reference
      sandboxes.delete(projectId);
      // Try to create a new one and retry
      try {
        await getOrCreateSandbox(projectId);
        sandboxInfo = sandboxes.get(projectId);
        if (sandboxInfo) {
          for (const file of files) {
            await sandboxInfo.sandbox.files.write(file.path, file.content);
          }
          return 'Files written successfully (sandbox recreated)';
        }
      } catch (retryError) {
        logger.error('Failed to recreate sandbox', retryError);
      }
    }
    logger.error('Failed to write files', error);
    return `Error: Failed to write files to sandbox: ${error.message}`;
  }
}

/**
 * Read file from sandbox
 */
export async function readFile(projectId: string, path: string): Promise<string> {
  const sandboxInfo = sandboxes.get(projectId);
  if (!sandboxInfo) {
    throw new SandboxError('Sandbox not found for project');
  }
  
  try {
    const content = await sandboxInfo.sandbox.files.read(path);
    return content;
  } catch (error) {
    logger.error('Failed to read file', error);
    throw new SandboxError(`Failed to read file: ${path}`);
  }
}

/**
 * List files in sandbox directory
 */
export async function listFiles(projectId: string, directory: string = '/'): Promise<string[]> {
  const sandboxInfo = sandboxes.get(projectId);
  if (!sandboxInfo) {
    throw new SandboxError('Sandbox not found for project');
  }
  
  try {
    const files = await sandboxInfo.sandbox.files.list(directory);
    return files.map(f => f.name);
  } catch (error) {
    logger.error('Failed to list files', error);
    throw new SandboxError('Failed to list files');
  }
}

/**
 * Run command in sandbox
 * Returns combined stdout/stderr as string for agent consumption
 */
export async function runCommand(projectId: string, command: string): Promise<string> {
  const sandboxInfo = sandboxes.get(projectId);
  if (!sandboxInfo) {
    throw new SandboxError('Sandbox not found for project');
  }
  
  logger.info('Running command', { projectId, command });
  
  // Check if this is a dev server command - run in background
  const isDevServer = command.includes('npm run dev') || 
                      command.includes('npm start') || 
                      command.includes('npx next dev') ||
                      command.includes('yarn dev');
  
  if (isDevServer) {
    logger.info('Starting dev server in background', { projectId, command });
    try {
      // Run in background - don't wait for it
      sandboxInfo.sandbox.commands.run(command, { background: true });
      
      // Wait a moment for server to start
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      return `Dev server started in background. Preview available at: ${sandboxInfo.url}:3000`;
    } catch (error) {
      logger.error('Failed to start dev server', error);
      throw new SandboxError('Failed to start dev server');
    }
  }
  
  try {
    // Use longer timeout for commands like npm install (3 minutes)
    const result = await sandboxInfo.sandbox.commands.run(command, {
      timeoutMs: 3 * 60 * 1000, // 3 minutes
    });
    
    // Combine output for agent - include both stdout and stderr
    let output = '';
    if (result.stdout) output += result.stdout;
    if (result.stderr) output += (output ? '\n' : '') + result.stderr;
    if (result.exitCode !== 0) {
      output += `\nExit code: ${result.exitCode}`;
    }
    
    return output || '(no output)';
  } catch (error) {
    // Return error as string so Claude can see it and potentially fix
    const message = error instanceof Error ? error.message : 'Command failed';
    logger.error('Command failed', { command, error: message });
    return `Error running command: ${message}`;
  }
}

/**
 * Start dev server in sandbox
 */
export async function startDevServer(projectId: string): Promise<string> {
  const sandboxInfo = sandboxes.get(projectId);
  if (!sandboxInfo) {
    throw new SandboxError('Sandbox not found for project');
  }
  
  logger.info('Starting dev server', { projectId });
  
  try {
    // Ensure the sandbox has a runnable Next.js project.
    // This matters when the sandbox was recreated: the agent might only update a single file
    // (e.g., `app/page.tsx`), but a fresh sandbox won't have `package.json`, etc.
    await ensureNextJsScaffold(sandboxInfo.sandbox, projectId);

    // Install dependencies and start dev server
    await sandboxInfo.sandbox.commands.run('npm install', { timeoutMs: 6 * 60 * 1000 });
    
    // Start dev server in background with host 0.0.0.0 for external access
    // Note: Next.js 14+ uses -H for hostname, older versions use --hostname
    sandboxInfo.sandbox.commands.run('npm run dev -- -H 0.0.0.0 -p 3000', { background: true });
    
    // Wait for server to start - Next.js can take 10-15 seconds on first compile
    await new Promise(resolve => setTimeout(resolve, 10000));
    
    // Get the public URL using E2B's getHost method
    const publicUrl = `https://${sandboxInfo.sandbox.getHost(3000)}`;
    
    logger.info('Dev server started', { projectId, url: publicUrl });
    
    return publicUrl;
  } catch (error) {
    logger.error('Failed to start dev server', error);
    throw new SandboxError('Failed to start preview server');
  }
}

/**
 * Ensure a minimal Next.js + Tailwind project exists in the sandbox.
 * We only create files if they are missing to avoid overwriting agent changes.
 */
async function ensureNextJsScaffold(sandbox: Sandbox, projectId: string): Promise<void> {
  async function ensureDir(path: string): Promise<void> {
    const parts = path.split('/').filter(Boolean);
    if (parts.length === 0) return;

    let current = '';
    for (const part of parts) {
      current = current ? `${current}/${part}` : part;
      try {
        // Create if missing; if it already exists, E2B just returns false.
        await sandbox.files.makeDir(current);
      } catch (error) {
        // If directory already exists (or creation fails due to race), continue.
        // Any real failure will surface when writing files below.
      }
    }
  }

  async function ensureFile(path: string, content: string): Promise<void> {
    try {
      await sandbox.files.read(path);
    } catch {
      logger.warn('Bootstrapping missing file in sandbox', { projectId, path });
      const dir = path.split('/').slice(0, -1).join('/');
      if (dir) {
        await ensureDir(dir);
      }
      await sandbox.files.write(path, content);
    }
  }

  // If `package.json` exists, assume the scaffold is present.
  try {
    await sandbox.files.read('package.json');
    return;
  } catch {
    logger.warn('No package.json found in sandbox; bootstrapping Next.js scaffold', { projectId });
  }

  await ensureFile(
    'package.json',
    JSON.stringify(
      {
        name: 'via-app',
        version: '0.1.0',
        private: true,
        scripts: {
          dev: 'next dev',
          build: 'next build',
          start: 'next start',
          lint: 'next lint',
        },
        dependencies: {
          next: '^15.0.0',
          react: '^19.0.0',
          'react-dom': '^19.0.0',
        },
        devDependencies: {
          typescript: '^5.0.0',
          '@types/node': '^20.0.0',
          '@types/react': '^19.0.0',
          '@types/react-dom': '^19.0.0',
          tailwindcss: '^3.4.0',
          postcss: '^8.4.0',
          autoprefixer: '^10.4.0',
        },
      },
      null,
      2
    ) + '\n'
  );

  await ensureFile(
    'tsconfig.json',
    JSON.stringify(
      {
        compilerOptions: {
          target: 'ES2017',
          lib: ['dom', 'dom.iterable', 'esnext'],
          allowJs: true,
          skipLibCheck: true,
          strict: true,
          noEmit: true,
          esModuleInterop: true,
          module: 'esnext',
          moduleResolution: 'bundler',
          resolveJsonModule: true,
          isolatedModules: true,
          jsx: 'preserve',
          incremental: true,
          plugins: [{ name: 'next' }],
        },
        include: ['next-env.d.ts', '**/*.ts', '**/*.tsx', '.next/types/**/*.ts'],
        exclude: ['node_modules'],
      },
      null,
      2
    ) + '\n'
  );

  await ensureFile(
    'next.config.ts',
    `import type { NextConfig } from 'next';\n\nconst nextConfig: NextConfig = {};\n\nexport default nextConfig;\n`
  );

  await ensureFile(
    'postcss.config.cjs',
    `module.exports = {\n  plugins: {\n    tailwindcss: {},\n    autoprefixer: {},\n  },\n};\n`
  );

  await ensureFile(
    'tailwind.config.ts',
    `import type { Config } from 'tailwindcss';\n\nconst config: Config = {\n  content: [\n    './app/**/*.{js,ts,jsx,tsx,mdx}',\n    './components/**/*.{js,ts,jsx,tsx,mdx}',\n    './pages/**/*.{js,ts,jsx,tsx,mdx}',\n  ],\n  theme: { extend: {} },\n  plugins: [],\n};\n\nexport default config;\n`
  );

  await ensureFile('next-env.d.ts', `/// <reference types="next" />\n/// <reference types="next/image-types/global" />\n\n// NOTE: This file should not be edited.\n\n`);

  await ensureFile('app/globals.css', `@tailwind base;\n@tailwind components;\n@tailwind utilities;\n`);

  await ensureFile(
    'app/layout.tsx',
    `import type { Metadata } from 'next';\nimport './globals.css';\n\nexport const metadata: Metadata = {\n  title: 'Via Preview',\n  description: 'Live preview',\n};\n\nexport default function RootLayout({ children }: { children: React.ReactNode }) {\n  return (\n    <html lang="en">\n      <body>{children}</body>\n    </html>\n  );\n}\n`
  );

  // Do NOT create `app/page.tsx` here — the agent likely wrote it already.

  await ensureFile(
    '.gitignore',
    `# dependencies\n/node_modules\n\n# next\n/.next\n/out\n\n# misc\n.DS_Store\n\n# env\n.env\n.env*.local\n`
  );
}

/**
 * Get sandbox URL
 */
export function getSandboxUrl(projectId: string): string | undefined {
  return sandboxes.get(projectId)?.url;
}

/**
 * Destroy sandbox
 */
export async function destroySandbox(projectId: string): Promise<void> {
  const sandboxInfo = sandboxes.get(projectId);
  if (!sandboxInfo) {
    return;
  }
  
  logger.info('Destroying sandbox', { projectId });
  
  try {
    await sandboxInfo.sandbox.kill();
    sandboxes.delete(projectId);
  } catch (error) {
    logger.error('Failed to destroy sandbox', error);
  }
}

/**
 * Keep sandbox alive (extend timeout)
 */
export async function keepAlive(projectId: string): Promise<void> {
  const sandboxInfo = sandboxes.get(projectId);
  if (sandboxInfo) {
    sandboxInfo.expiresAt = new Date(Date.now() + SANDBOX_TIMEOUT);
    logger.debug('Sandbox keepalive', { projectId });
    // Fail loudly if we cannot extend the remote TTL. This avoids silently masking
    // environment issues that would otherwise surface later as "blank preview".
    await sandboxInfo.sandbox.setTimeout(SANDBOX_TIMEOUT);
  }
}

/**
 * Get active sandbox count
 */
export function getActiveSandboxCount(): number {
  return sandboxes.size;
}

/**
 * Cleanup expired sandboxes
 */
export async function cleanupExpiredSandboxes(): Promise<void> {
  const now = new Date();
  
  for (const [projectId, info] of sandboxes.entries()) {
    if (info.expiresAt < now) {
      logger.info('Cleaning up expired sandbox', { projectId });
      await destroySandbox(projectId);
    }
  }
}

// Run cleanup every hour
setInterval(cleanupExpiredSandboxes, 60 * 60 * 1000);

// Track pre-warmed sandbox (ready for use)
let prewarmedSandbox: {
  sandbox: Sandbox;
  projectId: string;
  url: string;
  createdAt: Date;
  expiresAt: Date;
  npmInstalled: boolean;
} | null = null;

/**
 * Pre-warm a sandbox in the background.
 * Creates the sandbox, sets up Next.js scaffold, and runs npm install.
 * This is called when a WebSocket connection is established.
 */
export async function prewarmSandbox(): Promise<void> {
  // Don't pre-warm if we already have one ready
  if (prewarmedSandbox) {
    logger.debug('Pre-warmed sandbox already exists, skipping');
    return;
  }

  logger.info('Pre-warming sandbox in background...');
  
  try {
    const sandbox = await Sandbox.create({
      apiKey: env.E2B_API_KEY,
      timeoutMs: SANDBOX_TIMEOUT,
    });

    await sandbox.setTimeout(SANDBOX_TIMEOUT);
    
    const url = `https://${sandbox.sandboxId}.e2b.dev`;
    const projectId = `prewarm_${Date.now()}`;
    
    logger.info('Pre-warmed sandbox created, setting up Next.js scaffold...', { sandboxId: sandbox.sandboxId });

    // Set up the Next.js scaffold
    await ensureNextJsScaffoldForPrewarm(sandbox, projectId);
    
    logger.info('Running npm install in pre-warmed sandbox...');
    
    // Run npm install (the expensive part)
    await sandbox.commands.run('npm install', { timeoutMs: 6 * 60 * 1000 });
    
    prewarmedSandbox = {
      sandbox,
      projectId,
      url,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + SANDBOX_TIMEOUT),
      npmInstalled: true,
    };
    
    logger.info('Sandbox pre-warmed and ready!', { sandboxId: sandbox.sandboxId, url });
  } catch (error) {
    logger.error('Failed to pre-warm sandbox', error);
    // Non-fatal - the normal flow will create a sandbox when needed
  }
}

/**
 * Get a pre-warmed sandbox if available, otherwise create a new one.
 * This is called by getOrCreateSandbox when a sandbox is needed.
 */
export function consumePrewarmedSandbox(projectId: string): boolean {
  if (!prewarmedSandbox) {
    return false;
  }
  
  // Transfer the pre-warmed sandbox to the active sandboxes map
  sandboxes.set(projectId, {
    sandbox: prewarmedSandbox.sandbox,
    projectId,
    url: prewarmedSandbox.url,
    createdAt: prewarmedSandbox.createdAt,
    expiresAt: prewarmedSandbox.expiresAt,
  });
  
  logger.info('Using pre-warmed sandbox', { projectId, sandboxId: prewarmedSandbox.sandbox.sandboxId });
  
  prewarmedSandbox = null;
  
  // Start pre-warming another sandbox for the next request
  prewarmSandbox().catch(err => logger.error('Failed to pre-warm next sandbox', err));
  
  return true;
}

/**
 * Ensure Next.js scaffold exists for pre-warming (same as ensureNextJsScaffold but exported-friendly)
 */
async function ensureNextJsScaffoldForPrewarm(sandbox: Sandbox, projectId: string): Promise<void> {
  async function ensureDir(path: string): Promise<void> {
    const parts = path.split('/').filter(Boolean);
    if (parts.length === 0) return;

    let current = '';
    for (const part of parts) {
      current = current ? `${current}/${part}` : part;
      try {
        await sandbox.files.makeDir(current);
      } catch (error) {
        // Directory may already exist
      }
    }
  }

  async function ensureFile(path: string, content: string): Promise<void> {
    const dir = path.split('/').slice(0, -1).join('/');
    if (dir) {
      await ensureDir(dir);
    }
    await sandbox.files.write(path, content);
  }

  await ensureFile(
    'package.json',
    JSON.stringify(
      {
        name: 'via-app',
        version: '0.1.0',
        private: true,
        scripts: {
          dev: 'next dev',
          build: 'next build',
          start: 'next start',
          lint: 'next lint',
        },
        dependencies: {
          next: '^15.0.0',
          react: '^19.0.0',
          'react-dom': '^19.0.0',
        },
        devDependencies: {
          typescript: '^5.0.0',
          '@types/node': '^20.0.0',
          '@types/react': '^19.0.0',
          '@types/react-dom': '^19.0.0',
          tailwindcss: '^3.4.0',
          postcss: '^8.4.0',
          autoprefixer: '^10.4.0',
        },
      },
      null,
      2
    ) + '\n'
  );

  await ensureFile(
    'tsconfig.json',
    JSON.stringify(
      {
        compilerOptions: {
          target: 'ES2017',
          lib: ['dom', 'dom.iterable', 'esnext'],
          allowJs: true,
          skipLibCheck: true,
          strict: true,
          noEmit: true,
          esModuleInterop: true,
          module: 'esnext',
          moduleResolution: 'bundler',
          resolveJsonModule: true,
          isolatedModules: true,
          jsx: 'preserve',
          incremental: true,
          plugins: [{ name: 'next' }],
        },
        include: ['next-env.d.ts', '**/*.ts', '**/*.tsx', '.next/types/**/*.ts'],
        exclude: ['node_modules'],
      },
      null,
      2
    ) + '\n'
  );

  await ensureFile(
    'next.config.ts',
    `import type { NextConfig } from 'next';\n\nconst nextConfig: NextConfig = {};\n\nexport default nextConfig;\n`
  );

  await ensureFile(
    'postcss.config.cjs',
    `module.exports = {\n  plugins: {\n    tailwindcss: {},\n    autoprefixer: {},\n  },\n};\n`
  );

  await ensureFile(
    'tailwind.config.ts',
    `import type { Config } from 'tailwindcss';\n\nconst config: Config = {\n  content: [\n    './app/**/*.{js,ts,jsx,tsx,mdx}',\n    './components/**/*.{js,ts,jsx,tsx,mdx}',\n    './pages/**/*.{js,ts,jsx,tsx,mdx}',\n  ],\n  theme: { extend: {} },\n  plugins: [],\n};\n\nexport default config;\n`
  );

  await ensureFile('next-env.d.ts', `/// <reference types="next" />\n/// <reference types="next/image-types/global" />\n\n// NOTE: This file should not be edited.\n\n`);

  await ensureFile('app/globals.css', `@tailwind base;\n@tailwind components;\n@tailwind utilities;\n`);

  await ensureFile(
    'app/layout.tsx',
    `import type { Metadata } from 'next';\nimport './globals.css';\n\nexport const metadata: Metadata = {\n  title: 'Via Preview',\n  description: 'Live preview',\n};\n\nexport default function RootLayout({ children }: { children: React.ReactNode }) {\n  return (\n    <html lang="en">\n      <body>{children}</body>\n    </html>\n  );\n}\n`
  );

  // Create a placeholder page.tsx so npm install can complete
  await ensureFile(
    'app/page.tsx',
    `export default function Page() {\n  return <div>Loading...</div>;\n}\n`
  );

  await ensureFile(
    '.gitignore',
    `# dependencies\n/node_modules\n\n# next\n/.next\n/out\n\n# misc\n.DS_Store\n\n# env\n.env\n.env*.local\n`
  );
}
