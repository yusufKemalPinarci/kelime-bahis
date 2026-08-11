import '../agent.dart';
import '../context.dart';

Agent createBalanceAgent() {
  return Agent(
    role: 'Denge Mühendisi',
    goal:
        '[aşama balance] design.baseTargetScore’dan levelTargets üret; '
        'boss×1.1 hedef; ekonomi bandı; harf puanı ve joker çarpan üst sınırları',
    backstory:
        'dictionary sonrası, content öncesi çalışır. Türkçe Scrabble’a yakın '
        'puanlar; LLM yok, tablolarla çalışır. Tur 8: skor cezası yok, hedef ×1.1.',
    execute: (CrewContext ctx) async {
      final letterPoints = <String, int>{
        'a': 1,
        'b': 3,
        'c': 4,
        'ç': 4,
        'd': 3,
        'e': 1,
        'f': 7,
        'g': 5,
        'ğ': 8,
        'h': 5,
        'ı': 2,
        'i': 1,
        'j': 10,
        'k': 1,
        'l': 1,
        'm': 2,
        'n': 1,
        'o': 2,
        'ö': 7,
        'p': 5,
        'r': 1,
        's': 2,
        'ş': 4,
        't': 1,
        'u': 2,
        'ü': 3,
        'v': 7,
        'y': 3,
        'z': 4,
      };

      final design = ctx.get<Map<String, dynamic>>('design') ?? {};
      final base = (design['baseTargetScore'] as num?)?.toInt() ?? 32;
      final growth = (design['targetScoreGrowth'] as num?)?.toDouble() ?? 1.22;
      final bossMult =
          (design['bossTargetMultiplier'] as num?)?.toDouble() ?? 1.1;
      final levelsBeforeBoss =
          (design['levelsBeforeBoss'] as num?)?.toInt() ?? 3;
      final bossPeriod = levelsBeforeBoss + 1; // L4, L8, …
      final startingGold = (design['startingGold'] as num?)?.toInt() ?? 5;
      final shopRerollCost = (design['shopRerollCost'] as num?)?.toInt() ?? 1;
      final jokerCostMin = (design['jokerCostMin'] as num?)?.toInt() ?? 3;
      final jokerCostMax = (design['jokerCostMax'] as num?)?.toInt() ?? 6;

      // Baz eğri (boss çarpanı olmadan) — soft; L3→L4 uçurumu yok.
      final baseTargets = List<int>.generate(
        8,
        (i) => (base * _pow(growth, i)).round(),
      );

      // Efektif hedefler: boss seviyelerinde × bossMult (skor formülü değil).
      final targets = <int>[];
      final bossLevels = <int>[];
      for (var i = 0; i < 8; i++) {
        final level = i + 1;
        final isBoss = level % bossPeriod == 0;
        if (isBoss) bossLevels.add(level);
        targets.add(
          isBoss ? (baseTargets[i] * bossMult).round() : baseTargets[i],
        );
      }

      final lengthMult = <String, double>{
        '2': 0.5,
        '3': 0.85,
        '4': 1.0,
        '5': 1.0,
        '6': 1.25,
        '7': 1.5,
        '8': 1.8,
      };

      // Joker çarpan üst sınırı — Content şişirmesin.
      const jokerMultCap = 2.0;
      const jokerFlatBonusCap = 12;

      ctx.set('letterPoints', letterPoints);
      ctx.set('levelTargets', targets);
      ctx.set('levelTargetsBase', baseTargets);
      ctx.set('bossLevels', bossLevels);
      ctx.set('bossTargetMultiplier', bossMult);
      ctx.set('bossScorePenaltyPct', 0);
      ctx.set('levelsBeforeBoss', levelsBeforeBoss);
      ctx.set('lengthMultipliers', lengthMult);
      ctx.set('longWordThreshold', 6);
      ctx.set('shortWordExactLength', 3);
      ctx.set('maxShortWordsPerLevel', 2);
      ctx.set('startingGold', startingGold);
      ctx.set('shopRerollCost', shopRerollCost);
      ctx.set('jokerCostMin', jokerCostMin);
      ctx.set('jokerCostMax', jokerCostMax);
      ctx.set('jokerMultCap', jokerMultCap);
      ctx.set('jokerFlatBonusCap', jokerFlatBonusCap);
      ctx.set('balanceNotes', <String, dynamic>{
        'boss':
            'Boss seviyelerinde hedef ×$bossMult; skor cezası yok. '
            'Boss: her $bossPeriod. seviye (L${bossLevels.join(", L")}).',
        'economy':
            'startingGold=$startingGold, reroll=$shopRerollCost, '
            'joker cost $jokerCostMin–$jokerCostMax. '
            'İlk mağaza: ucuz (3)+reroll veya orta (4–5).',
        'curve':
            'base=$base growth=$growth; baz=$baseTargets; efektif=$targets',
      });
      return 'Denge hazır (Tur8): hedefler=$targets (boss L$bossLevels ×$bossMult), '
          'altın=$startingGold, cost=$jokerCostMin–$jokerCostMax';
    },
  );
}

double _pow(double base, int exp) {
  var r = 1.0;
  for (var i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}
