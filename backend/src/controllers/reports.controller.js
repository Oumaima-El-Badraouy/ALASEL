import * as db from '../db/index.js';

/** POST /reports — signalement problème (client ou artisan). */
export async function createReport(req, res) {
  try {
    const body = req.body || {};
    const text = String(body.text ?? body.description ?? '').trim();
    if (!text || text.length < 3) {
      return res.status(400).json({ error: 'text required (min 3 chars)' });
    }
    if (text.length > 4000) {
      return res.status(400).json({ error: 'text too long' });
    }
    const category = body.category != null ? String(body.category).trim().slice(0, 80) : '';
    const id = await db.addDoc('reports', {
      userId: req.user.uid,
      text,
      category: category || null,
      createdAt: new Date().toISOString(),
      status: 'open',
    });
    return res.status(201).json({ id, ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
