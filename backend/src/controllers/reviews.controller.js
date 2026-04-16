import * as db from '../db/index.js';
import { computeTrustScore } from '../services/trustScore.service.js';

async function recomputeArtisanStats(artisanId) {
  const all = await db.queryAll('reviews', 500);
  const revs = all.filter((r) => r.artisanId === artisanId);
  const n = revs.length;
  const avg = n ? revs.reduce((s, r) => s + (r.rating || 0), 0) / n : 0;
  const profile = await db.docGet('artisanProfiles', artisanId);
  if (!profile) return;
  await db.docSet('artisanProfiles', artisanId, {
    avgRating: Math.round(avg * 10) / 10,
    reviewCount: n,
    updatedAt: new Date().toISOString(),
  });
}

export async function createReview(req, res) {
  try {
    const { artisanId, rating, text, requestId } = req.body || {};
    if (!artisanId || !rating) {
      return res.status(400).json({ error: 'artisanId and rating required' });
    }
    const r = Math.min(5, Math.max(1, Number(rating)));
    const id = await db.addDoc('reviews', {
      clientId: req.user.uid,
      artisanId,
      requestId: requestId || '',
      rating: r,
      text: text || '',
      createdAt: new Date().toISOString(),
    });
    await recomputeArtisanStats(artisanId);
    const artisan = await db.docGet('artisanProfiles', artisanId);
    const trustScore = computeTrustScore({
      avgRating: artisan?.avgRating,
      reviewCount: artisan?.reviewCount,
      avgResponseHours: artisan?.avgResponseHours,
      completedJobs90d: artisan?.completedJobs90d,
      reportedIssues: artisan?.reportedIssues,
    });
    return res.status(201).json({ id, trustScore });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function listForArtisan(req, res) {
  try {
    const all = await db.queryAll('reviews', 300);
    const items = all
      .filter((r) => r.artisanId === req.params.artisanId)
      .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
    return res.json({ items });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
