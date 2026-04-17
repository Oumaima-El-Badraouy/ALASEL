import 'dotenv/config';
import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { Server } from 'socket.io';
import v1 from './routes/v1.routes.js';
import { initFirebase } from './config/firebase.js';
import { setIo } from './realtime.js';
import { seedDemoIfEnabled } from './seed/demoSeed.js';
import { loadMemorySnapshot, flushMemorySnapshotSync } from './db/index.js';

if (process.env.MEMORY_STORE !== '1') {
  try {
    initFirebase();
  } catch (e) {
    console.warn('[al-asel] Firebase init warning:', e.message);
  }
}

const app = express();
const server = http.createServer(app);

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const uploadsRoot = path.join(__dirname, '..', 'uploads');
app.use('/uploads', express.static(uploadsRoot));
const io = new Server(server, {
  cors: { origin: process.env.CORS_ORIGIN?.split(',') || '*' },
});
setIo(io);

app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '50mb' }));

app.use('/api/v1', v1);

io.on('connection', (socket) => {
  socket.on('join_user', (userId) => {
    if (typeof userId === 'string' && userId.length > 0) {
      socket.join(`user:${userId}`);
    }
  });
  socket.on('join_conversation', (conversationId) => {
    if (typeof conversationId === 'string') {
      socket.join(`conv:${conversationId}`);
    }
  });
  socket.on('leave_conversation', (conversationId) => {
    if (typeof conversationId === 'string') {
      socket.leave(`conv:${conversationId}`);
    }
  });
});

const PORT = Number(process.env.PORT) || 4000;

server.listen(PORT, async () => {
  loadMemorySnapshot();
  await seedDemoIfEnabled();
  console.log(`AL ASEL API listening on :${PORT} (memory=${process.env.MEMORY_STORE === '1'})`);
});

export default server;

function exitAfterFlush(code) {
  flushMemorySnapshotSync();
  process.exit(code);
}
process.on('SIGINT', () => exitAfterFlush(0));
process.on('SIGTERM', () => exitAfterFlush(0));
