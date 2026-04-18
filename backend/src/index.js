import http from 'http';
import { Server } from 'socket.io';
import app from './app.js';
import { setIo } from './realtime.js';
import { seedDemoIfEnabled } from './seed/demoSeed.js';
import { loadMemorySnapshot, flushMemorySnapshotSync } from './db/index.js';

const server = http.createServer(app);

const io = new Server(server, {
  cors: { origin: process.env.CORS_ORIGIN?.split(',') || '*' },
});
setIo(io);

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

server.listen(PORT, '0.0.0.0', async () => {
  loadMemorySnapshot();
  await seedDemoIfEnabled();
  console.log(`AL ASEL API listening on 0.0.0.0:${PORT} (memory=${process.env.MEMORY_STORE === '1'})`);
});

export default server;

function exitAfterFlush(code) {
  flushMemorySnapshotSync();
  process.exit(code);
}
process.on('SIGINT', () => exitAfterFlush(0));
process.on('SIGTERM', () => exitAfterFlush(0));
