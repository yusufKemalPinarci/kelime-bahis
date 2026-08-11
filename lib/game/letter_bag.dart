import 'turkish.dart';

const Map<String, int> kLetterPoints = {
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

/// Mobil-dostu torba dağılımı: resmi Scrabble oranı (~%40 sesli) 8 harflik
/// tek elde kelime kurmayı zorlaştırıyordu. Sesli oranı ~%30'a çekildi,
/// yaygın sessizler (k/l/n/r/t/s) güçlendirildi.
const Map<String, int> kLetterBagCounts = {
  'a': 8,
  'b': 3,
  'c': 2,
  'ç': 2,
  'd': 5,
  'e': 8,
  'f': 1,
  'g': 2,
  'ğ': 1,
  'h': 2,
  'ı': 3,
  'i': 5,
  'j': 1,
  'k': 8,
  'l': 8,
  'm': 4,
  'n': 8,
  'o': 3,
  'ö': 1,
  'p': 1,
  'r': 7,
  's': 5,
  'ş': 2,
  't': 6,
  'u': 3,
  'ü': 2,
  'v': 1,
  'y': 3,
  'z': 2,
};

class LetterTile {
  LetterTile({required this.id, required this.letter});

  final String id;
  final String letter;

  int get points => kLetterPoints[letter] ?? 1;
}

class LetterBag {
  LetterBag(this._tiles);

  factory LetterBag.standard({int? seed}) {
    final tiles = <LetterTile>[];
    var i = 0;
    kLetterBagCounts.forEach((letter, count) {
      for (var c = 0; c < count; c++) {
        tiles.add(LetterTile(id: '${letter}_$i', letter: letter));
        i++;
      }
    });
    final bag = LetterBag(tiles);
    bag.shuffle(seed: seed);
    return bag;
  }

  final List<LetterTile> _tiles;
  final _rand = _SeededRandom();

  int get remaining => _tiles.length;

  void shuffle({int? seed}) {
    _rand.reseed(seed ?? DateTime.now().millisecondsSinceEpoch);
    for (var i = _tiles.length - 1; i > 0; i--) {
      final j = _rand.nextInt(i + 1);
      final tmp = _tiles[i];
      _tiles[i] = _tiles[j];
      _tiles[j] = tmp;
    }
  }

  List<LetterTile> draw(int count) {
    final n = count.clamp(0, _tiles.length);
    final drawn = _tiles.sublist(0, n);
    _tiles.removeRange(0, n);
    return drawn;
  }

  /// Belirli bir harfle eşleşen ilk taşı torbadan çıkarır (yoksa null).
  /// Kelime kurulabilirliği garantisi için el "ekilirken" kullanılır.
  LetterTile? drawLetter(String letter) {
    final n = normalizeTr(letter);
    final idx = _tiles.indexWhere((t) => normalizeTr(t.letter) == n);
    if (idx < 0) return null;
    return _tiles.removeAt(idx);
  }

  void returnTiles(Iterable<LetterTile> tiles) {
    _tiles.addAll(tiles);
    shuffle();
  }
}

class _SeededRandom {
  int _state = 1;

  void reseed(int seed) => _state = seed == 0 ? 1 : seed;

  int nextInt(int max) {
    _state = 1664525 * _state + 1013904223;
    return (_state & 0x7fffffff) % max;
  }
}

bool isVowel(String letter) => 'aeıioöuü'.contains(normalizeTr(letter));

bool isConsonant(String letter) {
  final n = normalizeTr(letter);
  return n.isNotEmpty && !isVowel(n) && kLetterPoints.containsKey(n);
}
