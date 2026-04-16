import * as db from '../db/index.js';

export async function createRequest(req, res) {
  try {
    const { title, description, category, city, budgetMin, budgetMax, urgency } = req.body || {};
    if (!title || !category) {
      return res.status(400).json({ error: 'title and category required' });
    }
    const id = await db.addDoc('serviceRequests', {
      clientId: req.user.uid,
      title,
      description: description || '',
      category,
      city: city || '',
      budgetMin: budgetMin ?? null,
      budgetMax: budgetMax ?? null,
      urgency: urgency || 'normal',
      status: 'open',
      createdAt: new Date().toISOString(),
    });
    return res.status(201).json({ id });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function listMyRequests(req, res) {
  try {
    const all = await db.queryAll('serviceRequests', 200);
    const mine = all.filter((r) => r.clientId === req.user.uid);
    return res.json({ items: mine.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || '')) });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function listForArtisan(req, res) {
  try {
    const profile = await db.docGet('artisanProfiles', req.user.uid);
    if (!profile) {
      return res.status(403).json({ error: 'Artisan profile required' });
    }
    const cats = new Set(profile.categories || []);
    const all = await db.queryAll('serviceRequests', 200);
    const open = all.filter((r) => r.status === 'open' && cats.has(r.category));
    return res.json({ items: open.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || '')) });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function getRequest(req, res) {
  try {
    const row = await db.docGet('serviceRequests', req.params.id);
    if (!row) {
      return res.status(404).json({ error: 'Not found' });
    }
    if (row.clientId !== req.user.uid) {
      const p = await db.docGet('artisanProfiles', req.user.uid);
      const ok = p && (p.categories || []).includes(row.category);
      if (!ok) {
        return res.status(403).json({ error: 'Forbidden' });
      }
    }
    return res.json(row);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function patchRequestStatus(req, res) {
  try {
    const row = await db.docGet('serviceRequests', req.params.id);
    if (!row || row.clientId !== req.user.uid) {
      return res.status(403).json({ error: 'Only client can update' });
    }
    const { status } = req.body || {};
    const allowed = ['open', 'assigned', 'done', 'cancelled'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ error: 'invalid status' });
    }
    await db.docSet('serviceRequests', req.params.id, { status, updatedAt: new Date().toISOString() });
    return res.json(await db.docGet('serviceRequests', req.params.id));
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
