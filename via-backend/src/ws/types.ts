/**
 * WebSocket Message Types
 * 
 * Defines all message types for client-server communication.
 * Keep in sync with iOS client.
 */

// ============================================
// BASE MESSAGE FORMAT
// ============================================

export interface WebSocketMessage<T = unknown> {
  type: string;
  payload: T;
  timestamp: number;
  messageId: string;
}

// ============================================
// CLIENT → SERVER MESSAGES
// ============================================

// Voice messages
export interface VoiceStartPayload {
  projectId: string;
}

export interface VoiceChunkPayload {
  audio: string; // Base64-encoded audio chunk
}

export interface VoiceEndPayload {}

// Command messages
export interface CommandPayload {
  text: string;
  projectId: string;
}

// Project messages
export interface ProjectCreatePayload {
  name: string;
}

export interface ProjectOpenPayload {
  projectId: string;
}

export interface ProjectGetFilesPayload {
  projectId: string;
}

// Client message types
export type ClientMessageType =
  | 'voice.start'
  | 'voice.chunk'
  | 'voice.end'
  | 'command'
  | 'project.create'
  | 'project.open'
  | 'project.getFiles'
  | 'git.commit';

// ============================================
// SERVER → CLIENT MESSAGES
// ============================================

// Agent state
export type AgentState =
  | 'IDLE'
  | 'LISTENING'
  | 'INTERPRETING'
  | 'CLARIFYING'
  | 'PLANNING'
  | 'EXECUTING'
  | 'PRESENTING'
  | 'ERROR';

export interface AgentStatePayload {
  state: AgentState;
  message?: string;
  progress?: number; // 0-100
}

// Transcription
export interface TranscriptionPartialPayload {
  text: string;
}

export interface TranscriptionFinalPayload {
  text: string;
}

// Agent responses
export interface AgentSpeakPayload {
  text: string;
  audio?: string; // Base64-encoded audio
}

export interface AgentClarifyPayload {
  question: string;
  options?: string[];
}

// Preview
export interface PreviewReadyPayload {
  url: string;
}

export interface PreviewReloadPayload {}

// Code updates
export interface CodeUpdatedPayload {
  files: Array<{
    path: string;
    content: string;
  }>;
}

// Errors
export interface ErrorPayload {
  code: string;
  message: string;
  recoverable: boolean;
  suggestedAction?: string;
}

// Project responses
export interface ProjectCreatedPayload {
  projectId: string;
  name: string;
}

export interface ProjectOpenedPayload {
  projectId: string;
  name: string;
  sandboxUrl?: string;
}

export interface ProjectFilesPayload {
  projectId: string;
  files: Array<{
    path: string;
    content: string;
  }>;
}

// Server message types
export type ServerMessageType =
  | 'agent.state'
  | 'transcription.partial'
  | 'transcription.final'
  | 'agent.speak'
  | 'agent.clarify'
  | 'preview.ready'
  | 'preview.reload'
  | 'code.updated'
  | 'error'
  | 'project.created'
  | 'project.opened'
  | 'project.files'
  | 'git.committed';

// ============================================
// HELPER FUNCTIONS
// ============================================

export function createMessage<T>(
  type: ServerMessageType,
  payload: T
): WebSocketMessage<T> {
  return {
    type,
    payload,
    timestamp: Date.now(),
    messageId: crypto.randomUUID(),
  };
}
