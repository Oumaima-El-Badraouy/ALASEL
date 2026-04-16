import * as db from '../db/index.js';

/** Optional demo data for hackathon judges (MEMORY_STORE only). */
export async function seedDemoIfEnabled() {
  if (process.env.MEMORY_STORE !== '1' || process.env.SEED_DEMO !== '1') {
    return;
  }
  await db.docSet('users', 'demo_client', {
    role: 'client',
    displayName: 'Client Démo',
    city: 'Casablanca',
    createdAt: new Date().toISOString(),
  });
  await db.docSet('users', 'demo_artisan', {
    role: 'artisan',
    displayName: 'Artisan Démo',
    city: 'Casablanca',
    createdAt: new Date().toISOString(),
  });
  await db.docSet('artisanProfiles', 'demo_artisan', {
    userId: 'demo_artisan',
    displayName: 'Artisan Démo',
    bio: 'Plomberie & peinture — interventions rapides, devis clair.',
    categories: ['plumbing', 'painting'],
    serviceAreas: ['Casablanca', 'Mohammedia'],
    portfolio: [
      {
        id: 'pf_demo_1',
        type: 'before_after',
        beforeUrl: '',
        afterUrl: '',
        caption: 'Rénovation salle de bain — zellige & robinetterie',
        createdAt: new Date().toISOString(),
      },
    ],
    available: true,
    public: true,
    avgRating: 4.7,
    reviewCount: 18,
    avgResponseHours: 4,
    completedJobs90d: 12,
    reportedIssues: 0,
    updatedAt: new Date().toISOString(),
  });
  console.log('[al-asel] Demo seed loaded (demo_client / demo_artisan).');
}
