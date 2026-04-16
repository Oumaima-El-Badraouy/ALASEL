/**
 * Trust Score 0–100 — deterministic "AI-like" composite from signals.
 * @param {{
 *   avgRating?: number,
 *   reviewCount?: number,
 *   avgResponseHours?: number,
 *   completedJobs90d?: number,
 *   reportedIssues?: number
 * }} input
 */
export function computeTrustScore(input = {}) {
  const avgRating = Math.min(5, Math.max(0, Number(input.avgRating) || 0));
  const reviewCount = Math.max(0, Number(input.reviewCount) || 0);
  const avgResponseHours = Number(input.avgResponseHours);
  const completedJobs90d = Math.max(0, Number(input.completedJobs90d) || 0);
  const reportedIssues = Math.max(0, Number(input.reportedIssues) || 0);

  let score = 45;
  score += (avgRating / 5) * 35;
  score += Math.min(reviewCount * 1.5, 18);
  if (Number.isFinite(avgResponseHours)) {
    if (avgResponseHours <= 2) score += 12;
    else if (avgResponseHours <= 12) score += 8;
    else if (avgResponseHours <= 48) score += 4;
  }
  score += Math.min(completedJobs90d * 2, 12);
  score -= Math.min(reportedIssues * 8, 24);

  return Math.round(Math.min(100, Math.max(0, score)));
}
