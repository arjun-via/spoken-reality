/**
 * Session Manager
 * 
 * Manages user sessions and agent state.
 * Tracks active projects and conversation context.
 */

import { logger } from '../utils/logger.js';

// Agent states matching the state machine in BACKEND_SPEC.md
export type AgentState =
  | 'IDLE'
  | 'LISTENING'
  | 'INTERPRETING'
  | 'CLARIFYING'
  | 'PLANNING'
  | 'EXECUTING'
  | 'PRESENTING'
  | 'ERROR';

export interface UserSession {
  userId: string;
  sessionId: string;
  state: AgentState;
  currentProjectId?: string;
  lastActiveAt: Date;
  createdAt: Date;
}

// In-memory session store (will be backed by database later)
const sessions = new Map<string, UserSession>();

/**
 * Create or get existing session for user
 */
export function getOrCreateSession(userId: string): UserSession {
  let session = sessions.get(userId);
  
  if (!session) {
    session = {
      userId,
      sessionId: `session_${Date.now()}`,
      state: 'IDLE',
      lastActiveAt: new Date(),
      createdAt: new Date(),
    };
    sessions.set(userId, session);
    logger.info('Created new session', { userId, sessionId: session.sessionId });
  }
  
  return session;
}

/**
 * Get session for user
 */
export function getSession(userId: string): UserSession | undefined {
  return sessions.get(userId);
}

/**
 * Update session state
 */
export function updateState(userId: string, state: AgentState): void {
  const session = sessions.get(userId);
  if (session) {
    const previousState = session.state;
    session.state = state;
    session.lastActiveAt = new Date();
    logger.debug('State transition', { userId, from: previousState, to: state });
  }
}

/**
 * Set active project for session
 */
export function setActiveProject(userId: string, projectId: string): void {
  const session = sessions.get(userId);
  if (session) {
    session.currentProjectId = projectId;
    session.lastActiveAt = new Date();
    logger.info('Set active project', { userId, projectId });
  }
}

/**
 * Get active project for session
 */
export function getActiveProject(userId: string): string | undefined {
  const session = sessions.get(userId);
  return session?.currentProjectId;
}

/**
 * Remove session (on disconnect)
 */
export function removeSession(userId: string): void {
  sessions.delete(userId);
  logger.info('Removed session', { userId });
}

/**
 * Get all active sessions (for monitoring)
 */
export function getActiveSessions(): UserSession[] {
  return Array.from(sessions.values());
}

/**
 * Get session count
 */
export function getSessionCount(): number {
  return sessions.size;
}
