/**
 * Point d’entrée Vercel (serverless) — n’appelle pas server.listen().
 * Socket.IO reste disponible uniquement en local via `npm start` (src/index.js).
 */
import 'dotenv/config';
import app from '../src/app.js';
import { loadMemorySnapshot } from '../src/db/index.js';
import { seedDemoIfEnabled } from '../src/seed/demoSeed.js';

loadMemorySnapshot();
seedDemoIfEnabled().catch((e) => console.warn('[al-asel] seed:', e.message));

export default app;
