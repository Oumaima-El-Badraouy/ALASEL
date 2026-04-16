import * as db from '../db/index.js';

export async function bootstrapUser(req, res) {
  const { uid } = req.user;
  const { role, displayName, city, phone } = req.body || {};
  if (!['client', 'artisan'].includes(role)) {
    return res.status(400).json({ error: 'role must be client or artisan' });
  }
  const existing = await db.docGet('users', uid);
  const payload = {
    role,
    displayName: displayName || existing?.displayName || 'User',
    city: city || existing?.city || '',
    phone: phone || existing?.phone || '',
    updatedAt: new Date().toISOString(),
    createdAt: existing?.createdAt || new Date().toISOString(),
  };
  await db.docSet('users', uid, payload);
  return res.json({ id: uid, ...payload });
}

export async function getMe(req, res) {
  const u = await db.docGet('users', req.user.uid);
  if (!u) return res.status(404).json({ error: 'User not bootstrapped' });
  return res.json(u);
}

export async function patchMe(req, res) {
  const { displayName, city, phone } = req.body || {};
  const prev = await db.docGet('users', req.user.uid);
  if (!prev) return res.status(404).json({ error: 'User not found' });
  await db.docSet('users', req.user.uid, {
    ...prev,
    displayName: displayName ?? prev.displayName,
    city: city ?? prev.city,
    phone: phone ?? prev.phone,
    updatedAt: new Date().toISOString(),
  });
  const next = await db.docGet('users', req.user.uid);
  return res.json(next);
}
