import 'dart:math';

import 'turkish.dart';
import 'word_length.dart';

class WordDictionary {
  WordDictionary(Iterable<String> words)
      : _words = {
          for (final w in words)
            if (isValidWordLength(normalizeTr(w).length)) normalizeTr(w),
        };

  final Set<String> _words;

  /// signature -> words (anagram index).
  final Map<String, List<String>> _bySignature = {};

  /// length -> words (hint hızlandırma).
  final Map<int, List<String>> _byLength = {};

  int get size => _words.length;

  bool contains(String word) {
    final n = normalizeTr(word);
    if (!isValidWordLength(n.length)) return false;
    return _words.contains(n);
  }

  void buildAnagramIndex() {
    _bySignature.clear();
    _byLength.clear();
    for (final w in _words) {
      final sig = _signature(w);
      (_bySignature[sig] ??= []).add(w);
      (_byLength[w.length] ??= []).add(w);
    }
  }

  static String _signature(String word) {
    final chars = word.split('')..sort();
    return chars.join();
  }

  /// Elden 3–8 harfli oynanabilir kelime bulur; uzun/çeşitli tercih edilir.
  String? findPlayableWord(
    Iterable<String> handLetters, {
    bool Function(String word)? validate,
  }) {
    final counts = <String, int>{};
    for (final raw in handLetters) {
      final l = normalizeTr(raw);
      counts[l] = (counts[l] ?? 0) + 1;
    }
    final handSize = counts.values.fold<int>(0, (a, b) => a + b);

    // Uzunluktan başlayarak dene (ipucu: uzun kelime tercih).
    final lengths = <int>[
      for (var L = handSize.clamp(kMinWordLength, kMaxWordLength);
          L >= kMinWordLength;
          L--)
        L,
    ];

    String? best;
    var bestScore = -1;

    Iterable<String> candidatesFor(int len) {
      if (_byLength.isNotEmpty) {
        return _byLength[len] ?? const [];
      }
      return _words.where((w) => w.length == len);
    }

    for (final len in lengths) {
      for (final w in candidatesFor(len)) {
        if (!_canSpell(w, counts)) continue;
        if (validate != null && !validate(w)) continue;
        final score = w.length * 10 + w.split('').toSet().length;
        if (best == null || score > bestScore) {
          best = w;
          bestScore = score;
        }
      }
      // Uzun bir kelime bulunduysa daha kısa aramaya gerek yok (ipucu kalitesi).
      if (best != null && best.length == len) break;
    }
    return best;
  }

  /// [findPlayableWord]'ün hedef uzunluğu önceden bilinen sürümü — çok
  /// uzunluklu azalan taramayı atlayıp doğrudan `_byLength[length]`'i
  /// tarar. `_ensureSolvable`/`useSoftHint` gibi çağıranlar zaten
  /// `w.length == length` şartını `validate`'e koyduğu için davranış
  /// aynıdır, yalnızca gereksiz uzun-uzunluk taramaları elenir (bkz.
  /// GameController._ensureSolvable dokümantasyonu).
  String? findPlayableWordOfLength(
    int length,
    Iterable<String> handLetters, {
    bool Function(String word)? validate,
  }) {
    final counts = <String, int>{};
    for (final raw in handLetters) {
      final l = normalizeTr(raw);
      counts[l] = (counts[l] ?? 0) + 1;
    }

    String? best;
    var bestScore = -1;
    for (final w in _byLength[length] ?? const <String>[]) {
      if (!_canSpell(w, counts)) continue;
      if (validate != null && !validate(w)) continue;
      final score = w.split('').toSet().length;
      if (best == null || score > bestScore) {
        best = w;
        bestScore = score;
      }
    }
    return best;
  }

  /// Verilen uzunlukta, [validate] koşulunu sağlayan bir kelime var mı?
  bool hasWordOfLength(int length, {bool Function(String word)? validate}) {
    final candidates = _byLength[length] ?? const <String>[];
    if (validate == null) return candidates.isNotEmpty;
    return candidates.any(validate);
  }

  /// Verilen uzunlukta, [validate] koşulunu sağlayan kelimeler arasından
  /// [rng] ile rastgele biri seçilir. Torba/el bu kelimenin harfleriyle
  /// "ekilerek" kelime kurulabilirliği garanti edilir (bkz. GameController).
  String? pickRandomWordOfLength(
    int length, {
    bool Function(String word)? validate,
    required Random rng,
  }) {
    final pool = validate == null
        ? (_byLength[length] ?? const <String>[])
        : (_byLength[length] ?? const <String>[]).where(validate).toList();
    if (pool.isEmpty) return null;
    return pool.elementAt(rng.nextInt(pool.length));
  }

  /// [pickRandomWordOfLength]'ün serbest-uzunluk sürümü — [exactLength]
  /// verilmezse 2..8 arası tüm uzunluklardan [validate]'i sağlayan kelimeler
  /// havuzlanır ve [rng] ile biri seçilir. Adventure görevlerinde (sabit
  /// uzunluk şartı olmayan) "el her zaman çözülebilir" garantisini beslemek
  /// için kullanılır (bkz. GameController._ensureSolvableAdventure).
  String? pickRandomWordMatching({
    required bool Function(String word) validate,
    required Random rng,
    int? exactLength,
  }) {
    if (exactLength != null) {
      return pickRandomWordOfLength(exactLength, validate: validate, rng: rng);
    }
    final pool = <String>[];
    for (var len = kMinWordLength; len <= kMaxWordLength; len++) {
      pool.addAll((_byLength[len] ?? const <String>[]).where(validate));
    }
    if (pool.isEmpty) return null;
    return pool.elementAt(rng.nextInt(pool.length));
  }

  bool _canSpell(String word, Map<String, int> hand) {
    final need = <String, int>{};
    for (final ch in word.split('')) {
      need[ch] = (need[ch] ?? 0) + 1;
      if ((hand[ch] ?? 0) < need[ch]!) return false;
    }
    return true;
  }
}
