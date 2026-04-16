import * as db from '../db/index.js';

export async function getMe(req, res) {
  try {
    const row = await db.docGet('users', req.user.uid);
    if (!row) {
      return res.status(404).json({ error: 'User not found', hint: 'POST /api/v1/users/bootstrap' });
    }
    return res.json(row);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function bootstrap(req, res) {
  try {
    const { role, displayName, phone, city } = req.body || {};
    if (!['client', 'artisan'].includes(role)) {
      return res.status(400).json({ error: 'role must be client or artisan' });
    }
    const existing = await db.docGet('users', req.user.uid);
    if (existing) {
      return res.json(existing);
    }
    const user = {
      role,
      displayName: displayName || 'User',
      phone: phone || '',
      city: city || '',
      createdAt: new Date().toISOString(),
    };
    await db.docSet('users', req.user.uid, user);
    return res.status(201).json({ id: req.user.uid, ...user });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function patchMe(req, res) {
  try {
    const allowed = ['displayName', 'phone', 'city', 'photoUrl'];
    const patch = {};
    for (const k of allowed) {
      if (req.body[k] !== undefined) patch[k] = req.body[k];
    }
    patch.updatedAt = new Date().toISOString();
    await db.docSet('users', req.user.uid, patch);
    const row = await db.docGet('users', req.user.uid);
    return res.json(row);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
