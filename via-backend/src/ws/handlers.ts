/**
 * WebSocket Message Handlers
 * 
 * Handles incoming messages from clients and routes to appropriate services.
 * Implements the full voice → transcription → AI → sandbox → preview flow.
 */

import { WebSocket } from 'ws';
import { logger } from '../utils/logger.js';
import { 
  WebSocketMessage, 
  ClientMessageType,
  VoiceStartPayload,
  VoiceChunkPayload,
  CommandPayload,
  ProjectCreatePayload,
  ProjectOpenPayload,
  ProjectGetFilesPayload,
  createMessage,
  AgentStatePayload,
} from './types.js';
import * as VoicePipeline from '../services/VoicePipeline.js';
import * as AIOrchestrator from '../services/AIOrchestrator.js';
import * as SandboxManager from '../services/SandboxManager.js';
import * as CheckpointManager from '../services/CheckpointManager.js';
import * as SessionManager from '../services/SessionManager.js';

// Type for authenticated WebSocket connection
export interface AuthenticatedWebSocket extends WebSocket {
  userId?: string;
  sessionId?: string;
  currentProjectId?: string;
}

// Store active connections for sending messages
const connections = new Map<string, AuthenticatedWebSocket>();

/**
 * Register connection for a user
 */
export function registerConnection(userId: string, ws: AuthenticatedWebSocket): void {
  connections.set(userId, ws);
}

/**
 * Remove connection for a user
 */
export function removeConnection(userId: string): void {
  connections.delete(userId);
}

/**
 * Handle incoming WebSocket message
 */
export async function handleMessage(
  ws: AuthenticatedWebSocket,
  message: WebSocketMessage
): Promise<void> {
  const { type, payload, messageId } = message;
  
  logger.debug(`Received message: ${type}`, { messageId, userId: ws.userId });

  try {
    switch (type as ClientMessageType) {
      case 'voice.start':
        await handleVoiceStart(ws, payload as VoiceStartPayload);
        break;
      
      case 'voice.chunk':
        await handleVoiceChunk(ws, payload as VoiceChunkPayload);
        break;
      
      case 'voice.end':
        await handleVoiceEnd(ws);
        break;
      
      case 'command':
        await handleCommand(ws, payload as CommandPayload);
        break;
      
      case 'project.create':
        await handleProjectCreate(ws, payload as ProjectCreatePayload);
        break;
      
      case 'project.open':
        await handleProjectOpen(ws, payload as ProjectOpenPayload);
        break;
      
      case 'project.getFiles':
        await handleProjectGetFiles(ws, payload as ProjectGetFilesPayload);
        break;
      
      default:
        logger.warn(`Unknown message type: ${type}`);
        sendError(ws, 'INVALID_COMMAND', `Unknown message type: ${type}`, false);
    }
  } catch (error) {
    logger.error(`Error handling message ${type}`, error);
    const errorMessage = error instanceof Error ? error.message : 'An error occurred';
    sendError(ws, 'HANDLER_ERROR', errorMessage, true, 'Please try again');
  }
}

// ============================================
// VOICE HANDLERS
// ============================================

async function handleVoiceStart(
  ws: AuthenticatedWebSocket,
  payload: VoiceStartPayload
): Promise<void> {
  const userId = ws.userId!;
  const { projectId } = payload;
  
  logger.info('Voice start', { projectId, userId });
  
  // Store current project
  ws.currentProjectId = projectId;
  SessionManager.setActiveProject(userId, projectId);
  
  // Update agent state to LISTENING
  sendAgentState(ws, 'LISTENING', 'Listening...');
  
  // Initialize voice pipeline
  VoicePipeline.startListening(userId);
}

async function handleVoiceChunk(
  ws: AuthenticatedWebSocket,
  payload: VoiceChunkPayload
): Promise<void> {
  const userId = ws.userId!;
  
  // Process audio chunk
  VoicePipeline.processAudioChunk(userId, payload.audio);
  
  // TODO: When Grok streaming is implemented, send partial transcriptions here
  // For now, we'll send them after voice.end
}

async function handleVoiceEnd(ws: AuthenticatedWebSocket): Promise<void> {
  const userId = ws.userId!;
  const projectId = ws.currentProjectId || 'default-project';
  
  logger.info('Voice end', { userId, projectId });
  
  // Update agent state to INTERPRETING
  sendAgentState(ws, 'INTERPRETING', 'Processing your request...');
  
  try {
    // Get transcription from voice pipeline
    const transcription = await VoicePipeline.stopListening(userId);
    
    if (!transcription || transcription.trim() === '') {
      sendError(ws, 'TRANSCRIPTION_FAILED', 'Could not understand audio', true, 'Please try speaking again');
      sendAgentState(ws, 'IDLE', 'Ready');
      return;
    }
    
    // Send final transcription to client
    sendTranscriptionFinal(ws, transcription);
    
    // Process the command
    await processUserCommand(ws, transcription, projectId);
    
  } catch (error) {
    logger.error('Voice processing failed', error);
    sendError(ws, 'TRANSCRIPTION_FAILED', 'Failed to process audio', true, 'Please try again');
    sendAgentState(ws, 'ERROR', 'Processing failed');
  }
}

// ============================================
// COMMAND PROCESSING
// ============================================

async function handleCommand(
  ws: AuthenticatedWebSocket,
  payload: CommandPayload
): Promise<void> {
  const { text, projectId } = payload;
  const userId = ws.userId!;
  
  logger.info('Command received', { text, projectId, userId });
  
  // Store current project
  ws.currentProjectId = projectId;
  
  // Handle built-in commands
  const lowerText = text.toLowerCase().trim();
  
  if (lowerText === 'stop') {
    sendAgentState(ws, 'IDLE', 'Stopped');
    return;
  }
  
  if (lowerText === 'undo') {
    await handleUndo(ws, projectId);
    return;
  }
  
  // Process as regular command
  await processUserCommand(ws, text, projectId);
}

/**
 * Process user command through Claude Agent SDK
 */
async function processUserCommand(
  ws: AuthenticatedWebSocket,
  text: string,
  projectId: string
): Promise<void> {
  try {
    // Update state to PLANNING
    sendAgentState(ws, 'PLANNING', 'Understanding your request...');
    
    // Ensure sandbox exists for the agent to use
    sendAgentState(ws, 'EXECUTING', 'Setting up environment...', 10);
    await SandboxManager.getOrCreateSandbox(projectId);
    
    // Get existing files for context (if any)
    // TODO: Load from database
    const existingFiles: AIOrchestrator.ProjectFile[] = [];
    
    // Process command with Claude Agent SDK
    sendAgentState(ws, 'EXECUTING', 'Building your app...', 30);
    
    const result = await AIOrchestrator.processCommand(
      projectId,
      text,
      existingFiles,
      (state, message) => {
        // Progress callback from agent
        sendAgentState(ws, state as AgentStatePayload['state'], message);
      }
    );
    
    logger.info('Agent completed', { 
      success: result.success,
      fileCount: result.files.length,
      explanation: result.explanation,
    });
    
    // Check if clarification is needed
    if (result.needsClarification && result.clarificationQuestion) {
      sendAgentState(ws, 'CLARIFYING');
      sendClarification(ws, result.clarificationQuestion);
      return;
    }
    
    // Check for errors
    if (!result.success) {
      sendError(ws, 'CLAUDE_ERROR', result.error || 'Agent failed', true, 'Please try rephrasing your request');
      sendAgentState(ws, 'ERROR', 'Something went wrong');
      return;
    }
    
    // Send code update to client
    if (result.files.length > 0) {
      sendCodeUpdated(ws, result.files);
      
      // Create checkpoint
      CheckpointManager.autoCheckpoint(projectId, result.explanation, result.files);
    }
    
    // Try to start preview (but don't fail if it doesn't work)
    sendAgentState(ws, 'EXECUTING', 'Starting preview...', 90);
    try {
      const previewUrl = await SandboxManager.startDevServer(projectId);
      sendPreviewReady(ws, previewUrl);
    } catch (previewError) {
      // FAIL IS FAIL: if the preview can't start, the user must see it immediately.
      const message =
        previewError instanceof Error ? previewError.message : 'Failed to start preview server';

      logger.error('Could not start preview server', { projectId, error: message });
      sendError(
        ws,
        'SANDBOX_ERROR',
        `Preview failed to start: ${message}`,
        true,
        'Try your command again. If it still fails, we need to reinitialize the sandbox.'
      );
      sendAgentState(ws, 'ERROR', 'Preview failed to start');
      sendAgentSpeak(ws, `Preview failed to start: ${message}`);
      return;
    }
    
    // Done!
    sendAgentState(ws, 'PRESENTING', result.explanation);
    sendAgentSpeak(ws, result.explanation);
    
  } catch (error) {
    logger.error('Command processing failed', error);
    
    const errorMessage = error instanceof Error ? error.message : 'Failed to process command';
    
    if (errorMessage.includes('Claude') || errorMessage.includes('AI') || errorMessage.includes('Agent')) {
      sendError(ws, 'CLAUDE_ERROR', 'AI processing failed', true, 'Please try rephrasing your request');
    } else if (errorMessage.includes('sandbox') || errorMessage.includes('Sandbox')) {
      sendError(ws, 'SANDBOX_ERROR', 'Preview setup failed', true, 'Retrying...');
    } else {
      sendError(ws, 'HANDLER_ERROR', errorMessage, true, 'Please try again');
    }
    
    sendAgentState(ws, 'ERROR', 'Something went wrong');
  }
}

/**
 * Handle undo command
 */
async function handleUndo(ws: AuthenticatedWebSocket, projectId: string): Promise<void> {
  sendAgentState(ws, 'EXECUTING', 'Undoing last change...');
  
  const previousFiles = CheckpointManager.undo(projectId);
  
  if (!previousFiles) {
    sendError(ws, 'INVALID_COMMAND', 'Nothing to undo', false);
    sendAgentState(ws, 'IDLE', 'Ready');
    return;
  }
  
  try {
    // Restore files to sandbox
    await SandboxManager.writeFiles(projectId, previousFiles);
    
    // Send updates
    sendCodeUpdated(ws, previousFiles);
    sendPreviewReload(ws);
    
    sendAgentState(ws, 'PRESENTING', 'Undone');
    sendAgentSpeak(ws, 'I\'ve undone the last change');
    
  } catch (error) {
    logger.error('Undo failed', error);
    sendError(ws, 'SANDBOX_ERROR', 'Failed to undo', true);
    sendAgentState(ws, 'ERROR', 'Undo failed');
  }
}

// ============================================
// PROJECT HANDLERS
// ============================================

async function handleProjectCreate(
  ws: AuthenticatedWebSocket,
  payload: ProjectCreatePayload
): Promise<void> {
  const userId = ws.userId!;
  logger.info('Creating project', { name: payload.name, userId });
  
  // TODO: Create project in database with Prisma
  // const project = await prisma.project.create({
  //   data: {
  //     name: payload.name,
  //     userId,
  //   },
  // });
  
  // For now, generate a mock project ID
  const projectId = `proj_${Date.now()}`;
  
  ws.send(JSON.stringify(createMessage('project.created', {
    projectId,
    name: payload.name,
  })));
  
  // Set as active project
  ws.currentProjectId = projectId;
  SessionManager.setActiveProject(userId, projectId);
}

async function handleProjectOpen(
  ws: AuthenticatedWebSocket,
  payload: ProjectOpenPayload
): Promise<void> {
  const userId = ws.userId!;
  const { projectId } = payload;
  
  logger.info('Opening project', { projectId, userId });
  
  // TODO: Load project from database
  // const project = await prisma.project.findUnique({
  //   where: { id: projectId, userId },
  // });
  
  // Set as active project
  ws.currentProjectId = projectId;
  SessionManager.setActiveProject(userId, projectId);
  
  // Check if sandbox exists
  const sandboxUrl = SandboxManager.getSandboxUrl(projectId);
  
  ws.send(JSON.stringify(createMessage('project.opened', {
    projectId,
    name: 'Project', // TODO: Get from database
    sandboxUrl,
  })));
  
  // If sandbox exists, send preview URL
  if (sandboxUrl) {
    sendPreviewReady(ws, sandboxUrl);
  }
}

async function handleProjectGetFiles(
  ws: AuthenticatedWebSocket,
  payload: ProjectGetFilesPayload
): Promise<void> {
  const { projectId } = payload;
  
  logger.info('Getting project files', { projectId, userId: ws.userId });
  
  // TODO: Load files from database
  // const files = await prisma.projectFile.findMany({
  //   where: { projectId },
  // });
  
  // For now, try to get from checkpoint
  const checkpoint = CheckpointManager.getLatestCheckpoint(projectId);
  const files = checkpoint?.files || [];
  
  ws.send(JSON.stringify(createMessage('project.files', {
    projectId,
    files,
  })));
}

// ============================================
// MESSAGE SENDERS
// ============================================

function sendAgentState(
  ws: AuthenticatedWebSocket,
  state: AgentStatePayload['state'],
  message?: string,
  progress?: number
): void {
  if (ws.readyState !== 1) { // 1 = OPEN
    logger.warn('Cannot send agent.state - WebSocket not open', { readyState: ws.readyState, state });
    return;
  }
  const msg = createMessage('agent.state', { state, message, progress });
  logger.info('Sending agent.state', { state, message });
  ws.send(JSON.stringify(msg));
}

function sendTranscriptionPartial(ws: AuthenticatedWebSocket, text: string): void {
  ws.send(JSON.stringify(createMessage('transcription.partial', { text })));
}

function sendTranscriptionFinal(ws: AuthenticatedWebSocket, text: string): void {
  ws.send(JSON.stringify(createMessage('transcription.final', { text })));
}

function sendAgentSpeak(ws: AuthenticatedWebSocket, text: string, audio?: string): void {
  if (ws.readyState !== 1) {
    logger.warn('Cannot send agent.speak - WebSocket not open', { readyState: ws.readyState });
    return;
  }
  logger.info('Sending agent.speak', { textLength: text.length });
  ws.send(JSON.stringify(createMessage('agent.speak', { text, audio })));
}

function sendClarification(ws: AuthenticatedWebSocket, question: string, options?: string[]): void {
  ws.send(JSON.stringify(createMessage('agent.clarify', { question, options })));
}

function sendPreviewReady(ws: AuthenticatedWebSocket, url: string): void {
  if (ws.readyState !== 1) {
    logger.warn('Cannot send preview.ready - WebSocket not open', { readyState: ws.readyState });
    return;
  }
  logger.info('Sending preview.ready', { url });
  ws.send(JSON.stringify(createMessage('preview.ready', { url })));
}

function sendPreviewReload(ws: AuthenticatedWebSocket): void {
  ws.send(JSON.stringify(createMessage('preview.reload', {})));
}

function sendCodeUpdated(ws: AuthenticatedWebSocket, files: Array<{ path: string; content: string }>): void {
  if (ws.readyState !== 1) {
    logger.warn('Cannot send code.updated - WebSocket not open', { readyState: ws.readyState });
    return;
  }
  logger.info('Sending code.updated', { fileCount: files.length, paths: files.map(f => f.path) });
  ws.send(JSON.stringify(createMessage('code.updated', { files })));
}

function sendError(
  ws: AuthenticatedWebSocket,
  code: string,
  message: string,
  recoverable: boolean = false,
  suggestedAction?: string
): void {
  ws.send(JSON.stringify(createMessage('error', {
    code,
    message,
    recoverable,
    suggestedAction,
  })));
}

// Export for use in other modules
export {
  sendAgentState,
  sendTranscriptionPartial,
  sendTranscriptionFinal,
  sendAgentSpeak,
  sendClarification,
  sendPreviewReady,
  sendPreviewReload,
  sendCodeUpdated,
  sendError,
};
