import * as db from '../db/index.js';
import { computeTrustScore } from '../services/trustScore.service.js';
import { rankArtisans } from '../services/matching.service.js';

function enrichProfile(raw) {
  if (!raw) return null;
  const trustScore = computeTrustScore({
    avgRating: raw.avgRating,
    reviewCount: raw.reviewCount,
    avgResponseHours: raw.avgResponseHours,
    completedJobs90d: raw.completedJobs90d,
    reportedIssues: raw.reportedIssues,
  });
  return { ...raw, trustScore };
}

export async function listArtisans(req, res) {
  try {
    const { category, city, minRating, available } = req.query;
    let rows = (await db.queryAll('artisanProfiles', 300)).filter((a) => a.public !== false);
    if (category) {
      rows = rows.filter((a) => (a.categories || []).includes(category));
    }
    if (city) {
      const c = city.toLowerCase();
      rows = rows.filter(
        (a) =>
          !a.serviceAreas?.length ||
          (a.serviceAreas || []).some((x) => x.toLowerCase() === c)
      );
    }
    if (minRating) {
      const m = parseFloat(minRating);
      rows = rows.filter((a) => (a.avgRating || 0) >= m);
    }
    if (available === 'true') {
      rows = rows.filter((a) => a.available !== false);
    }
    rows = rows.map(enrichProfile).sort((a, b) => b.trustScore - a.trustScore);
    return res.json({ items: rows });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function getArtisan(req, res) {
  try {
    const row = await db.docGet('artisanProfiles', req.params.id);
    if (!row || !row.public) {
      return res.status(404).json({ error: 'Artisan not found' });
    }
    return res.json(enrichProfile(row));
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function upsertProfile(req, res) {
  try {
    const u = await db.docGet('users', req.user.uid);
    if (!u || u.role !== 'artisan') {
      return res.status(403).json({ error: 'Only artisans can publish a profile' });
    }
    const body = req.body || {};
    const profile = {
      userId: req.user.uid,
      displayName: body.displayName || u.displayName,
      bio: body.bio || '',
      categories: Array.isArray(body.categories) ? body.categories : [],
      serviceAreas: Array.isArray(body.serviceAreas) ? body.serviceAreas : [],
      portfolio: Array.isArray(body.portfolio) ? body.portfolio : [],
      available: body.available !== false,
      public: body.public !== false,
      avgRating: body.avgRating ?? 0,
      reviewCount: body.reviewCount ?? 0,
      avgResponseHours: body.avgResponseHours ?? null,
      completedJobs90d: body.completedJobs90d ?? 0,
      reportedIssues: body.reportedIssues ?? 0,
      updatedAt: new Date().toISOString(),
    };
    const id = req.user.uid;
    await db.docSet('artisanProfiles', id, profile);
    return res.json(enrichProfile({ id, ...profile }));
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function addPortfolioItem(req, res) {
  try {
    const row = await db.docGet('artisanProfiles', req.user.uid);
    if (!row) {
      return res.status(404).json({ error: 'Create profile first' });
    }
    const { type, beforeUrl, afterUrl, caption, videoUrl } = req.body || {};
    if (!['before_after', 'image', 'video'].includes(type)) {
      return res.status(400).json({ error: 'type must be before_after, image, or video' });
    }
    const item = {
      id: `pf_${Date.now()}`,
      type,
      beforeUrl: beforeUrl || '',
      afterUrl: afterUrl || '',
      caption: caption || '',
      videoUrl: videoUrl || '',
      createdAt: new Date().toISOString(),
    };
    const portfolio = [...(row.portfolio || []), item];
    await db.docSet('artisanProfiles', req.user.uid, { portfolio, updatedAt: new Date().toISOString() });
    return res.status(201).json(item);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function matchArtisans(req, res) {
  try {
    const { category, city, urgency } = req.query;
    if (!category) {
      return res.status(400).json({ error: 'category is required' });
    }
    let rows = (await db.queryAll('artisanProfiles', 300)).filter(
      (a) => a.public !== false && (a.categories || []).includes(category)
    );
    const ranked = rankArtisans({ category, city, urgency }, rows);
    return res.json({ suggestions: ranked.slice(0, 12) });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
