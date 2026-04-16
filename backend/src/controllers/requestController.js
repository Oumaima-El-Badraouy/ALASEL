import * as db from '../db/index.js';

export async function createRequest(req, res) {
  const clientId = req.user.uid;
  const { title, description, category, city, budgetHint, preferredDates, urgency } =
    req.body || {};
  if (!title || !category) {
    return res.status(400).json({ error: 'title and category required' });
  }
  const id = await db.addDoc('requests', {
    clientId,
    title,
    description: description || '',
    category,
    city: city || '',
    budgetHint: budgetHint || null,
    preferredDates: preferredDates || [],
    urgency: urgency || 'normal',
    status: 'open',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  const row = await db.docGet('requests', id);
  return res.status(201).json(row);
}

export async function listMyRequests(req, res) {
  const all = await db.queryAll('requests', 200);
  const mine = all.filter((r) => r.clientId === req.user.uid);
  mine.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
  return res.json({ items: mine });
}

export async function listForArtisan(req, res) {
  const uid = req.user.uid;
  const artisan = await db.docGet('artisans', uid);
  if (!artisan) return res.json({ items: [] });

  const cats = new Set(artisan.categories || []);
  const all = await db.queryAll('requests', 200);
  const open = all.filter((r) => r.status === 'open' && cats.has(r.category));
  open.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
  return res.json({ items: open });
}

export async function getRequest(req, res) {
  const row = await db.docGet('requests', req.params.id);
  if (!row) return res.status(404).json({ error: 'Not found' });
  return res.json(row);
}

export async function patchRequestStatus(req, res) {
  const row = await db.docGet('requests', req.params.id);
  if (!row) return res.status(404).json({ error: 'Not found' });
  const { status, assignedArtisanId } = req.body || {};
  const next = {
    ...row,
    status: status || row.status,
    assignedArtisanId: assignedArtisanId ?? row.assignedArtisanId,
    updatedAt: new Date().toISOString(),
  };
  await db.docSet('requests', req.params.id, next);
  return res.json(await db.docGet('requests', req.params.id));
}
