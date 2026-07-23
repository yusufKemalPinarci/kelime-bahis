import '../agent.dart';
import '../context.dart';

Agent createDesignerAgent() {
  return Agent(
    role: 'Oyun Tasarımcısı',
    goal: 'Seviye hedefleri, el boyutu ve tur ekonomisini tanımla',
    backstory:
        'Wordlike/Balatro tarzı offline kelime-roguelike için sistem tasarlar. '
        'API kullanmaz; sabit kurallar ve sezgisel dengelerle çalışır.',
    execute: (CrewContext ctx) async {
      final design = <String, dynamic>{
        'handSize': 8,
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
