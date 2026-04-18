import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import * as db from '../db/index.js';
import { isValidMoroccanTrade } from '../constants/moroccanTrades.js';

const JWT_SECRET = process.env.JWT_SECRET || 'al-asel-dev-change-me-in-production';
const JWT_EXPIRES = process.env.JWT_EXPIRES || '30d';

function sanitize(u) {
  if (!u) return null;
  const { passwordHash, ...rest } = u;
  return rest;
}

function signToken(user) {
  return jwt.sign(
    { sub: user.id, email: user.email, role: user.role },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES }
  );
}

/** POST /auth/register — Artisan ou Client, Mediouna obligatoire */
export async function register(req, res) {
  try {
    const body = req.body || {};
    const isMediouna =
      body.isMediounaVerified === true ||
      body.mediounaResident === true ||
      body.isFromMediouna === true;
    if (!isMediouna) {
      return res.status(400).json({
        error: 'You must confirm that you are from Mediouna city.',
      });
    }

    const role = body.role;
    if (!['artisan', 'client'].includes(role)) {
      return res.status(400).json({ error: 'role must be artisan or client' });
    }

    const email = String(body.email || '').trim().toLowerCase();
    const password = String(body.password || '');
    if (!email || !password || password.length < 6) {
      return res.status(400).json({ error: 'Valid email and password (min 6 chars) required' });
    }

    const existing = await db.findUserByEmail(email);
    if (existing) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const id = crypto.randomUUID();

    let userDoc;

    if (role === 'client') {
      const firstName = String(body.firstName || '').trim();
      const lastName = String(body.lastName || '').trim();
      const phone = String(body.phone || '').trim();
      if (!firstName || !lastName || !phone) {
        return res.status(400).json({
          error: 'Client registration requires firstName, lastName, and phone.',
        });
      }
      const name = `${firstName} ${lastName}`.trim();
      const photoUrl =
        body.photoUrl != null && String(body.photoUrl).trim()
          ? String(body.photoUrl).trim()
          : null;
      userDoc = {
        id,
        role: 'client',
        name,
        firstName,
        lastName,
        email,
        phone,
        photoUrl,
        domain: null,
        description: null,
        isMediounaVerified: true,
        city: 'Mediouna',
        passwordHash,
        createdAt: new Date().toISOString(),
        popularityScore: 0,
        favoritePostIds: [],
      };
    } else {
      const fullName = String(body.fullName || body.name || '').trim();
      const domain = String(body.domain || '').trim();
      const description = String(body.description || '').trim();
      const phone = String(body.phone || '').trim();
      if (!fullName || !domain || !description || !phone) {
        return res.status(400).json({
          error: 'fullName, domain, description, phone required for artisan',
        });
      }
      if (String(description).trim().length < 10) {
        return res.status(400).json({
          error: 'Artisan profile: description must be at least 10 characters.',
        });
      }
      const categories = domain
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
      for (const c of categories) {
        if (!isValidMoroccanTrade(c)) {
          return res.status(400).json({
            error: 'domain must be one or more valid traditional Moroccan craft ids (from the registration list).',
          });
        }
      }
      const photoUrl =
        body.photoUrl != null && String(body.photoUrl).trim()
          ? String(body.photoUrl).trim()
          : null;
      const cinRectoUrl =
        body.cinRectoUrl != null && String(body.cinRectoUrl).trim()
          ? String(body.cinRectoUrl).trim()
          : null;
      const cinVersoUrl =
        body.cinVersoUrl != null && String(body.cinVersoUrl).trim()
          ? String(body.cinVersoUrl).trim()
          : null;
      if (!cinRectoUrl || !cinVersoUrl) {
        return res.status(400).json({
          error: 'Artisan registration requires cinRectoUrl and cinVersoUrl (national ID photos).',
        });
      }
      userDoc = {
        id,
        role: 'artisan',
        name: fullName,
        firstName: null,
        lastName: null,
        email,
        phone,
        domain,
        description,
        photoUrl,
        cinRectoUrl,
        cinVersoUrl,
        isMediounaVerified: true,
        city: 'Mediouna',
        passwordHash,
        createdAt: new Date().toISOString(),
        popularityScore: 0,
        favoritePostIds: [],
      };
      await db.docSet('artisanProfiles', id, {
        userId: id,
        displayName: fullName,
        bio: description,
        categories: categories.length ? categories : ['general'],
        serviceAreas: ['Mediouna'],
        portfolio: [],
        available: true,
        public: true,
        avgRating: 0,
        reviewCount: 0,
        updatedAt: new Date().toISOString(),
      });
    }

    await db.docSet('users', id, userDoc);
    const token = signToken(userDoc);
    return res.status(201).json({ token, user: sanitize(userDoc) });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

/** POST /auth/login */
export async function login(req, res) {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const password = String(req.body?.password || '');
    if (!email || !password) {
      return res.status(400).json({ error: 'email and password required' });
    }
    const user = await db.findUserByEmail(email);
    if (!user || !user.passwordHash) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const token = signToken(user);
    return res.json({ token, user: sanitize(user) });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

export function verifyJwtToken(token) {
  return jwt.verify(token, JWT_SECRET);
}
