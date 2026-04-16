import { estimatePrice } from '../services/priceEstimator.service.js';

export async function getEstimate(req, res) {
  try {
    const { category, sqm, urgency } = req.query;
    const result = estimatePrice({
      category,
      sqm: sqm ? parseFloat(sqm) : 0,
      urgency,
    });
    return res.json(result);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}
