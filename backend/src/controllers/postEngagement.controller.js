import * as db from '../db/index.js';

function authorFields(u) {
  if (!u) {
    return {
      authorFirstName: '',
      authorLastName: '',
      authorDisplayName: 'Utilisateur',
      authorRole: null,
    };
  }
  const fn = String(u.firstName || '').trim();
  const ln = String(u.lastName || '').trim();
  let display =
    (u.name && String(u.name).trim()) ||
    (u.displayName && String(u.displayName).trim()) ||
    null;
  if (!display && (fn || ln)) display = `${fn} ${ln}`.trim();
  if (!display && u.email) display = String(u.email).split('@')[0];
  if (!display) display = 'Utilisateur';
  return {
    authorFirstName: fn,
    authorLastName: ln,
    authorDisplayName: display,
    authorRole: u.role || null,
  };
}

/** Ajoute likesCount, commentsCount, likedByMe aux posts (batch). */
export function attachSocialCounts(posts, userId, allLikes, allComments) {
  const likeCount = new Map();
  const likedSet = new Set();
  for (const l of allLikes) {
    if (!l.postId) continue;
    likeCount.set(l.postId, (likeCount.get(l.postId) || 0) + 1);
    if (l.userId === userId) likedSet.add(l.postId);
  }
  const commentCount = new Map();
  for (const c of allComments) {
    if (!c.postId) continue;
    commentCount.set(c.postId, (commentCount.get(c.postId) || 0) + 1);
  }
  return posts.map((p) => ({
    ...p,
    likesCount: likeCount.get(p.id) || 0,
    commentsCount: commentCount.get(p.id) || 0,
    likedByMe: likedSet.has(p.id),
  }));
}

async function countLikesForPost(postId) {
  const all = await db.queryAll('post_likes', 5000);
  return all.filter((l) => l.postId === postId).length;
}

/** GET /posts/:postId/comments */
export async function listComments(req, res) {
  try {
    const postId = req.params.postId;
    const post = await db.docGet('posts', postId);
    if (!post || post.deleted) {
      return res.status(404).json({ error: 'Post not found' });
    }
    const all = await db.queryAll('post_comments', 2000);
    const rows = all.filter((c) => c.postId === postId);
    rows.sort((a, b) => (a.createdAt || '').localeCompare(b.createdAt || ''));
    const items = await Promise.all(
      rows.map(async (c) => {
        const u = await db.docGet('users', c.userId);
        const a = authorFields(u);
        return { ...c, ...a };
      })
    );
    return res.json({ items });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

/** POST /posts/:postId/comments — clients et artisans */
export async function addComment(req, res) {
  try {
    const user = await db.docGet('users', req.user.uid);
    if (!user || (user.role !== 'client' && user.role !== 'artisan')) {
      return res.status(403).json({ error: 'Only clients and artisans can comment' });
    }
    const postId = req.params.postId;
    const post = await db.docGet('posts', postId);
    if (!post || post.deleted) {
      return res.status(404).json({ error: 'Post not found' });
    }
    const text = String(req.body?.text ?? '').trim();
    if (!text) {
      return res.status(400).json({ error: 'text required' });
    }
    if (text.length > 2000) {
      return res.status(400).json({ error: 'text too long (max 2000)' });
    }
    const createdAt = new Date().toISOString();
    const id = await db.addDoc('post_comments', {
      postId,
      userId: req.user.uid,
      text,
      createdAt,
    });
    const u = await db.docGet('users', req.user.uid);
    const a = authorFields(u);
    return res.status(201).json({
      id,
      postId,
      userId: req.user.uid,
      text,
      createdAt,
      ...a,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

/** GET /posts/:postId/likes — liste des personnes ayant aimé */
export async function listPostLikes(req, res) {
  try {
    const postId = req.params.postId;
    const post = await db.docGet('posts', postId);
    if (!post || post.deleted) {
      return res.status(404).json({ error: 'Post not found' });
    }
    const all = await db.queryAll('post_likes', 5000);
    const likes = all.filter((l) => l.postId === postId);
    const items = await Promise.all(
      likes.map(async (l) => {
        const u = await db.docGet('users', l.userId);
        const a = authorFields(u);
        return {
          userId: l.userId,
          firstName: a.authorFirstName,
          lastName: a.authorLastName,
          authorDisplayName: a.authorDisplayName,
          role: a.authorRole,
          createdAt: l.createdAt,
        };
      })
    );
    items.sort((a, b) => (a.createdAt || '').localeCompare(b.createdAt || ''));
    return res.json({ items });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

/** POST /posts/:postId/like — toggle like (clients et artisans) */
export async function toggleLike(req, res) {
  try {
    const user = await db.docGet('users', req.user.uid);
    if (!user || (user.role !== 'client' && user.role !== 'artisan')) {
      return res.status(403).json({ error: 'Only clients and artisans can like posts' });
    }
    const postId = req.params.postId;
    const post = await db.docGet('posts', postId);
    if (!post || post.deleted) {
      return res.status(404).json({ error: 'Post not found' });
    }
    const all = await db.queryAll('post_likes', 5000);
    const existing = all.find((l) => l.postId === postId && l.userId === req.user.uid);
    if (existing) {
      await db.docDelete('post_likes', existing.id);
    } else {
      await db.addDoc('post_likes', {
        postId,
        userId: req.user.uid,
        createdAt: new Date().toISOString(),
      });
    }
    const likesCount = await countLikesForPost(postId);
    return res.json({ liked: !existing, likesCount });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
