/**
 * Project Store
 * 
 * Persists project files in memory (or database) so they survive sandbox restarts.
 * When a sandbox dies and is recreated, we restore all files from this store.
 * 
 * This solves the E2B ephemeral sandbox problem without changing infrastructure.
 */

import { logger } from '../utils/logger.js';

// In-memory store for project files
// In production, this should be Redis, PostgreSQL, or a file system
const projectFiles = new Map<string, Map<string, string>>();

// Track which projects have had npm install completed
const npmInstalledProjects = new Set<string>();

// Track conversation history per project for multi-turn context
const conversationHistory = new Map<string, Array<{ role: 'user' | 'assistant'; content: string }>>();

/**
 * Store a file for a project
 */
export function storeFile(projectId: string, path: string, content: string): void {
  if (!projectFiles.has(projectId)) {
    projectFiles.set(projectId, new Map());
  }
  projectFiles.get(projectId)!.set(path, content);
  logger.debug('File stored', { projectId, path, size: content.length });
}

/**
 * Store multiple files at once
 */
export function storeFiles(projectId: string, files: Array<{ path: string; content: string }>): void {
  for (const file of files) {
    storeFile(projectId, file.path, file.content);
  }
  logger.info('Files stored', { projectId, count: files.length });
}

/**
 * Get a single file
 */
export function getFile(projectId: string, path: string): string | undefined {
  return projectFiles.get(projectId)?.get(path);
}

/**
 * Get all files for a project
 */
export function getAllFiles(projectId: string): Array<{ path: string; content: string }> {
  const files = projectFiles.get(projectId);
  if (!files) return [];
  
  return Array.from(files.entries()).map(([path, content]) => ({ path, content }));
}

/**
 * Get file count for a project
 */
export function getFileCount(projectId: string): number {
  return projectFiles.get(projectId)?.size || 0;
}

/**
 * Delete a file
 */
export function deleteFile(projectId: string, path: string): boolean {
  const files = projectFiles.get(projectId);
  if (!files) return false;
  return files.delete(path);
}

/**
 * Clear all files for a project
 */
export function clearProject(projectId: string): void {
  projectFiles.delete(projectId);
  npmInstalledProjects.delete(projectId);
  conversationHistory.delete(projectId);
  logger.info('Project cleared', { projectId });
}

/**
 * Mark that npm install has been completed for a project
 */
export function markNpmInstalled(projectId: string): void {
  npmInstalledProjects.add(projectId);
}

/**
 * Check if npm install has been completed
 */
export function isNpmInstalled(projectId: string): boolean {
  return npmInstalledProjects.has(projectId);
}

/**
 * Store conversation history
 */
export function addToHistory(projectId: string, role: 'user' | 'assistant', content: string): void {
  if (!conversationHistory.has(projectId)) {
    conversationHistory.set(projectId, []);
  }
  conversationHistory.get(projectId)!.push({ role, content });
  
  // Keep only last 20 messages to avoid context overflow
  const history = conversationHistory.get(projectId)!;
  if (history.length > 20) {
    conversationHistory.set(projectId, history.slice(-20));
  }
}

/**
 * Get conversation history
 */
export function getHistory(projectId: string): Array<{ role: 'user' | 'assistant'; content: string }> {
  return conversationHistory.get(projectId) || [];
}

/**
 * Get all active project IDs
 */
export function getActiveProjects(): string[] {
  return Array.from(projectFiles.keys());
}

/**
 * Get memory usage stats
 */
export function getStats(): {
  projectCount: number;
  totalFiles: number;
  totalBytes: number;
} {
  let totalFiles = 0;
  let totalBytes = 0;
  
  for (const files of projectFiles.values()) {
    totalFiles += files.size;
    for (const content of files.values()) {
      totalBytes += content.length;
    }
  }
  
  return {
    projectCount: projectFiles.size,
    totalFiles,
    totalBytes,
  };
}
