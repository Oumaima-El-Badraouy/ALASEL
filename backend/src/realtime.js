/** Avoid circular imports: set from index.js after Socket.IO boots */
let ioRef = null;

export function setIo(io) {
  ioRef = io;
}

export function emitNewMessage(conversationId, payload) {
  ioRef?.to(`conv:${conversationId}`).emit('new_message', payload);
}
