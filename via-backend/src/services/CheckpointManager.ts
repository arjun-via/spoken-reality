/**
 * Checkpoint Manager
 * 
 * Handles versioning and rollback for projects.
 * Creates snapshots of project files at key moments.
 */

import { logger } from '../utils/logger.js';

// ============================================
// TYPES
// ============================================

export interface Checkpoint {
  id: string;
  projectId: string;
  name: string;
  description?: string;
  files: Array<{
    path: string;
    content: string;
  }>;
  createdAt: Date;
}

// In-memory checkpoint store (will be backed by database later)
const checkpoints = new Map<string, Checkpoint[]>(); // projectId -> checkpoints

/**
 * Create a checkpoint for project
 */
export function createCheckpoint(
  projectId: string,
  name: string,
  files: Array<{ path: string; content: string }>,
  description?: string
): Checkpoint {
  const checkpoint: Checkpoint = {
    id: `checkpoint_${Date.now()}`,
    projectId,
    name,
    description,
    files: [...files], // Clone files array
    createdAt: new Date(),
  };
  
  // Get or create checkpoint list for project
  let projectCheckpoints = checkpoints.get(projectId);
  if (!projectCheckpoints) {
    projectCheckpoints = [];
    checkpoints.set(projectId, projectCheckpoints);
  }
  
  projectCheckpoints.push(checkpoint);
  
  logger.info('Checkpoint created', { 
    projectId, 
    checkpointId: checkpoint.id, 
    name,
    fileCount: files.length,
  });
  
  return checkpoint;
}

/**
 * Auto-create checkpoint after significant action
 */
export function autoCheckpoint(
  projectId: string,
  action: string,
  files: Array<{ path: string; content: string }>
): Checkpoint {
  const name = `After: ${action}`;
  return createCheckpoint(projectId, name, files, `Automatic checkpoint after ${action}`);
}

/**
 * List checkpoints for project
 */
export function listCheckpoints(projectId: string): Checkpoint[] {
  return checkpoints.get(projectId) || [];
}

/**
 * Get specific checkpoint
 */
export function getCheckpoint(projectId: string, checkpointId: string): Checkpoint | undefined {
  const projectCheckpoints = checkpoints.get(projectId);
  return projectCheckpoints?.find(c => c.id === checkpointId);
}

/**
 * Get latest checkpoint
 */
export function getLatestCheckpoint(projectId: string): Checkpoint | undefined {
  const projectCheckpoints = checkpoints.get(projectId);
  if (!projectCheckpoints || projectCheckpoints.length === 0) {
    return undefined;
  }
  return projectCheckpoints[projectCheckpoints.length - 1];
}

/**
 * Get previous checkpoint (for undo)
 */
export function getPreviousCheckpoint(projectId: string): Checkpoint | undefined {
  const projectCheckpoints = checkpoints.get(projectId);
  if (!projectCheckpoints || projectCheckpoints.length < 2) {
    return undefined;
  }
  return projectCheckpoints[projectCheckpoints.length - 2];
}

/**
 * Restore to checkpoint
 * Returns the files from the checkpoint
 */
export function restoreToCheckpoint(
  projectId: string,
  checkpointId: string
): Array<{ path: string; content: string }> | undefined {
  const checkpoint = getCheckpoint(projectId, checkpointId);
  
  if (!checkpoint) {
    logger.warn('Checkpoint not found', { projectId, checkpointId });
    return undefined;
  }
  
  logger.info('Restoring to checkpoint', { 
    projectId, 
    checkpointId, 
    name: checkpoint.name,
  });
  
  return checkpoint.files;
}

/**
 * Undo last change (restore to previous checkpoint)
 */
export function undo(projectId: string): Array<{ path: string; content: string }> | undefined {
  const previousCheckpoint = getPreviousCheckpoint(projectId);
  
  if (!previousCheckpoint) {
    logger.warn('No previous checkpoint for undo', { projectId });
    return undefined;
  }
  
  // Remove the latest checkpoint
  const projectCheckpoints = checkpoints.get(projectId);
  if (projectCheckpoints && projectCheckpoints.length > 0) {
    projectCheckpoints.pop();
  }
  
  logger.info('Undo performed', { 
    projectId, 
    restoredTo: previousCheckpoint.name,
  });
  
  return previousCheckpoint.files;
}

/**
 * Delete checkpoint
 */
export function deleteCheckpoint(projectId: string, checkpointId: string): boolean {
  const projectCheckpoints = checkpoints.get(projectId);
  if (!projectCheckpoints) {
    return false;
  }
  
  const index = projectCheckpoints.findIndex(c => c.id === checkpointId);
  if (index === -1) {
    return false;
  }
  
  projectCheckpoints.splice(index, 1);
  logger.info('Checkpoint deleted', { projectId, checkpointId });
  
  return true;
}

/**
 * Clear all checkpoints for project
 */
export function clearCheckpoints(projectId: string): void {
  checkpoints.delete(projectId);
  logger.info('Checkpoints cleared', { projectId });
}

/**
 * Get checkpoint count for project
 */
export function getCheckpointCount(projectId: string): number {
  return checkpoints.get(projectId)?.length || 0;
}
