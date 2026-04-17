import bcrypt from 'bcryptjs';
import * as db from '../db/index.js';

/** Optional demo data (MEMORY_STORE). Login: ali@demo.ma / Mediouna2026! — hassan@demo.ma / Mediouna2026! */
export async function seedDemoIfEnabled() {
  if (process.env.MEMORY_STORE !== '1' || process.env.SEED_DEMO !== '1') {
    return;
  }
  const already = await db.docGet('users', 'demo_client');
  if (already) {
    console.log('[al-asel] Demo seed skipped (data already loaded from snapshot or session)');
    return;
  }
  const pwd = bcrypt.hashSync('Mediouna2026!', 10);
  const now = new Date().toISOString();

  await db.docSet('users', 'demo_client', {
    id: 'demo_client',
    role: 'client',
    name: 'Ali Benani',
    firstName: 'Ali',
    lastName: 'Benani',
    email: 'ali@demo.ma',
    phone: null,
    domain: null,
    description: null,
    isMediounaVerified: true,
    city: 'Mediouna',
    mediounaResident: true,
    passwordHash: pwd,
    popularityScore: 0,
    favoritePostIds: [],
    createdAt: now,
  });

  await db.docSet('users', 'demo_artisan', {
    id: 'demo_artisan',
    role: 'artisan',
    name: 'Hassan Artisan',
    firstName: null,
    lastName: null,
    email: 'hassan@demo.ma',
    phone: '+212600000000',
    domain: 'plumbing,painting',
    description: 'Plomberie & peinture — Mediouna.',
    isMediounaVerified: true,
    city: 'Mediouna',
    mediounaResident: true,
    passwordHash: pwd,
    popularityScore: 12,
    favoritePostIds: [],
    createdAt: now,
  });

  await db.docSet('artisanProfiles', 'demo_artisan', {
    userId: 'demo_artisan',
    displayName: 'Hassan Artisan',
    bio: 'Plomberie & peinture — interventions rapides, devis clair.',
    categories: ['plumbing', 'painting'],
    serviceAreas: ['Mediouna'],
    portfolio: [],
    available: true,
    public: true,
    avgRating: 4.7,
    reviewCount: 18,
    avgResponseHours: 4,
    completedJobs90d: 12,
    reportedIssues: 0,
    updatedAt: now,
  });

  await db.docSet('posts', 'seed_demand_1', {
    id: 'seed_demand_1',
    userId: 'demo_client',
    authorId: 'demo_client',
    authorRole: 'client',
    type: 'client_request',
    postType: 'demand',
    content: 'I need a plumber — fuite salon. Bonjour, fuite sous évier, Mediouna centre.',
    media: null,
    category: 'plumbing',
    city: 'Mediouna',
    createdAt: now,
  });
  await db.docSet('posts', 'seed_service_1', {
    id: 'seed_service_1',
    userId: 'demo_artisan',
    authorId: 'demo_artisan',
    authorRole: 'artisan',
    type: 'artisan_service',
    postType: 'service',
    content: 'Installation & dépannage plomberie — intervention rapide, devis gratuit.',
    media: null,
    category: 'plumbing',
    city: 'Mediouna',
    createdAt: now,
  });
  console.log('[al-asel] Demo seed (JWT: ali@demo.ma / Mediouna2026!)');
}
