import * as db from '../db/index.js';

function stripSecrets(u) {
  if (!u) return null;
  const { passwordHash, emailVerifyCode, ...rest } = u;
  return rest;
}

export async function getMe(req, res) {
  try {
    const row = await db.docGet('users', req.user.uid);
    if (!row) {
      return res.status(404).json({ error: 'User not found', hint: 'POST /api/v1/auth/register' });
    }
    return res.json(stripSecrets(row));
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

/** Inscription Mediouna — client (nom, prénom, email) ou artisan (+ domaine, desc, tél). */
export async function register(req, res) {
  try {
    const {
      role,
      mediounaResident,
      firstName,
      lastName,
      email,
      phone,
      domain,
      description,
    } = req.body || {};

    if (!mediounaResident) {
      return res.status(400).json({
        error: 'AL ASEL est réservé aux habitants de Mediouna. Cochez la case pour continuer.',
      });
    }
    if (!['client', 'artisan'].includes(role)) {
      return res.status(400).json({ error: 'role must be client or artisan' });
    }
    const existing = await db.docGet('users', req.user.uid);
    if (existing) {
      return res.json(existing);
    }

    const displayName = `${firstName || ''} ${lastName || ''}`.trim() || 'User';
    const user = {
      role,
      mediounaResident: true,
      city: 'Mediouna',
      firstName: firstName || '',
      lastName: lastName || '',
      email: email || req.user?.email || '',
      displayName,
      createdAt: new Date().toISOString(),
    };

    if (role === 'artisan') {
      user.phone = phone || '';
      user.domain = typeof domain === 'string' ? domain : '';
      user.bio = description || '';
      const categories = user.domain
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
      await db.docSet('users', req.user.uid, user);
      await db.docSet('artisanProfiles', req.user.uid, {
        userId: req.user.uid,
        displayName,
        bio: user.bio,
        categories: categories.length ? categories : ['general'],
        serviceAreas: ['Mediouna'],
        portfolio: [],
        available: true,
        public: true,
        avgRating: 0,
        reviewCount: 0,
        avgResponseHours: null,
        completedJobs90d: 0,
        reportedIssues: 0,
        updatedAt: new Date().toISOString(),
      });
    } else {
      await db.docSet('users', req.user.uid, user);
    }

    return res.status(201).json(await db.docGet('users', req.user.uid));
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

/** Ancien flux démo — crée un user sans formulaire complet */
export async function bootstrap(req, res) {
  try {
    const { role, displayName, phone, city } = req.body || {};
    if (!['client', 'artisan'].includes(role)) {
      return res.status(400).json({ error: 'role must be client or artisan' });
    }
    const existing = await db.docGet('users', req.user.uid);
    if (existing) {
      return res.json(existing);
    }
    const parts = (displayName || 'User').trim().split(/\s+/);
    const user = {
      role,
      mediounaResident: true,
      city: city || 'Mediouna',
      firstName: parts[0] || 'User',
      lastName: parts.length > 1 ? parts.slice(1).join(' ') : '',
      displayName: displayName || 'User',
      phone: phone || '',
      email: '',
      createdAt: new Date().toISOString(),
    };
    await db.docSet('users', req.user.uid, user);
    if (role === 'artisan') {
      await db.docSet('artisanProfiles', req.user.uid, {
        userId: req.user.uid,
        displayName: user.displayName,
        bio: '',
        categories: ['plumbing'],
        serviceAreas: ['Mediouna'],
        portfolio: [],
        available: true,
        public: true,
        avgRating: 0,
        reviewCount: 0,
        updatedAt: new Date().toISOString(),
      });
    }
    return res.status(201).json(await db.docGet('users', req.user.uid));
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function patchMe(req, res) {
  try {
    const allowed = [
      'displayName',
      'name',
      'phone',
      'city',
      'location',
      'photoUrl',
      'firstName',
      'lastName',
      'email',
      'bio',
      'description',
      'domain',
      'cinRectoUrl',
      'cinVersoUrl',
    ];
    const patch = {};
    for (const k of allowed) {
      if (req.body[k] !== undefined) patch[k] = req.body[k];
    }
    if (patch.description !== undefined && patch.bio === undefined) {
      patch.bio = patch.description;
    }
    if (patch.name !== undefined) {
      patch.displayName = patch.name;
    }
    if (patch.firstName !== undefined || patch.lastName !== undefined) {
      const u = await db.docGet('users', req.user.uid);
      const fn = patch.firstName ?? u.firstName ?? '';
      const ln = patch.lastName ?? u.lastName ?? '';
      patch.name = `${fn} ${ln}`.trim() || u.name;
      patch.displayName = patch.name;
    }
    patch.updatedAt = new Date().toISOString();
    await db.docSet('users', req.user.uid, patch);

    const u2 = await db.docGet('users', req.user.uid);
    if (
      u2.role === 'artisan' &&
      (patch.bio !== undefined ||
        patch.domain !== undefined ||
        patch.name !== undefined ||
        patch.location !== undefined)
    ) {
      const prof = await db.docGet('artisanProfiles', req.user.uid);
      if (prof) {
        const ap = { ...prof, updatedAt: new Date().toISOString() };
        if (patch.bio !== undefined) ap.bio = patch.bio;
        if (patch.description !== undefined) ap.bio = patch.description;
        if (patch.domain !== undefined) {
          ap.categories = String(patch.domain)
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean);
        }
        if (patch.location !== undefined) ap.location = patch.location;
        ap.displayName = u2.name || u2.displayName || prof.displayName;
        await db.docSet('artisanProfiles', req.user.uid, ap);
      }
    }

    return res.json(stripSecrets(await db.docGet('users', req.user.uid)));
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

/** GET /users/peer/:peerId/contact — téléphone de l’autre partie (client ↔ artisan, chat) */
/** POST /users/me/email/request-code — code 6 chiffres (démo : renvoyé dans la réponse si MEMORY_STORE). */
export async function requestEmailVerification(req, res) {
  try {
    const code = String(Math.floor(100000 + Math.random() * 900000));
    const expires = Date.now() + 15 * 60 * 1000;
    await db.docSet('users', req.user.uid, {
      emailVerifyCode: code,
      emailVerifyExpires: expires,
    });
    const demo = process.env.MEMORY_STORE === '1';
    return res.json({ ok: true, ...(demo ? { demoCode: code } : {}) });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

/** POST /users/me/email/verify — body: { code: string } */
export async function verifyEmail(req, res) {
  try {
    const code = String(req.body?.code ?? '').trim();
    if (code.length < 4) {
      return res.status(400).json({ error: 'code required' });
    }
    const u = await db.docGet('users', req.user.uid);
    if (!u) return res.status(404).json({ error: 'User not found' });
    if (String(u.emailVerifyCode) !== code) {
      return res.status(400).json({ error: 'Invalid code' });
    }
    if (u.emailVerifyExpires && Date.now() > Number(u.emailVerifyExpires)) {
      return res.status(400).json({ error: 'Code expired' });
    }
    await db.docSet('users', req.user.uid, {
      emailVerified: true,
      emailVerifyCode: null,
      emailVerifyExpires: null,
    });
    return res.json({ ok: true, emailVerified: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export async function getPeerContact(req, res) {
  try {
    const peerId = req.params.peerId;
    const me = await db.docGet('users', req.user.uid);
    const peer = await db.docGet('users', peerId);
    if (!me || !peer) {
      return res.status(404).json({ error: 'Not found' });
    }
    const roles = new Set([me.role, peer.role]);
    if (!roles.has('artisan') || !roles.has('client')) {
      return res.status(403).json({ error: 'Contact only between client and artisan' });
    }
    return res.json({
      phone: peer.phone != null ? String(peer.phone) : '',
      displayName: peer.name || peer.displayName || '',
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
