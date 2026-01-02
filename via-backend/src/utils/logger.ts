/**
 * Simple Logger
 * 
 * Structured logging with levels.
 * Can be replaced with Winston/Pino later if needed.
 */

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LOG_LEVELS: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

const currentLevel = LOG_LEVELS[process.env.LOG_LEVEL as LogLevel] ?? LOG_LEVELS.info;

function formatMessage(level: LogLevel, message: string, data?: unknown): string {
  const timestamp = new Date().toISOString();
  const dataStr = data ? ` ${JSON.stringify(data)}` : '';
  return `[${timestamp}] [${level.toUpperCase()}] ${message}${dataStr}`;
}

export const logger = {
  debug(message: string, data?: unknown): void {
    if (LOG_LEVELS.debug >= currentLevel) {
      console.debug(formatMessage('debug', message, data));
    }
  },

  info(message: string, data?: unknown): void {
    if (LOG_LEVELS.info >= currentLevel) {
      console.info(formatMessage('info', message, data));
    }
  },

  warn(message: string, data?: unknown): void {
    if (LOG_LEVELS.warn >= currentLevel) {
      console.warn(formatMessage('warn', message, data));
    }
  },

  error(message: string, error?: unknown): void {
    if (LOG_LEVELS.error >= currentLevel) {
      const errorData = error instanceof Error 
        ? { message: error.message, stack: error.stack }
        : error;
      console.error(formatMessage('error', message, errorData));
    }
  },
};
