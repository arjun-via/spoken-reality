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
import infographicRouter from './routes/infographic.js';

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
app.use('/api/infographic', infographicRouter);

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

// Start server - bind to 0.0.0.0 for Railway/container environments
const HOST = '0.0.0.0';
httpServer.listen(env.PORT, HOST, () => {
  logger.info(`🚀 Via Backend running on ${HOST}:${env.PORT}`);
  logger.info(`   Environment: ${env.NODE_ENV}`);
  logger.info(`   PORT env var: ${process.env.PORT || 'not set, using default 3000'}`);
  logger.info(`   WebSocket: ws://${HOST}:${env.PORT}/ws`);
  logger.info(`   Health: http://${HOST}:${env.PORT}/api/health`);
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
