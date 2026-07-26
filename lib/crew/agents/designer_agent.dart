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
      final design = <String, dynamic>{
        'handSize': 5,
        'wordLength': 5,
        'startingBagSize': 60,
        'maxHandsPerLevel': 4,
        'maxDiscardsPerLevel': 2,
        'levelsBeforeBoss': 3,
        'baseTargetScore': 40,
        'targetScoreGrowth': 1.35,
        'shopJokerChoices': 3,
      };
      ctx.set('design', design);
      return 'Tasarım sabitlendi: el=${design['handSize']}, '
          'tur=${design['maxHandsPerLevel']}, baz hedef=${design['baseTargetScore']}';
    },
  );
}
