import * as db from '../db/index.js';
import { withAuthorDisplayName } from './posts.controller.js';
import { attachSocialCounts } from './postEngagement.controller.js';
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
    rows = rows
      .map((a) => enrichProfile({ ...a, id: a.id || a.userId }))
      .sort((a, b) => b.trustScore - a.trustScore);
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

/** GET /artisans/:id/full — profil public : utilisateur, stats, publications service */
export async function getArtisanFull(req, res) {
  try {
    const id = req.params.id;
    const profileRaw = await db.docGet('artisanProfiles', id);
    if (!profileRaw || profileRaw.public === false) {
      return res.status(404).json({ error: 'Artisan not found' });
    }
    const profile = { ...profileRaw, id: profileRaw.id || id, userId: profileRaw.userId || id };
    const user = await db.docGet('users', id);
    const cats = new Set(profile.categories || []);

    const allPosts = (await db.queryAll('posts', 500)).filter((p) => !p.deleted);
    const servicePosts = [];
    let demandsInTradeCount = 0;

    for (const p of allPosts) {
      const author = p.userId || p.authorId;
      const rawT = p.type || '';
      const eff =
        rawT ||
        (p.postType === 'service' ? 'artisan_service' : p.postType === 'demand' ? 'client_request' : '');
      if (author === id && eff === 'artisan_service') {
        servicePosts.push(p);
      }
      if (eff === 'client_request' && p.category && cats.has(String(p.category))) {
        demandsInTradeCount += 1;
      }
    }

    servicePosts.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
    const withAuthors = await Promise.all(servicePosts.map((p) => withAuthorDisplayName(p)));
    const uid = req.user?.uid || null;
    const [allLikes, allComments] = await Promise.all([
      db.queryAll('post_likes', 5000),
      db.queryAll('post_comments', 5000),
    ]);
    const postsOut = attachSocialCounts(withAuthors, uid, allLikes, allComments);

    const name = user?.name || profile.displayName || '';
    let firstName = user?.firstName ?? null;
    let lastName = user?.lastName ?? null;
    if ((!firstName || !lastName) && name) {
      const parts = String(name).trim().split(/\s+/);
      if (parts.length >= 2) {
        firstName = firstName || parts[0];
        lastName = lastName || parts.slice(1).join(' ');
      } else if (parts.length === 1) {
        firstName = firstName || parts[0];
      }
    }

    return res.json({
      profile: enrichProfile(profile),
      user: {
        name,
        firstName,
        lastName,
        phone: user?.phone ?? '',
        photoUrl: user?.photoUrl ?? null,
        description: user?.description ?? profile.bio ?? '',
        domain: user?.domain ?? '',
      },
      stats: {
        servicePostsCount: postsOut.length,
        demandsInTradeCount,
      },
      posts: postsOut,
    });
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
      displayName: body.displayName || u.name || u.displayName,
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
