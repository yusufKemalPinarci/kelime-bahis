import 'turkish.dart';

class WordDictionary {
  WordDictionary(Iterable<String> words)
      : _words = {
          for (final w in words) normalizeTr(w),
        };

  final Set<String> _words;

  /// letter -> words containing only those multiset letters (preindexed lightly).
  final Map<String, List<String>> _bySignature = {};

  int get size => _words.length;

  bool contains(String word) => _words.contains(normalizeTr(word));

  void buildAnagramIndex() {
    _bySignature.clear();
    for (final w in _words) {
      final sig = _signature(w);
      (_bySignature[sig] ??= []).add(w);
    }
  }

  static String _signature(String word) {
    final chars = word.split('')..sort();
    return chars.join();
  }

  /// Finds one playable word using a multiset of hand letters (offline).
  String? findPlayableWord(
    Iterable<String> handLetters, {
    int minLength = 3,
    bool Function(String word)? validate,
  }) {
    final counts = <String, int>{};
    for (final raw in handLetters) {
      final l = normalizeTr(raw);
      counts[l] = (counts[l] ?? 0) + 1;
    }

    String? best;
    for (final w in _words) {
      if (w.length < minLength) continue;
      if (!_canSpell(w, counts)) continue;
      if (validate != null && !validate(w)) continue;
      if (best == null || w.length > best.length) {
        best = w;
      }
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
