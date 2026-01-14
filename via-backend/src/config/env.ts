/**
 * Environment Configuration
 * 
 * Loads and validates all environment variables.
 * Fails fast if required variables are missing.
 */

import dotenv from 'dotenv';

// Load .env file in development
dotenv.config();

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function optionalEnv(name: string, defaultValue: string): string {
  return process.env[name] || defaultValue;
}

export const env = {
  // Server
  PORT: parseInt(optionalEnv('PORT', '3000'), 10),
  NODE_ENV: optionalEnv('NODE_ENV', 'development'),

  // Database (optional for now - using in-memory)
  DATABASE_URL: optionalEnv('DATABASE_URL', ''),

  // Clerk (Authentication - optional, using mock auth for testing)
  CLERK_PUBLISHABLE_KEY: optionalEnv('NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY', ''),
  CLERK_SECRET_KEY: optionalEnv('CLERK_SECRET_KEY', ''),

  // E2B (Code Sandboxes)
  E2B_API_KEY: requireEnv('E2B_API_KEY'),

  // OpenAI (Whisper for STT)
  OPENAI_API_KEY: requireEnv('OPENAI_API_KEY'),

  // Anthropic (Claude)
  ANTHROPIC_API_KEY: requireEnv('ANTHROPIC_API_KEY'),

  // xAI (Grok - optional, for TTS if needed)
  XAI_API_KEY: optionalEnv('XAI_API_KEY', ''),

  // OpenRouter (for infographic generation)
  OPENROUTER_API_KEY: optionalEnv('OPENROUTER_API_KEY', ''),

  // Computed
  isDev: optionalEnv('NODE_ENV', 'development') === 'development',
  isProd: optionalEnv('NODE_ENV', 'development') === 'production',
} as const;

export type Env = typeof env;
