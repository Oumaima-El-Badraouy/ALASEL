/// Métiers d'art traditionnels marocains — mêmes identifiants que l'API (`/posts`, inscription artisan).
class MoroccanTrade {
  const MoroccanTrade({required this.id, required this.labelAr});

  final String id;
  final String labelAr;
}

/// Liste unique utilisée pour listes déroulantes et filtres.
const List<MoroccanTrade> moroccanTrades = [
  MoroccanTrade(id: 'zellige', labelAr: 'الزليج والفسيفساء'),
  MoroccanTrade(id: 'pottery', labelAr: 'الفخار والخزف'),
  MoroccanTrade(id: 'leather', labelAr: 'الجلد والصناعة التقليدية للبوابيش'),
  MoroccanTrade(id: 'dinanderie', labelAr: 'الدندانة والنحاس والفضة'),
  MoroccanTrade(id: 'wood_traditional', labelAr: 'النجارة التقليدية والخشب المنقوش'),
  MoroccanTrade(id: 'carpet_weaving', labelAr: 'السجاد والبرود والزربية'),
  MoroccanTrade(id: 'textile_fouta', labelAr: 'النسيج والفوطة والحايك'),
  MoroccanTrade(id: 'henna', labelAr: 'الحناء والنقش'),
  MoroccanTrade(id: 'plaster_gebs', labelAr: 'الجص والجبس والأرابيسك'),
  MoroccanTrade(id: 'basketry', labelAr: 'الحصر والقفاف والتبوريدة'),
  MoroccanTrade(id: 'embroidery', labelAr: 'التطريز والصيفة والراندة'),
  MoroccanTrade(id: 'calligraphy', labelAr: 'الخط العربي والزخرفة'),
  MoroccanTrade(id: 'argan_cosmetics', labelAr: 'زيت الأرغان ومستحضرات طبيعية'),
  MoroccanTrade(id: 'traditional_food', labelAr: 'الحلويات والمطبخ التقليدي'),
  MoroccanTrade(id: 'jewelry_berber', labelAr: 'الحلي الأمازيغية والفضة'),
  MoroccanTrade(id: 'wrought_iron', labelAr: 'الحداد التقليدي والبوابات المطاوعة'),
];

List<String> get moroccanTradeIds => moroccanTrades.map((e) => e.id).toList();

MoroccanTrade? moroccanTradeById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final t in moroccanTrades) {
    if (t.id == id) return t;
  }
  return null;
}
