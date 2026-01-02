/**
 * Health Check Route
 * 
 * Used by Railway for deployment health checks.
 */

import { Router, Request, Response } from 'express';
import { getConnectionCount } from '../ws/server.js';

const router = Router();

router.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    connections: getConnectionCount(),
  });
});

export default router;
