# Railway Deployment Issue - Via Backend

## Problem Summary
The Node.js backend deploys to Railway, shows "Online" status, healthcheck passes during build, but **all external HTTP requests return 502 Bad Gateway**.

## Environment
- **Platform**: Railway (paid tier)
- **Domain**: `spoken-reality-production.up.railway.app`
- **Repository**: `github.com/arjun-via/spoken-reality`
- **Root Directory**: `via-backend` (configured in Railway)
- **Node Version**: 20+

## Current Behavior
1. `git push` triggers Railway build
2. Build succeeds with message: `=== Successfully Built! ===`
3. Healthcheck during build passes: `[1/1] Healthcheck succeeded!`
4. Deploy logs show: `🚀 Via Backend running on port 8080` (or 3000)
5. Railway dashboard shows service as "Online"
6. **BUT**: All external requests return 502:
   ```
   curl https://spoken-reality-production.up.railway.app/api/health
   {"status":"error","code":502,"message":"Application failed to respond"}
   ```

## What We've Tried
1. ✅ Set explicit host binding to `0.0.0.0` - no change
2. ✅ Removed host binding (let Node default) - no change
3. ✅ Set `PORT=8080` in railway.toml - no change
4. ✅ Removed PORT override to let Railway set it - no change
5. ✅ Created `start.sh` script - caused "start.sh not found" error
6. ✅ Upgraded to paid Railway tier - no change
7. ✅ Multiple redeploys - no change

## Key Files

### `/via-backend/package.json`
```json
{
  "name": "via-backend",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
```

### `/via-backend/railway.toml`
```toml
[build]
builder = "nixpacks"

[deploy]
startCommand = "npm run start"
healthcheckPath = "/api/health"
healthcheckTimeout = 30
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3
```

### `/via-backend/src/index.ts`
```typescript
import express from 'express';
import { createServer } from 'http';
import { env } from './config/env.js';

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api', healthRouter);
app.get('/', (req, res) => res.json({ status: 'running' }));

const httpServer = createServer(app);
initWebSocketServer(httpServer);

// Start server
httpServer.listen(env.PORT, () => {
  logger.info(`🚀 Via Backend running on port ${env.PORT}`);
});
```

### `/via-backend/src/config/env.ts`
```typescript
export const env = {
  PORT: parseInt(process.env.PORT || '3000', 10),
  NODE_ENV: process.env.NODE_ENV || 'development',
  // ... other env vars
}
```

### `/via-backend/src/routes/health.ts`
```typescript
import { Router } from 'express';
const router = Router();

router.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});

export default router;
```

## Railway Dashboard Observations
- Service shows: `Port 3000 · Metal Edge`
- Status: `Online` with warning icons
- Domain: `spoken-reality-production.up.railway.app`
- Start Command in settings shows: `npm run start`

## Deploy Logs (from Railway)
```
Starting Container
> node dist/index.js
[INFO] WebSocket server initialized
[INFO] 🚀 Via Backend running on port 8080
[INFO] Environment: production
[INFO] WebSocket: ws://localhost:8080/ws
[INFO] Health: http://localhost:8080/api/health
> via-backend@1.0.0 start
```

## Suspected Issues
1. **Port mismatch**: Railway UI shows Port 3000, but logs show 8080
2. **Internal vs External networking**: Healthcheck works internally during build but external requests fail
3. **Railway edge proxy not routing correctly** to the container

## Questions to Investigate
1. Is Railway's PORT environment variable actually being set?
2. Is there a networking/firewall issue between Railway edge and the container?
3. Does the service need explicit port configuration in Railway dashboard?
4. Is there a conflict between railway.toml and Railway dashboard settings?

## Required Fix
Make the backend accessible via `https://spoken-reality-production.up.railway.app/api/health` returning `{"status":"ok"}`.

## Repository Structure
```
/spoken-reality/
├── SpokenRealityApp/     # iOS app
├── via-backend/          # Node.js backend (this is what deploys to Railway)
│   ├── src/
│   │   ├── index.ts
│   │   ├── config/env.ts
│   │   ├── routes/health.ts
│   │   └── ws/server.ts
│   ├── package.json
│   ├── tsconfig.json
│   ├── railway.toml
│   └── start.sh          # Created but may not be needed
└── RAILWAY_DEBUG.md      # This file
```

## Environment Variables Needed
- `E2B_API_KEY` - Required
- `OPENAI_API_KEY` - Required
- `ANTHROPIC_API_KEY` - Required
- `PORT` - Should be set by Railway automatically
- `NODE_ENV` - Optional, defaults to 'development'
