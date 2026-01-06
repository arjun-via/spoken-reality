/**
 * Via Backend - Entry Point
 * 
 * Voice-first app builder backend service.
 * 
 * Features:
 * - WebSocket server for real-time communication
 * - REST API for utility endpoints
 * - Integration with Grok (voice), Claude (AI), E2B (sandboxes)
 */

import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { env } from './config/env.js';
import { logger } from './utils/logger.js';
import { initWebSocketServer } from './ws/server.js';
import healthRouter from './routes/health.js';

// Create Express app
const app = express();

// Middleware
app.use(cors({
  origin: env.isDev ? '*' : ['https://via.app'], // Restrict in production
  credentials: true,
}));
app.use(express.json());

// Routes
app.use('/api', healthRouter);

// Root route
app.get('/', (req, res) => {
  res.json({
    name: 'Via Backend',
    version: '1.0.0',
    status: 'running',
    docs: '/api/health',
  });
});

// Create HTTP server
const httpServer = createServer(app);

// Initialize WebSocket server
initWebSocketServer(httpServer);

// Start server - bind to 0.0.0.0 for Railway/Docker
httpServer.listen(env.PORT, '0.0.0.0', () => {
  logger.info(`🚀 Via Backend running on port ${env.PORT}`);
  logger.info(`   Environment: ${env.NODE_ENV}`);
  logger.info(`   WebSocket: ws://localhost:${env.PORT}/ws`);
  logger.info(`   Health: http://localhost:${env.PORT}/api/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully...');
  httpServer.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully...');
  httpServer.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});
