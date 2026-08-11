String normalizeTr(String input) {
  return input
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('i̇', 'i')
      .trim();
}

/// Türkçe büyük harf: i→İ, ı→I (Dart `toUpperCase` ikisini de I yapar).
String toUpperTr(String input) {
  final buf = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == 'i') {
      buf.write('İ');
    } else if (ch == 'ı') {
      buf.write('I');
    } else {
      buf.write(ch.toUpperCase());
    }
  }
  return buf.toString();
}
