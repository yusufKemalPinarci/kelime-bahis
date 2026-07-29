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

  /// Elden 2–8 harfli oynanabilir kelime bulur; uzun/çeşitli tercih edilir.
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

  bool _canSpell(String word, Map<String, int> hand) {
    final need = <String, int>{};
    for (final ch in word.split('')) {
      need[ch] = (need[ch] ?? 0) + 1;
      if ((hand[ch] ?? 0) < need[ch]!) return false;
    }
    return true;
  }
}
