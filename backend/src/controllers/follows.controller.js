import * as db from '../db/index.js';

function pairId(followerId, artisanId) {
  return `${followerId}_${artisanId}`;
}

export async function follow(req, res) {
  try {
    const followingId = req.params.followingId || req.params.artisanId;
    if (!followingId || followingId === req.user.uid) {
      return res.status(400).json({ error: 'invalid followingId' });
    }
    const artisan = await db.docGet('users', followingId);
    if (!artisan || artisan.role !== 'artisan') {
      return res.status(404).json({ error: 'Artisan not found' });
    }
    const id = pairId(req.user.uid, followingId);
    await db.docSet('follows', id, {
      followerId: req.user.uid,
      followingId,
      artisanId: followingId,
      createdAt: new Date().toISOString(),
    });
    const art = await db.docGet('users', followingId);
    if (art) {
      await db.docSet('users', followingId, {
        popularityScore: (art.popularityScore || 0) + 1,
      });
    }
    return res.json({
      ok: true,
      id,
      followerId: req.user.uid,
      followingId,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function unfollow(req, res) {
  try {
    const followingId = req.params.followingId || req.params.artisanId;
    const id = pairId(req.user.uid, followingId);
    const existed = await db.docGet('follows', id);
    await db.docDelete('follows', id);
    if (existed) {
      const art = await db.docGet('users', followingId);
      if (art && (art.popularityScore || 0) > 0) {
        await db.docSet('users', followingId, {
          popularityScore: (art.popularityScore || 1) - 1,
        });
      }
    }
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function listFollowing(req, res) {
  try {
    const all = await db.queryAll('follows', 500);
    const mine = all.filter((f) => f.followerId === req.user.uid);
    const followingIds = mine.map((f) => f.followingId || f.artisanId);
    return res.json({
      count: followingIds.length,
      followingIds,
      artisanIds: followingIds,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function followersCount(req, res) {
  try {
    const { artisanId } = req.params;
    const all = await db.queryAll('follows', 500);
    const n = all.filter((f) => f.artisanId === artisanId).length;
    return res.json({ count: n });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function isFollowing(req, res) {
  try {
    const followingId = req.params.followingId || req.params.artisanId;
    const row = await db.docGet('follows', pairId(req.user.uid, followingId));
    return res.json({ following: !!row });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
