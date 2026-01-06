/**
 * WebSocket Server
 * 
 * Manages WebSocket connections, authentication, and message routing.
 */

import { WebSocketServer, WebSocket } from 'ws';
import { Server } from 'http';
import { logger } from '../utils/logger.js';
import { handleMessage, AuthenticatedWebSocket } from './handlers.js';
import { WebSocketMessage, createMessage } from './types.js';

// Store active connections by userId
const connections = new Map<string, AuthenticatedWebSocket>();

/**
 * Initialize WebSocket server
 */
export function initWebSocketServer(httpServer: Server): WebSocketServer {
  const wss = new WebSocketServer({ 
    server: httpServer,
    path: '/ws',
  });

  wss.on('connection', async (ws: AuthenticatedWebSocket, req) => {
    logger.info('New WebSocket connection', { 
      url: req.url,
      headers: req.headers['user-agent'],
    });

    // Extract token from query string
    const url = new URL(req.url || '', `http://${req.headers.host}`);
    const token = url.searchParams.get('token');

    if (!token) {
      logger.warn('Connection rejected: no token provided');
      ws.close(4001, 'Authentication required');
      return;
    }

    // TODO: Verify token with Clerk
    // For now, use a mock user ID for development
    try {
      // const { userId } = await verifyToken(token);
      const userId = `user_dev_${Date.now()}`; // Mock for development
      
      ws.userId = userId;
      ws.sessionId = `session_${Date.now()}`;
      
      // Store connection
      connections.set(userId, ws);
      
      logger.info('Client authenticated', { userId, sessionId: ws.sessionId });
      
      // Send initial state
      ws.send(JSON.stringify(createMessage('agent.state', {
        state: 'IDLE',
        message: 'Ready',
      })));

    } catch (error) {
      logger.error('Authentication failed', error);
      ws.close(4001, 'Authentication failed');
      return;
    }

    // Handle incoming messages
    ws.on('message', async (data) => {
      try {
        const message = JSON.parse(data.toString()) as WebSocketMessage;
        await handleMessage(ws, message);
      } catch (error) {
        logger.error('Failed to parse message', error);
        ws.send(JSON.stringify(createMessage('error', {
          code: 'PARSE_ERROR',
          message: 'Invalid message format',
          recoverable: false,
        })));
      }
    });

    // #region agent log - Track connection timing
    const connectionStartTime = Date.now();
    // #endregion

    // Handle disconnection
    ws.on('close', (code, reason) => {
      // #region agent log - Debug disconnection with timing
      const connectionDuration = Date.now() - connectionStartTime;
      logger.warn('CLIENT DISCONNECTED - DEBUG', { 
        userId: ws.userId, 
        code, 
        reason: reason.toString(),
        connectionDurationMs: connectionDuration,
        connectionDurationSec: (connectionDuration / 1000).toFixed(1),
      });
      // #endregion
      
      if (ws.userId) {
        connections.delete(ws.userId);
      }
    });

    // Handle errors
    ws.on('error', (error) => {
      // #region agent log - Debug WebSocket errors
      logger.error('WEBSOCKET ERROR - DEBUG', { 
        userId: ws.userId,
        error: error.message,
        stack: error.stack,
      });
      // #endregion
    });

    // Heartbeat to keep connection alive
    ws.on('pong', () => {
      logger.debug('Pong received', { userId: ws.userId });
    });
  });

  // Heartbeat interval
  const heartbeatInterval = setInterval(() => {
    wss.clients.forEach((ws) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.ping();
      }
    });
  }, 30000); // Every 30 seconds

  wss.on('close', () => {
    clearInterval(heartbeatInterval);
  });

  logger.info('WebSocket server initialized');
  
  return wss;
}

/**
 * Send message to specific user
 */
export function sendToUser(userId: string, message: WebSocketMessage): boolean {
  const ws = connections.get(userId);
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(message));
    return true;
  }
  return false;
}

/**
 * Get connection count
 */
export function getConnectionCount(): number {
  return connections.size;
}

/**
 * Check if user is connected
 */
export function isUserConnected(userId: string): boolean {
  const ws = connections.get(userId);
  return ws !== undefined && ws.readyState === WebSocket.OPEN;
}
