import * as db from '../db/index.js';
import { isValidMoroccanTrade } from '../constants/moroccanTrades.js';
import { emitUserInboxPing } from '../realtime.js';
import { attachSocialCounts } from './postEngagement.controller.js';

const LEGACY = {
  service: 'artisan_service',
  demand: 'client_request',
};

function normalizeType(t) {
  const x = String(t || '');
  if (LEGACY[x]) return LEGACY[x];
  if (['artisan_service', 'client_request'].includes(x)) return x;
  return null;
}

export async function createPost(req, res) {
  try {
    const body = req.body || {};
    const type = normalizeType(body.type || body.postType);
    const user = await db.docGet('users', req.user.uid);
    if (!user) {
      return res.status(400).json({ error: 'Complete registration first' });
    }
    if (!type) {
      return res.status(400).json({ error: 'type must be artisan_service or client_request' });
    }
    if (type === 'artisan_service' && user.role !== 'artisan') {
      return res.status(403).json({ error: 'Only artisans can post services' });
    }
    if (type === 'client_request' && user.role !== 'client') {
      return res.status(403).json({ error: 'Only clients can post requests' });
    }

    const content = String(body.content ?? body.text ?? `${body.title || ''}\n${body.body || ''}`).trim();
    if (!content) {
      return res.status(400).json({ error: 'content required' });
    }
    const media = body.media != null ? String(body.media) : body.mediaUrl != null ? String(body.mediaUrl) : '';
    const category = String(body.category || '').trim();
    if (!isValidMoroccanTrade(category)) {
      return res.status(400).json({
        error: 'category must be a valid traditional Moroccan craft (see API trades list).',
      });
    }

    const id = await db.addDoc('posts', {
      userId: req.user.uid,
      authorId: req.user.uid,
      authorRole: user.role,
      type,
      postType: type === 'artisan_service' ? 'service' : 'demand',
      content,
      media: media || null,
      category,
      city: user.city || 'Mediouna',
      createdAt: new Date().toISOString(),
    });
    const saved = await db.docGet('posts', id);
    try {
      const allUsers = await db.queryAll('users', 500);
      /* Notifications temps réel (Socket.IO) : uniquement les artisans — nouvelle demande client dans la zone. */
      if (type === 'client_request') {
        for (const u of allUsers) {
          if (u.role === 'artisan' && u.id !== req.user.uid) {
            emitUserInboxPing(u.id, {
              type: 'new_demand',
              postId: id,
              preview: content.slice(0, 120),
            });
          }
        }
      }
    } catch (_) {
      /* notifications best-effort */
    }
    return res.status(201).json(saved);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

async function authorPopularity(authorId) {
  const u = await db.docGet('users', authorId);
  return (u && u.popularityScore) || 0;
}

export async function withAuthorDisplayName(p) {
  const uid = p.userId || p.authorId;
  if (!uid) return { ...p, authorDisplayName: 'Artisan', authorPhotoUrl: null };
  const u = await db.docGet('users', uid);
  const name =
    (u && (u.name || u.displayName)) ||
    (u && u.firstName && u.lastName ? `${u.firstName} ${u.lastName}`.trim() : null) ||
    'Artisan';
  const photo =
    u && u.photoUrl != null && String(u.photoUrl).trim() ? String(u.photoUrl).trim() : null;
  return { ...p, authorDisplayName: name, authorPhotoUrl: photo };
}

export async function listFeed(req, res) {
  try {
    const { category, postType, type, sort, q } = req.query;
    let rows = (await db.queryAll('posts', 500)).filter((p) => !p.deleted);

    const tFilter = type || postType;
    if (tFilter && tFilter !== 'all') {
      const nt = normalizeType(tFilter) || tFilter;
      rows = rows.filter((p) => {
        const eff =
          p.type ||
          (p.postType === 'service' ? 'artisan_service' : p.postType === 'demand' ? 'client_request' : null);
        return eff === nt || p.postType === tFilter;
      });
    }
    if (category) {
      rows = rows.filter((p) => (p.category || '') === category);
    }

    if (sort === 'popular') {
      const enriched = await Promise.all(
        rows.map(async (p) => ({
          p,
          pop: await authorPopularity(p.userId || p.authorId),
        }))
      );
      enriched.sort((a, b) => b.pop - a.pop || (b.p.createdAt || '').localeCompare(a.p.createdAt || ''));
      rows = enriched.map((e) => e.p);
    } else {
      rows.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
    }

    let items = await Promise.all(rows.map((p) => withAuthorDisplayName(p)));
    const needle = q != null ? String(q).trim().toLowerCase() : '';
    if (needle) {
      items = items.filter((p) => {
        const content = String(p.content || '').toLowerCase();
        const cat = String(p.category || '').toLowerCase();
        const auth = String(p.authorDisplayName || '').toLowerCase();
        const city = String(p.city || '').toLowerCase();
        return (
          content.includes(needle) ||
          cat.includes(needle) ||
          auth.includes(needle) ||
          city.includes(needle)
        );
      });
    }
    const [allLikes, allComments] = await Promise.all([
      db.queryAll('post_likes', 5000),
      db.queryAll('post_comments', 5000),
    ]);
    const out = attachSocialCounts(items, req.user.uid, allLikes, allComments);
    return res.json({ items: out });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function listMine(req, res) {
  try {
    const all = await db.queryAll('posts', 500);
    const mine = all.filter((p) => (p.userId || p.authorId) === req.user.uid && !p.deleted);
    mine.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
    const items = await Promise.all(mine.map((p) => withAuthorDisplayName(p)));
    return res.json({ items });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

/** GET /posts/favorites — posts enregistrés par le client */
export async function listFavorites(req, res) {
  try {
    const user = await db.docGet('users', req.user.uid);
    if (!user || user.role !== 'client') {
      return res.status(403).json({ error: 'Only clients can list favorites' });
    }
    const ids = new Set(Array.isArray(user.favoritePostIds) ? user.favoritePostIds : []);
    if (ids.size === 0) {
      return res.json({ items: [] });
    }
    const all = await db.queryAll('posts', 500);
    const rows = all.filter((p) => ids.has(p.id) && !p.deleted);
    rows.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
    const items = await Promise.all(rows.map((p) => withAuthorDisplayName(p)));
    const [allLikes, allComments] = await Promise.all([
      db.queryAll('post_likes', 5000),
      db.queryAll('post_comments', 5000),
    ]);
    const out = attachSocialCounts(items, req.user.uid, allLikes, allComments);
    return res.json({ items: out });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function updatePost(req, res) {
  try {
    const row = await db.docGet('posts', req.params.id);
    if (!row || (row.userId || row.authorId) !== req.user.uid) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const body = req.body || {};
    const patch = { updatedAt: new Date().toISOString() };
    if (body.content !== undefined) patch.content = String(body.content).trim();
    if (body.media !== undefined) patch.media = body.media ? String(body.media) : null;
    if (body.category !== undefined) patch.category = String(body.category).trim();
    await db.docSet('posts', req.params.id, patch);
    return res.json(await db.docGet('posts', req.params.id));
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function deletePost(req, res) {
  try {
    const row = await db.docGet('posts', req.params.id);
    if (!row || (row.userId || row.authorId) !== req.user.uid) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    await db.docSet('posts', req.params.id, { deleted: true, updatedAt: new Date().toISOString() });
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
