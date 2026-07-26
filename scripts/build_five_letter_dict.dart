import 'dart:io';

/// Build-time: TDK tarzı listeden yalnızca 5 harfli TR kelimeleri çıkarır.
/// Kullanım: dart run scripts/build_five_letter_dict.dart <kaynak.txt>
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Kullanım: dart run scripts/build_five_letter_dict.dart <kaynak.txt>');
    exit(64);
  }

  const allowed = 'abcçdefgğhıijklmnoöprsştuüvyz';
  final src = File(args.first);
  if (!src.existsSync()) {
    stderr.writeln('Kaynak yok: ${src.path}');
    exit(66);
  }

  final words = <String>{};
  for (final raw in await src.readAsLines()) {
    var w = raw.trim();
    if (w.startsWith('"') && w.endsWith('"') && w.length >= 2) {
      w = w.substring(1, w.length - 1);
    }
    w = _normalizeTr(w);
    if (w.length != 5) continue;
    if (!_onlyTurkish(w, allowed)) continue;
    words.add(w);
  }

  final sorted = words.toList()..sort();
  final out = File('assets/dictionary/tr_words.txt');
  await out.writeAsString('${sorted.join('\n')}\n');
  stdout.writeln('Yazıldı: ${out.path} (${sorted.length} kelime, 5 harf)');
}

String _normalizeTr(String input) {
  return input
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('i̇', 'i')
      .trim();
}

bool _onlyTurkish(String word, String allowed) {
  for (final rune in word.runes) {
    if (!allowed.contains(String.fromCharCode(rune))) return false;
  }
  return true;
}
