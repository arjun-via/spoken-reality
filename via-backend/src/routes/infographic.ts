/**
 * Infographic Generation Routes
 * 
 * POST /api/infographic/generate - Generate interactive infographic from GitHub repo
 */

import { Router, Request, Response } from 'express';
import { generateInfographic } from '../services/infographic.js';
import { logger } from '../utils/logger.js';

const router = Router();

// Get Cerebras API key from environment
const CEREBRAS_API_KEY = process.env.CEREBRAS_API_KEY || '';

/**
 * POST /api/infographic/generate
 * 
 * Request body:
 *   - repo_url: string (required) - GitHub repository URL
 *   - model: string (optional) - Model to use (default: anthropic/claude-opus-4.5)
 * 
 * Response:
 *   - data: InfographicData - The generated infographic JSON
 *   - stats: object - Statistics about the generation
 */
router.post('/generate', async (req: Request, res: Response) => {
  const startTime = Date.now();
  
  try {
    const { repo_url, model } = req.body;
    
    // Validate request
    if (!repo_url) {
      return res.status(400).json({
        error: 'Missing required field: repo_url',
        example: { repo_url: 'https://github.com/owner/repo' },
      });
    }
    
    // Check API key
    if (!CEREBRAS_API_KEY) {
      logger.error('[Infographic] CEREBRAS_API_KEY not configured');
      return res.status(500).json({
        error: 'Server configuration error: Cerebras API key not set',
      });
    }
    
    logger.info(`[Infographic] Generate request for: ${repo_url}`);
    
    // Generate infographic
    const result = await generateInfographic(repo_url, CEREBRAS_API_KEY, model);
    
    const duration = Date.now() - startTime;
    logger.info(`[Infographic] Generation completed in ${duration}ms`);
    
    return res.json({
      success: true,
      duration_ms: duration,
      ...result,
    });
    
  } catch (error) {
    const duration = Date.now() - startTime;
    const message = error instanceof Error ? error.message : 'Unknown error';
    
    logger.error(`[Infographic] Generation failed after ${duration}ms: ${message}`);
    
    return res.status(500).json({
      success: false,
      error: message,
      duration_ms: duration,
    });
  }
});

/**
 * GET /api/infographic/health
 * 
 * Health check for the infographic service
 */
router.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    service: 'infographic',
    api_key_configured: !!CEREBRAS_API_KEY,
  });
});

export default router;
