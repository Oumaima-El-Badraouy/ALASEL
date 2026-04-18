/** Identifiants stables pour métiers d'art traditionnels marocains (filtrage, inscription). */
export const MOROCCAN_TRADE_IDS = [
  'zellige',
  'pottery',
  'leather',
  'dinanderie',
  'wood_traditional',
  'carpet_weaving',
  'textile_fouta',
  'henna',
  'plaster_gebs',
  'basketry',
  'embroidery',
  'calligraphy',
  'argan_cosmetics',
  'traditional_food',
  'jewelry_berber',
  'wrought_iron',
];

export function isValidMoroccanTrade(id) {
  return MOROCCAN_TRADE_IDS.includes(String(id || '').trim());
}
