import * as db from '../db/index.js';
import { emitNewMessage } from '../realtime.js';

function peerDisplay(peer) {
  if (!peer) return 'Utilisateur';
  const n = peer.name || peer.displayName;
  if (n) return String(n);
  const fn = `${peer.firstName || ''} ${peer.lastName || ''}`.trim();
  if (fn) return fn;
  const em = peer.email ? String(peer.email).split('@')[0] : '';
  return em ? em.charAt(0).toUpperCase() + em.slice(1) : 'Utilisateur';
}

export async function listConversations(req, res) {
  try {
    const all = await db.queryAll('conversations', 200);
    const allMsgs = await db.queryAll('messages', 3000);
    const mine = all.filter(
      (c) => c.participantIds && c.participantIds.includes(req.user.uid)
    );
    const sorted = mine.sort((a, b) => (b.updatedAt || '').localeCompare(a.updatedAt || ''));
    const uid = req.user.uid;
    const items = [];
    for (const c of sorted) {
      const peerId = otherParticipant(c, uid);
      const peer = peerId ? await db.docGet('users', peerId) : null;
      const myLast = (c.lastReadAt && c.lastReadAt[uid]) || '';
      const convMsgs = allMsgs.filter((m) => m.conversationId === c.id);
      const unread = convMsgs.filter(
        (m) =>
          m.senderId !== uid &&
          String(m.createdAt || '').localeCompare(String(myLast || '\u0000')) > 0
      ).length;
      items.push({
        ...c,
        peerId,
        peerDisplayName: peerDisplay(peer),
        unreadCount: unread,
      });
    }
    return res.json({ items });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function openOrGetConversation(req, res) {
  try {
    const { peerId } = req.body || {};
    if (!peerId) {
      return res.status(400).json({ error: 'peerId required' });
    }
    const all = await db.queryAll('conversations', 300);
    const pair = [req.user.uid, peerId].sort().join('_');
    let found = all.find((c) => c.pairKey === pair);
    if (!found) {
      const id = await db.addDoc('conversations', {
        pairKey: pair,
        participantIds: [req.user.uid, peerId],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });
      found = await db.docGet('conversations', id);
    }
    return res.json(found);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function listMessages(req, res) {
  try {
    const conv = await db.docGet('conversations', req.params.id);
    if (!conv || !conv.participantIds?.includes(req.user.uid)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const all = await db.queryAll('messages', 500);
    const items = all
      .filter((m) => m.conversationId === req.params.id)
      .sort((a, b) => (a.createdAt || '').localeCompare(b.createdAt || ''));
    return res.json({ items });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

function otherParticipant(conv, meId) {
  return conv.participantIds.find((id) => id !== meId);
}

export async function postMessage(req, res) {
  try {
    const conv = await db.docGet('conversations', req.params.id);
    if (!conv || !conv.participantIds?.includes(req.user.uid)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const { text, audioUrl } = req.body || {};
    const hasText = text && String(text).trim();
    const hasAudio = audioUrl && String(audioUrl).trim();
    if (!hasText && !hasAudio) {
      return res.status(400).json({ error: 'text or audioUrl required' });
    }
    const receiverId = otherParticipant(conv, req.user.uid);
    const createdAt = new Date().toISOString();
    const id = await db.addDoc('messages', {
      conversationId: req.params.id,
      senderId: req.user.uid,
      receiverId: receiverId || null,
      text: hasText ? String(text).trim() : '',
      audioUrl: hasAudio ? String(audioUrl).trim() : null,
      messageType: hasAudio ? 'audio' : 'text',
      timestamp: createdAt,
      createdAt,
    });
    await db.docSet('conversations', req.params.id, { updatedAt: createdAt });
    const payload = {
      id,
      conversationId: req.params.id,
      senderId: req.user.uid,
      receiverId,
      text: hasText ? String(text).trim() : '',
      audioUrl: hasAudio ? String(audioUrl).trim() : null,
      messageType: hasAudio ? 'audio' : 'text',
      createdAt,
    };
    emitNewMessage(req.params.id, payload);
    return res.status(201).json({ id });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function markConversationRead(req, res) {
  try {
    const conv = await db.docGet('conversations', req.params.id);
    if (!conv || !conv.participantIds?.includes(req.user.uid)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const now = new Date().toISOString();
    const lastReadAt = { ...(conv.lastReadAt || {}), [req.user.uid]: now };
    await db.docSet('conversations', req.params.id, { lastReadAt }, true);
    return res.json({ ok: true, lastReadAt: now });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
