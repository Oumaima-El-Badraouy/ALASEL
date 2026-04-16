import { computeTrustScore } from './trustScore.service.js';

/**
 * Rank artisans for a client request.
 * @param {object} request — { category, city?, urgency? }
 * @param {Array<object>} artisans — artisan profile docs with stats
 */
export function rankArtisans(request, artisans) {
  const cat = request.category;
  const city = (request.city || '').toLowerCase();

  return artisans
    .map((a) => {
      const cats = a.categories || [];
      const catMatch = cats.includes(cat) ? 1 : cats.length ? 0.3 : 0.5;
      const cityMatch =
        !city || !a.serviceAreas?.length
          ? 0.7
          : a.serviceAreas.some((c) => c.toLowerCase() === city)
            ? 1
            : 0.4;
      const trust = computeTrustScore({
        avgRating: a.avgRating,
        reviewCount: a.reviewCount,
        avgResponseHours: a.avgResponseHours,
        completedJobs90d: a.completedJobs90d,
        reportedIssues: a.reportedIssues,
      });
      const availability = a.available !== false ? 1 : 0.35;
      const matchScore =
        catMatch * 0.38 + cityMatch * 0.22 + (trust / 100) * 0.28 + availability * 0.12;

      return {
        artisanId: a.id,
        displayName: a.displayName,
        matchScore: Math.round(matchScore * 1000) / 1000,
        trustScore: trust,
        reasons: {
          categoryFit: catMatch >= 0.9 ? 'strong' : 'partial',
          location: cityMatch >= 0.9 ? 'in_area' : 'outside_or_unknown',
          availability: a.available !== false ? 'open' : 'limited',
        },
      };
    })
    .sort((x, y) => y.matchScore - x.matchScore);
}
