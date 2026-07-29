import 'dart:io';

import '../agent.dart';
import '../context.dart';

Agent createDictionaryAgent() {
  return Agent(
    role: 'Sözlük Uzmanı',
    goal:
        '[aşama dictionary] tr_words.txt’yi filtrele: 2–8 harf, yalnızca '
        'Türkçe harf; offline WordDictionary ile uyumlu tut',
    backstory:
        'design sonrası, balance öncesi çalışır. Offline sözlük bakımı; '
        'harici API yok. Oyun 2–8 harfli Türkçe kelime kabul eder.',
    execute: (CrewContext ctx) async {
      final path = ctx.get<String>('dictionaryPath') ??
          'assets/dictionary/tr_words.txt';
      final file = File(path);
      if (!file.existsSync()) {
        ctx.set('wordCount', 0);
        ctx.set('wordsSample', <String>[]);
        return 'Sözlük bulunamadı: $path';
      }

      final design = ctx.get<Map<String, dynamic>>('design') ?? {};
      final minLen = (design['minWordLength'] as num?)?.toInt() ?? 2;
      final maxLen = (design['maxWordLength'] as num?)?.toInt() ?? 8;

      final raw = await file.readAsLines();
      final words = raw
          .map((w) => w.trim().toLocaleLowerCaseTr())
          .where((w) => w.length >= minLen && w.length <= maxLen)
          .where(_isTurkishWord)
          .toSet()
          .toList()
        ..sort();

      ctx.set('wordCount', words.length);
      ctx.set('wordsSample', words.take(12).toList());
      ctx.set('minWordLength', minLen);
      ctx.set('maxWordLength', maxLen);
      return 'Sözlük hazır: ${words.length} kelime ($minLen–$maxLen harf, TR)';
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
