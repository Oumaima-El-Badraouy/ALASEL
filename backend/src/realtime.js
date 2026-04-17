/** Avoid circular imports: set from index.js after Socket.IO boots */
let ioRef = null;

export function setIo(io) {
  ioRef = io;
}

export function emitNewMessage(conversationId, payload) {
  ioRef?.to(`conv:${conversationId}`).emit('new_message', payload);
}

/** Notification temps réel pour un utilisateur (ex. nouveau message dans la boîte). */
export function emitUserInboxPing(userId, payload) {
  if (!userId || typeof userId !== 'string') return;
  ioRef?.to(`user:${userId}`).emit('inbox_ping', payload);
}
