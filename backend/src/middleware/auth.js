import { admin, initFirebase } from '../config/firebase.js';

if (process.env.MEMORY_STORE !== '1') {
  initFirebase();
}

/**
 * Verifies Firebase ID token from Authorization: Bearer <token>
 * Attaches req.user = { uid, email?, role? }
 */
export async function requireAuth(req, res, next) {
  if (process.env.MEMORY_STORE === '1') {
    const uid = req.headers['x-demo-uid'] || 'demo_user';
    req.user = { uid: String(uid), email: 'demo@al-asel.ma' };
    return next();
  }
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Bearer token' });
  }
  const idToken = header.slice(7);
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.user = { uid: decoded.uid, email: decoded.email };
    return next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid token', detail: e.message });
  }
}

/** Dev-only bypass: X-Demo-Uid header sets uid without Firebase (never use in prod) */
export function optionalDemoAuth(req, res, next) {
  const demoUid = req.headers['x-demo-uid'];
  if (process.env.NODE_ENV === 'development' && demoUid && typeof demoUid === 'string') {
    req.user = { uid: demoUid, email: 'demo@al-asel.ma' };
  }
  return next();
}

export async function attachUserRole(req, res, next) {
  if (!req.user?.uid) return next();
  try {
    const { docGet } = await import('../db/index.js');
    const u = await docGet('users', req.user.uid);
    if (u?.role) req.user.role = u.role;
  } catch (_) {
    /* ignore */
  }
  next();
}
