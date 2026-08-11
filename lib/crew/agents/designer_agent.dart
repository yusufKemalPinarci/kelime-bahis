import '../agent.dart';
import '../context.dart';

Agent createDesignerAgent() {
  return Agent(
    role: 'Oyun Tasarımcısı',
    goal:
        '[aşama design] El boyutu, tur/atım hakkı, seviye ritmi ve mağaza seçim '
        'sayısını sabitle; UX’te tek hedef / tek CTA koru',
    backstory:
        'Wordlike/Balatro tarzı offline kelime-roguelike için sistem tasarlar. '
        'Pipeline’da dictionary’den önce çalışır. API yok; sabit kurallar.',
    execute: (CrewContext ctx) async {
      // Tur 8 onaylı id: boss_score_pressure, economy_fine_tune, joker_boss_dialog
      final design = <String, dynamic>{
        'handSize': 8,
        'minWordLength': 3,
        'maxWordLength': 8,
        'startingBagSize': 112,
        'maxHandsPerLevel': 4,
        'maxDiscardsPerLevel': 2,
        'levelsBeforeBoss': 3,
        'baseTargetScore': 32,
        'targetScoreGrowth': 1.22,
        'shopJokerChoices': 3,
        'maxJokerSlots': 5,
        'maxShortWordsPerLevel': 2,

        // --- Tur 8: economy_fine_tune ---
        'startingGold': 5,
        'shopRerollCost': 1,
        'jokerCostMin': 3,
        'jokerCostMax': 6,
        'economyNotes':
            'Başlangıç 4→5: ilk mağazada ucuz joker (3) + reroll (1) veya orta '
            'fiyat (4–5) alınabilsin; reroll 1 kalsın. Content/Balance joker '
            'cost bandını 3–6’da tutsun; pay-to-win yok.',

        // --- Tur 8: boss_score_pressure ---
        // Karar: skoru çarpmak yerine hedefi yükselt (HUD okunaklı, skor formülü temiz).
        'bossScorePenaltyPct': 0,
        'bossTargetMultiplier': 1.1,
        'bossPressureHudRule':
            'Boss seviyesinde tek satır: «Boss · hedef +10%» (veya ×1.1). '
            'Ana CTA «Oyna/Gönder» kalır; baskı chip’i ikincil, skor flash’ı bozmaz. '
            'Tek hedef = yükseltilmiş target; ikinci skor metrik gösterme.',

        // --- Tur 8: joker_boss_dialog ---
        'bossDialogEnabled': true,
        'bossDialogTrigger': 'shop_before_boss',
        'bossDialogUx':
            'Mağazada upcomingBossPreview varken tek diyalog: jokerlerin '
            'boss kısıtıyla çakışma uyarısı + «Devam». Birincil CTA yine mağaza '
            'alışverişi; diyalog modal, ses/Android yok.',
      };
      ctx.set('design', design);
      return 'Tasarım sabitlendi (Tur8): el=${design['handSize']}, '
          'altın=${design['startingGold']}, boss×${design['bossTargetMultiplier']}, '
          'dialog=${design['bossDialogEnabled']}';
    },
  );
}
