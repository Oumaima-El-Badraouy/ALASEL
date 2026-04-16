import * as db from '../db/index.js';
import { emitNewMessage } from '../realtime.js';

export async function listConversations(req, res) {
  try {
    const all = await db.queryAll('conversations', 200);
    const mine = all.filter(
      (c) => c.participantIds && c.participantIds.includes(req.user.uid)
    );
    return res.json({
      items: mine.sort((a, b) => (b.updatedAt || '').localeCompare(a.updatedAt || '')),
    });
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

export async function postMessage(req, res) {
  try {
    const conv = await db.docGet('conversations', req.params.id);
    if (!conv || !conv.participantIds?.includes(req.user.uid)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const { text } = req.body || {};
    if (!text?.trim()) {
      return res.status(400).json({ error: 'text required' });
    }
    const createdAt = new Date().toISOString();
    const id = await db.addDoc('messages', {
      conversationId: req.params.id,
      senderId: req.user.uid,
      text: text.trim(),
      createdAt,
    });
    await db.docSet('conversations', req.params.id, { updatedAt: createdAt });
    const payload = {
      id,
      conversationId: req.params.id,
      senderId: req.user.uid,
      text: text.trim(),
      createdAt,
    };
    emitNewMessage(req.params.id, payload);
    return res.status(201).json({ id });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
