import 'dart:io';

import '../agent.dart';
import '../context.dart';

Agent createDictionaryAgent() {
  return Agent(
    role: 'Sözlük Uzmanı',
    goal: 'Türkçe kelime listesini doğrula ve oyun için filtrele',
    backstory:
        'Offline sözlük bakımı yapar. En az 3 harfli, yalnızca Türkçe harf '
        'içeren kelimeleri kabul eder. Harici API yok.',
    execute: (CrewContext ctx) async {
      final path = ctx.get<String>('dictionaryPath') ??
          'assets/dictionary/tr_words.txt';
      final file = File(path);
      if (!file.existsSync()) {
        ctx.set('wordCount', 0);
        ctx.set('wordsSample', <String>[]);
        return 'Sözlük bulunamadı: $path';
      }

      final raw = await file.readAsLines();
      final words = raw
          .map((w) => w.trim().toLocaleLowerCaseTr())
          .where((w) => w.length >= 3)
          .where(_isTurkishWord)
          .toSet()
          .toList()
        ..sort();

      ctx.set('wordCount', words.length);
      ctx.set('wordsSample', words.take(12).toList());
      return 'Sözlük hazır: ${words.length} kelime (min 3 harf, TR harfler)';
    },
  );
}

bool _isTurkishWord(String word) {
  const allowed = 'abcçdefgğhıijklmnoöprsştuüvyz';
  for (final rune in word.runes) {
    final ch = String.fromCharCode(rune);
    if (!allowed.contains(ch)) return false;
  }
  return true;
}

extension on String {
  String toLocaleLowerCaseTr() {
    return replaceAll('I', 'ı')
        .replaceAll('İ', 'i')
        .toLowerCase()
        .replaceAll('i̇', 'i');
  }
}
