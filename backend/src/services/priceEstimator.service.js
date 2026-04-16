/** Approximate price bands in MAD for MVP rules engine */
const BASE_RANGES = {
  plumbing: { min: 150, max: 1200, unit: 'visit' },
  painting: { min: 800, max: 8000, unit: 'room', perSqm: { min: 25, max: 65 } },
  carpentry: { min: 400, max: 6000, unit: 'project' },
  electricity: { min: 200, max: 2500, unit: 'visit' },
  tiling: { min: 1200, max: 15000, unit: 'room', perSqm: { min: 80, max: 220 } },
  hvac: { min: 500, max: 9000, unit: 'system' },
  general: { min: 200, max: 3000, unit: 'job' },
};

export function estimatePrice({ category, sqm, urgency }) {
  const key = (category || 'general').toLowerCase();
  const band = BASE_RANGES[key] || BASE_RANGES.general;
  let min = band.min;
  let max = band.max;

  if (band.perSqm && sqm > 0) {
    min = Math.round(band.perSqm.min * sqm);
    max = Math.round(band.perSqm.max * sqm);
  }

  if (urgency === 'urgent') {
    min = Math.round(min * 1.15);
    max = Math.round(max * 1.25);
  }

  return {
    currency: 'MAD',
    min,
    max,
    basis: band.unit,
    disclaimer:
      'Estimation indicative — final quote after artisan visit. AL ASEL ne garantit pas le prix final.',
  };
}
