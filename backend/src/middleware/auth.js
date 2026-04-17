import { admin, initFirebase } from '../config/firebase.js';
import { verifyJwtToken } from '../controllers/auth.controller.js';

if (process.env.MEMORY_STORE !== '1' && process.env.USE_FIREBASE_AUTH === '1') {
  initFirebase();
}

/**
 * JWT (email/password) OR optional demo header OR Firebase if enabled.
 */
export async function requireAuth(req, res, next) {
  if (process.env.USE_DEMO_AUTH === '1' && process.env.MEMORY_STORE === '1') {
    const uid = req.headers['x-demo-uid'] || 'demo_user';
    req.user = { uid: String(uid), email: 'demo@al-asel.ma' };
    return next();
  }

  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const token = header.slice(7);

  try {
    const payload = verifyJwtToken(token);
    req.user = { uid: payload.sub, email: payload.email, role: payload.role };
    return next();
  } catch (_) {
    /* try Firebase legacy */
  }

  if (process.env.USE_FIREBASE_AUTH === '1') {
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      req.user = { uid: decoded.uid, email: decoded.email };
      return next();
    } catch (e) {
      return res.status(401).json({ error: 'Invalid token' });
    }
  }

  return res.status(401).json({ error: 'Invalid or expired token' });
}
