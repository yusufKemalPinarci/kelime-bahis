import '../agent.dart';
import '../context.dart';

Agent createBalanceAgent() {
  return Agent(
    role: 'Denge Mühendisi',
    goal:
        '[aşama balance] design.baseTargetScore’dan levelTargets üret; '
        'harf puanı ve joker çarpan üst sınırlarını dengele',
    backstory:
        'dictionary sonrası, content öncesi çalışır. Türkçe Scrabble’a yakın '
        'puanlar; LLM yok, tablolarla çalışır.',
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
      final base = (design['baseTargetScore'] as num?)?.toInt() ?? 40;
      final growth = (design['targetScoreGrowth'] as num?)?.toDouble() ?? 1.35;

      final targets = List<int>.generate(
        8,
        (i) => (base * _pow(growth, i)).round(),
      );

      final lengthMult = <String, double>{
        '2': 0.5,
        '3': 0.85,
        '4': 1.0,
        '5': 1.0,
        '6': 1.25,
        '7': 1.5,
        '8': 1.8,
      };

      ctx.set('letterPoints', letterPoints);
      ctx.set('levelTargets', targets);
      ctx.set('lengthMultipliers', lengthMult);
      ctx.set('longWordThreshold', 6);
      ctx.set('shortWordExactLength', 2);
      ctx.set('maxShortWordsPerLevel', 2);
      return 'Denge hazır: ${letterPoints.length} harf puanı, '
          'hedefler=$targets, uzunluk=$lengthMult';
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
