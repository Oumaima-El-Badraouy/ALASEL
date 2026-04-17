import * as db from '../db/index.js';

/** POST /posts/:postId/favorite — client uniquement */
export async function addPostFavorite(req, res) {
  try {
    const postId = req.params.postId;
    const user = await db.docGet('users', req.user.uid);
    if (!user) return res.status(400).json({ error: 'User not found' });
    if (user.role !== 'client') {
      return res.status(403).json({ error: 'Only clients can save favorites' });
    }
    const post = await db.docGet('posts', postId);
    if (!post || post.deleted) return res.status(404).json({ error: 'Post not found' });
    const arr = Array.isArray(user.favoritePostIds) ? [...user.favoritePostIds] : [];
    if (!arr.includes(postId)) arr.push(postId);
    await db.docSet('users', req.user.uid, { favoritePostIds: arr, updatedAt: new Date().toISOString() });
    const u2 = await db.docGet('users', req.user.uid);
    const { passwordHash, ...rest } = u2;
    return res.json(rest);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

/** DELETE /posts/:postId/favorite */
export async function removePostFavorite(req, res) {
  try {
    const postId = req.params.postId;
    const user = await db.docGet('users', req.user.uid);
    if (!user) return res.status(400).json({ error: 'User not found' });
    if (user.role !== 'client') {
      return res.status(403).json({ error: 'Only clients can manage favorites' });
    }
    const arr = (Array.isArray(user.favoritePostIds) ? user.favoritePostIds : []).filter((id) => id !== postId);
    await db.docSet('users', req.user.uid, { favoritePostIds: arr, updatedAt: new Date().toISOString() });
    const u2 = await db.docGet('users', req.user.uid);
    const { passwordHash, ...rest } = u2;
    return res.json(rest);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
