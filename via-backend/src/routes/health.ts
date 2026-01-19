/**
 * Health Check Route
 * 
 * Used by Railway for deployment health checks.
 */

import { Router, Request, Response } from 'express';
import { getConnectionCount } from '../ws/server.js';
import { getActiveSandboxCount } from '../services/SandboxManager.js';
import * as ProjectStore from '../services/ProjectStore.js';

const router = Router();

router.get('/health', (req: Request, res: Response) => {
  const storeStats = ProjectStore.getStats();
  
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    connections: getConnectionCount(),
    sandboxes: getActiveSandboxCount(),
    projectStore: {
      projects: storeStats.projectCount,
      files: storeStats.totalFiles,
      bytes: storeStats.totalBytes,
      bytesFormatted: formatBytes(storeStats.totalBytes),
    },
  });
});

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

export default router;
