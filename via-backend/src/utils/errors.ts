/**
 * Custom Error Classes
 * 
 * Structured errors for different failure scenarios.
 * Error codes match what the iOS frontend expects.
 * 
 * Error Codes (from BACKEND_REQUIREMENTS.md):
 * - TRANSCRIPTION_FAILED - Grok Voice API error
 * - CLAUDE_ERROR - Claude API error
 * - SANDBOX_ERROR - E2B sandbox error
 * - INVALID_COMMAND - User command not understood
 * - PROJECT_NOT_FOUND - Invalid project ID
 * - RATE_LIMIT - API rate limit exceeded
 */

// Error codes that the frontend expects
export const ErrorCodes = {
  // Voice/Transcription
  TRANSCRIPTION_FAILED: 'TRANSCRIPTION_FAILED',
  
  // AI/Claude
  CLAUDE_ERROR: 'CLAUDE_ERROR',
  
  // Sandbox/E2B
  SANDBOX_ERROR: 'SANDBOX_ERROR',
  
  // Commands
  INVALID_COMMAND: 'INVALID_COMMAND',
  
  // Projects
  PROJECT_NOT_FOUND: 'PROJECT_NOT_FOUND',
  
  // Rate limiting
  RATE_LIMIT: 'RATE_LIMIT',
  
  // Auth
  AUTH_ERROR: 'AUTH_ERROR',
  
  // Generic
  HANDLER_ERROR: 'HANDLER_ERROR',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  UNKNOWN_ERROR: 'UNKNOWN_ERROR',
} as const;

export type ErrorCode = typeof ErrorCodes[keyof typeof ErrorCodes];

export class AppError extends Error {
  public readonly code: ErrorCode;
  public readonly statusCode: number;
  public readonly recoverable: boolean;
  public readonly suggestedAction?: string;

  constructor(
    message: string,
    code: ErrorCode,
    statusCode: number = 500,
    recoverable: boolean = false,
    suggestedAction?: string
  ) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.statusCode = statusCode;
    this.recoverable = recoverable;
    this.suggestedAction = suggestedAction;
  }

  toJSON() {
    return {
      code: this.code,
      message: this.message,
      recoverable: this.recoverable,
      suggestedAction: this.suggestedAction,
    };
  }
}

// Authentication errors
export class AuthError extends AppError {
  constructor(message: string = 'Authentication required') {
    super(message, ErrorCodes.AUTH_ERROR, 401, false, 'Please sign in again');
  }
}

// Voice/Transcription errors
export class VoiceError extends AppError {
  constructor(message: string = 'Voice processing failed') {
    super(message, ErrorCodes.TRANSCRIPTION_FAILED, 500, true, 'Please try speaking again');
  }
}

// AI/Claude errors
export class AIError extends AppError {
  constructor(message: string = 'AI processing failed') {
    super(message, ErrorCodes.CLAUDE_ERROR, 500, true, 'Please try rephrasing your request');
  }
}

// Sandbox/E2B errors
export class SandboxError extends AppError {
  constructor(message: string = 'Code execution failed') {
    super(message, ErrorCodes.SANDBOX_ERROR, 500, true, 'Retrying...');
  }
}

// Command errors
export class InvalidCommandError extends AppError {
  constructor(message: string = 'Command not understood') {
    super(message, ErrorCodes.INVALID_COMMAND, 400, true, 'Please try rephrasing');
  }
}

// Project errors
export class ProjectNotFoundError extends AppError {
  constructor(projectId: string) {
    super(`Project not found: ${projectId}`, ErrorCodes.PROJECT_NOT_FOUND, 404, false);
  }
}

// Rate limit errors
export class RateLimitError extends AppError {
  constructor(message: string = 'Too many requests') {
    super(message, ErrorCodes.RATE_LIMIT, 429, true, 'Please wait a moment and try again');
  }
}

// Validation errors
export class ValidationError extends AppError {
  constructor(message: string) {
    super(message, ErrorCodes.VALIDATION_ERROR, 400, false);
  }
}

// Generic not found
export class NotFoundError extends AppError {
  constructor(resource: string) {
    super(`${resource} not found`, ErrorCodes.PROJECT_NOT_FOUND, 404, false);
  }
}

/**
 * Convert any error to AppError format for consistent handling
 */
export function toAppError(error: unknown): AppError {
  if (error instanceof AppError) {
    return error;
  }
  
  if (error instanceof Error) {
    // Try to categorize based on message
    const message = error.message.toLowerCase();
    
    if (message.includes('rate limit') || message.includes('429')) {
      return new RateLimitError(error.message);
    }
    
    if (message.includes('auth') || message.includes('token') || message.includes('401')) {
      return new AuthError(error.message);
    }
    
    if (message.includes('transcri') || message.includes('audio') || message.includes('voice')) {
      return new VoiceError(error.message);
    }
    
    if (message.includes('claude') || message.includes('anthropic') || message.includes('ai')) {
      return new AIError(error.message);
    }
    
    if (message.includes('sandbox') || message.includes('e2b')) {
      return new SandboxError(error.message);
    }
    
    return new AppError(error.message, ErrorCodes.UNKNOWN_ERROR, 500, true, 'Please try again');
  }
  
  return new AppError('An unknown error occurred', ErrorCodes.UNKNOWN_ERROR, 500, true, 'Please try again');
}
