import * as db from '../db/index.js';
import { computeTrustScore } from '../services/trustScore.service.js';
import { rankArtisans } from '../services/matching.service.js';

function enrichTrust(profile) {
  const trustScore = computeTrustScore({
    avgRating: profile.avgRating,
    reviewCount: profile.reviewCount,
    avgResponseHours: profile.avgResponseHours,
    completedJobs90d: profile.completedJobs90d,
    reportedIssues: profile.reportedIssues,
  });
  return { ...profile, trustScore };
}

export async function listArtisans(req, res) {
  const {
    category,
    city,
    minRating,
    available,
    sort = 'trust',
  } = req.query;

  let list = await db.queryAll('artisans', 300);
  if (category) {
    list = list.filter((a) => (a.categories || []).includes(String(category)));
  }
  if (city) {
    const c = String(city).toLowerCase();
    list = list.filter(
      (a) =>
        !a.serviceAreas?.length ||
        a.serviceAreas.some((x) => String(x).toLowerCase() === c)
    );
  }
  if (minRating) {
    const m = Number(minRating);
    list = list.filter((a) => (a.avgRating || 0) >= m);
  }
  if (available === 'true') {
    list = list.filter((a) => a.available !== false);
  }

  list = list.map(enrichTrust);
  if (sort === 'rating') {
    list.sort((a, b) => (b.avgRating || 0) - (a.avgRating || 0));
  } else {
    list.sort((a, b) => b.trustScore - a.trustScore);
  }
  return res.json({ items: list });
}

export async function getArtisan(req, res) {
  const row = await db.docGet('artisans', req.params.id);
  if (!row) return res.status(404).json({ error: 'Artisan not found' });
  return res.json(enrichTrust(row));
}

export async function upsertArtisanProfile(req, res) {
  const uid = req.user.uid;
  const user = await db.docGet('users', uid);
  if (!user || user.role !== 'artisan') {
    return res.status(403).json({ error: 'Only artisans can publish a profile' });
  }

  const body = req.body || {};
  const prev = (await db.docGet('artisans', uid)) || {};
  const payload = {
    id: uid,
    displayName: body.displayName ?? prev.displayName ?? user.displayName,
    bio: body.bio ?? prev.bio ?? '',
    categories: body.categories ?? prev.categories ?? [],
    serviceAreas: body.serviceAreas ?? prev.serviceAreas ?? [],
    portfolio: body.portfolio ?? prev.portfolio ?? [],
    available: body.available ?? prev.available ?? true,
    avgRating: prev.avgRating ?? 0,
    reviewCount: prev.reviewCount ?? 0,
    avgResponseHours: body.avgResponseHours ?? prev.avgResponseHours ?? 24,
    completedJobs90d: prev.completedJobs90d ?? 0,
    reportedIssues: prev.reportedIssues ?? 0,
    updatedAt: new Date().toISOString(),
    createdAt: prev.createdAt || new Date().toISOString(),
  };
  await db.docSet('artisans', uid, payload);
  return res.json(enrichTrust(await db.docGet('artisans', uid)));
}

export async function addPortfolioItem(req, res) {
  const uid = req.user.uid;
  const artisan = await db.docGet('artisans', uid);
  if (!artisan) return res.status(404).json({ error: 'Create profile first' });

  const { title, beforeUrl, afterUrl, caption, videoUrl } = req.body || {};
  if (!beforeUrl || !afterUrl) {
    return res.status(400).json({ error: 'beforeUrl and afterUrl required (Before/After proof)' });
  }
  const item = {
    id: `pf_${Date.now()}`,
    title: title || 'Réalisation',
    beforeUrl,
    afterUrl,
    caption: caption || '',
    videoUrl: videoUrl || null,
    createdAt: new Date().toISOString(),
  };
  const portfolio = [...(artisan.portfolio || []), item];
  await db.docSet('artisans', uid, { ...artisan, portfolio, updatedAt: new Date().toISOString() });
  return res.json({ portfolio });
}

export async function matchArtisans(req, res) {
  const { category, city, urgency } = req.query;
  if (!category) return res.status(400).json({ error: 'category is required' });

  const all = await db.queryAll('artisans', 300);
  const filtered = all.filter((a) => (a.categories || []).includes(String(category)));
  const ranked = rankArtisans({ category, city, urgency }, filtered);
  return res.json({ request: { category, city, urgency }, results: ranked.slice(0, 12) });
}
