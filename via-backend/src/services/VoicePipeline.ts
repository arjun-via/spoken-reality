/**
 * Voice Pipeline
 *
 * Handles voice input/output via OpenAI Whisper API.
 * - Speech-to-text (STT) for user input via Whisper
 * - Text-to-speech (TTS) for agent responses
 *
 * API: https://platform.openai.com/docs/api-reference/audio
 * Cost: $0.006/minute (Whisper)
 */

import OpenAI from 'openai';
import { env } from '../config/env.js';
import { logger } from '../utils/logger.js';
import { VoiceError } from '../utils/errors.js';

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: env.OPENAI_API_KEY,
});

// Store audio buffers per user during recording
const audioBuffers = new Map<string, Buffer[]>();

/**
 * Start listening for voice input
 */
export function startListening(userId: string): void {
  audioBuffers.set(userId, []);
  logger.info('Started listening', { userId });
}

/**
 * Process incoming audio chunk
 */
export function processAudioChunk(userId: string, audioBase64: string): void {
  const buffers = audioBuffers.get(userId);
  if (buffers) {
    const chunk = Buffer.from(audioBase64, 'base64');
    buffers.push(chunk);
    logger.debug('Audio chunk received', { userId, chunkSize: chunk.length });
  }
}

/**
 * Stop listening and transcribe audio
 */
export async function stopListening(userId: string): Promise<string> {
  const buffers = audioBuffers.get(userId);
  
  if (!buffers || buffers.length === 0) {
    logger.warn('No audio data to transcribe', { userId });
    return '';
  }
  
  // Combine all audio chunks
  const audioBuffer = Buffer.concat(buffers);
  audioBuffers.delete(userId);
  
  logger.info('Transcribing audio', { userId, audioSize: audioBuffer.length });
  
  try {
    const transcription = await transcribeAudio(audioBuffer);
    logger.info('Transcription complete', { userId, text: transcription });
    return transcription;
  } catch (error) {
    logger.error('Transcription failed', error);
    throw new VoiceError('Failed to transcribe audio');
  }
}

/**
 * Transcribe audio using OpenAI Whisper
 */
async function transcribeAudio(audioBuffer: Buffer): Promise<string> {
  try {
    // Create WAV header for PCM audio (16-bit, 16kHz, mono)
    const wavBuffer = createWavBuffer(audioBuffer);

    // Create a File-like object for OpenAI API
    const file = new File([wavBuffer], 'audio.wav', { type: 'audio/wav' });

    // Call Whisper API
    const transcription = await openai.audio.transcriptions.create({
      file: file,
      model: 'whisper-1',
      language: 'en', // Optional: specify language for better accuracy
    });

    logger.info('Whisper transcription successful', { text: transcription.text });
    return transcription.text;
  } catch (error) {
    logger.error('Whisper transcription failed', error);
    throw new VoiceError('Failed to transcribe audio with Whisper');
  }
}

/**
 * Create WAV file buffer from raw PCM data
 */
function createWavBuffer(pcmBuffer: Buffer): Buffer {
  const sampleRate = 16000;
  const numChannels = 1;
  const bitsPerSample = 16;
  const byteRate = sampleRate * numChannels * (bitsPerSample / 8);
  const blockAlign = numChannels * (bitsPerSample / 8);
  const dataSize = pcmBuffer.length;

  const header = Buffer.alloc(44);

  // RIFF chunk descriptor
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + dataSize, 4);
  header.write('WAVE', 8);

  // fmt sub-chunk
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16); // Subchunk1Size
  header.writeUInt16LE(1, 20); // AudioFormat (PCM)
  header.writeUInt16LE(numChannels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(bitsPerSample, 34);

  // data sub-chunk
  header.write('data', 36);
  header.writeUInt32LE(dataSize, 40);

  return Buffer.concat([header, pcmBuffer]);
}

/**
 * Convert text to speech using Grok API
 */
export async function textToSpeech(text: string): Promise<Buffer> {
  logger.info('Converting text to speech', { textLength: text.length });
  
  try {
    // TODO: Implement actual Grok TTS API call
    /*
    const response = await fetch('https://api.x.ai/v1/audio/speech', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.XAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'grok-2-audio',
        input: text,
        voice: 'alloy', // or other voice options
      }),
    });
    
    if (!response.ok) {
      throw new VoiceError(`Grok TTS API error: ${response.status}`);
    }
    
    return Buffer.from(await response.arrayBuffer());
    */
    
    // Mock response for development
    logger.warn('Using mock TTS (Grok API not implemented yet)');
    return Buffer.from([]);
  } catch (error) {
    logger.error('TTS failed', error);
    throw new VoiceError('Failed to convert text to speech');
  }
}

/**
 * Check if user is currently recording
 */
export function isRecording(userId: string): boolean {
  return audioBuffers.has(userId);
}

/**
 * Cancel recording without transcribing
 */
export function cancelRecording(userId: string): void {
  audioBuffers.delete(userId);
  logger.info('Recording cancelled', { userId });
}
