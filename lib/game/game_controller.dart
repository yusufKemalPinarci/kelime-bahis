import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'adventure_levels.dart';
import 'letter_bag.dart';
import 'local_stats.dart';
import 'scoring.dart';
import 'turkish.dart';
import 'word_dictionary.dart';
import 'word_length.dart';

enum RunPhase { playing, adventureComplete }

enum RunMode { classic, adventure }

/// Kaç doğru kelimede bir yeni "pas hakkı" (limitsiz olmayan el yenileme)
/// kazanılır.
const int kWordsPerPass = 10;

class GameController extends ChangeNotifier {
  WordDictionary? dictionary;
  LocalStats stats = LocalStats();

  late LetterBag bag;
  final List<LetterTile> hand = [];
  final List<LetterTile> selected = [];

  /// Adventure seviyesinde tekrar oynanan kelimeleri engellemek için kullanılır.
  final Set<String> playedThisLevel = {};

  RunMode mode = RunMode.classic;
  RunPhase phase = RunPhase.playing;

  // Classic
  int classicScore = 0;

  // Adventure
  int adventureLevelNumber = 1;
  AdventureLevelDef? adventureTask;
  int adventureAttemptsLeft = 0;
  int adventureProgress = 0;

  int comboStreak = 0;

  /// Elini yenilemek için kullanılabilecek pas hakkı — her [kWordsPerPass]
  /// doğru kelimede bir kazanılır (bkz. [playWord]).
  int passesAvailable = 0;
  int _wordsTowardNextPass = 0;

  String message = '';
  ScoreBreakdown? lastScore;
  bool ready = false;

  /// Bootstrap sırasında ölümcül hata (sözlük yüklenemedi vb.); UI hata ekranı
  /// gösterir ve tekrar denemeye izin verir.
  String? bootstrapError;

  int get maxSelectable {
    final exact = mode == RunMode.adventure ? adventureTask?.exactLength : null;
    return exact ?? kMaxWordLength;
  }

  int get adventureTarget => adventureTask?.target ?? 0;

  double get adventureProgressRatio {
    final target = adventureTarget;
    if (target <= 0) return 0;
    return (adventureProgress / target).clamp(0.0, 1.0);
  }

  Future<void> bootstrap() async {
    bootstrapError = null;
    stats = await LocalStats.load();

    try {
      final wordsRaw =
          await rootBundle.loadString('assets/dictionary/tr_words.txt');
      final words = wordsRaw
          .split(RegExp(r'\r?\n'))
          .map((w) => w.trim())
          .where((w) => w.isNotEmpty)
          .where((w) {
            final n = normalizeTr(w);
            return isValidWordLength(n.length);
          });
      dictionary = WordDictionary(words);
      dictionary!.buildAnagramIndex();
    } catch (e) {
      // Sözlük olmadan oyun oynanamaz — hata ekranı gösterilir.
      bootstrapError = 'Sözlük yüklenemedi: $e';
      notifyListeners();
      return;
    }

    ready = true;
    notifyListeners();
  }

  int _freshSeed() => DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  void startClassic() {
    mode = RunMode.classic;
    bag = LetterBag.standard(seed: _freshSeed());
    hand.clear();
    selected.clear();
    playedThisLevel.clear();
    classicScore = 0;
    comboStreak = 0;
    passesAvailable = 0;
    _wordsTowardNextPass = 0;
    lastScore = null;
    message = '';
    phase = RunPhase.playing;
    _refillHand();
    notifyListeners();
  }

  void startAdventureLevel(int levelNumber) {
    if (dictionary == null) return;
    final n = levelNumber.clamp(1, kAdventureLevelCount);
    if (n > stats.adventureHighestCleared + 1) return; // kilitli
    mode = RunMode.adventure;
    adventureLevelNumber = n;
    adventureTask = adventureLevel(n);
    // Pas hakkı, harita'dan taze girişte sıfırlanır; seviye içi başarısız
    // deneme sonrası tekrar başlamada (_resetAdventureAttempt) korunur —
    // oyuncunun bildiği kelimeler bir hamle hatasıyla "unutulmasın".
    passesAvailable = 0;
    _wordsTowardNextPass = 0;
    _resetAdventureAttempt();
    message = '';
    phase = RunPhase.playing;
    notifyListeners();
  }

  void _resetAdventureAttempt() {
    final task = adventureTask;
    if (task == null) return;
    bag = LetterBag.standard(seed: _freshSeed());
    hand.clear();
    selected.clear();
    playedThisLevel.clear();
    adventureAttemptsLeft = task.attempts;
    adventureProgress = 0;
    comboStreak = 0;
    lastScore = null;
    phase = RunPhase.playing;
    _refillHand();
  }

  /// Tamamlanan seviyeden sonraki seviyeye geçer (100'ü aştıysa no-op).
  void advanceToNextAdventureLevel() {
    if (phase != RunPhase.adventureComplete) return;
    final next = adventureLevelNumber + 1;
    if (next > kAdventureLevelCount) return;
    startAdventureLevel(next);
  }

  void _refillHand() {
    final need = kHandSize - hand.length;
    if (need > 0) {
      hand.addAll(bag.draw(need));
    }
    _ensureSolvable();
  }

  /// Eldeki harflerle bu modun/görevin gerektirdiği bir kelime kurulamıyorsa,
  /// sözlükten uygun bir kelime seçip elin içine "eker" — oyuncuya asla
  /// kelimesiz bir el gösterilmez.
  void _ensureSolvable() {
    if (dictionary == null) return;

    bool valid(String w) {
      if (mode == RunMode.classic) return true;
      final task = adventureTask;
      if (task == null) return false;
      return !playedThisLevel.contains(w) && task.accepts(w);
    }

    final exactLength =
        mode == RunMode.adventure ? adventureTask?.exactLength : null;

    final solvable = exactLength != null
        ? dictionary!.findPlayableWordOfLength(
              exactLength,
              hand.map((t) => t.letter),
              validate: valid,
            ) !=
            null
        : dictionary!.findPlayableWord(
              hand.map((t) => t.letter),
              validate: valid,
            ) !=
            null;
    if (solvable) return;

    final rng = Random(
      (_freshSeed() + hand.length * 7) & 0x7fffffff,
    );
    final word = dictionary!.pickRandomWordMatching(
      validate: valid,
      rng: rng,
      exactLength: exactLength,
    );
    if (word == null) return; // sözlükte uygun kelime yok

    bag.returnTiles(hand);
    hand.clear();
    var synth = 0;
    for (final ch in word.split('')) {
      final tile = bag.drawLetter(ch) ??
          LetterTile(id: '${ch}_g${synth++}', letter: ch);
      hand.add(tile);
    }
    final fillerNeeded = kHandSize - hand.length;
    if (fillerNeeded > 0) {
      hand.addAll(bag.draw(fillerNeeded));
    }
  }

  void toggleSelect(LetterTile tile) {
    if (phase != RunPhase.playing) return;
    if (selected.contains(tile)) {
      selected.remove(tile);
    } else if (selected.length < maxSelectable) {
      selected.add(tile);
    } else {
      message = 'En fazla $maxSelectable harf seçebilirsin.';
    }
    notifyListeners();
  }

  void clearSelection() {
    if (phase != RunPhase.playing) return;
    selected.clear();
    notifyListeners();
  }

  void moveSelected(int fromIndex, int toIndex) {
    if (phase != RunPhase.playing) return;
    if (fromIndex < 0 ||
        fromIndex >= selected.length ||
        toIndex < 0 ||
        toIndex >= selected.length ||
        fromIndex == toIndex) {
      return;
    }
    final tile = selected.removeAt(fromIndex);
    selected.insert(toIndex, tile);
    notifyListeners();
  }

  void nudgeSelectedLeft(int index) {
    if (index <= 0) return;
    moveSelected(index, index - 1);
  }

  void nudgeSelectedRight(int index) {
    if (index < 0 || index >= selected.length - 1) return;
    moveSelected(index, index + 1);
  }

  String get selectedWord => selected.map((t) => t.letter).join();

  /// Eldeki taşlardan [word]'ü kuracak taşları seçer (varsa). Elde
  /// kurulamıyorsa seçim değişmez ve false döner.
  bool selectWordFromHand(String word) {
    if (phase != RunPhase.playing) return false;
    final target = normalizeTr(word);
    final available = List<LetterTile>.from(hand);
    final picked = <LetterTile>[];
    for (final ch in target.split('')) {
      final idx = available.indexWhere((t) => normalizeTr(t.letter) == ch);
      if (idx < 0) return false;
      picked.add(available.removeAt(idx));
    }
    selected
      ..clear()
      ..addAll(picked);
    notifyListeners();
    return true;
  }

  /// Anlık skor önizlemesi — UI'da "OYNA · +N" için kullanılır.
  ScoreBreakdown? get livePreviewBreakdown {
    if (dictionary == null || selected.length < kMinWordLength) return null;
    final word = normalizeTr(selectedWord);
    if (!dictionary!.contains(word)) return null;
    if (mode == RunMode.adventure) {
      if (playedThisLevel.contains(word)) return null;
      if (adventureTask != null && !adventureTask!.accepts(word)) return null;
    }
    return scoreWord(word: word);
  }

  int? get livePreviewScore => livePreviewBreakdown?.total;

  /// Elin tamamını yeniler — her [kWordsPerPass] doğru kelimede kazanılan
  /// bir "pas hakkı" harcar. Seriyi sıfırlar (küçük bir maliyet).
  void refreshHand() {
    if (phase != RunPhase.playing) return;
    if (passesAvailable <= 0) {
      message = 'Pas hakkın yok — $kWordsPerPass kelime bilince bir tane kazanırsın.';
      notifyListeners();
      return;
    }
    passesAvailable -= 1;
    bag.returnTiles(hand);
    hand.clear();
    selected.clear();
    comboStreak = 0;
    _refillHand();
    message = 'Yeni harfler geldi.';
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  String _adventureRejectReason(AdventureLevelDef t) {
    if (t.exactLength != null) return 'Tam ${t.exactLength} harfli olmalı.';
    if (t.minLength != null) return 'En az ${t.minLength} harfli olmalı.';
    if (t.minVowels != null) {
      return 'En az ${t.minVowels} sesli harf içermeli.';
    }
    if (t.minConsonants != null) {
      return 'En az ${t.minConsonants} sessiz harf içermeli.';
    }
    if (t.noRepeat) return 'Harfler tekrar etmemeli.';
    if (t.startsVowel) return 'Sesli harfle başlamalı.';
    if (t.requiredLetter != null) {
      return "'${toUpperTr(t.requiredLetter!)}' harfini içermeli.";
    }
    return 'Bu görevin kuralına uymuyor.';
  }

  void playWord() {
    if (phase != RunPhase.playing || dictionary == null) return;
    if (selected.isEmpty) {
      message = 'Harf seç.';
      HapticFeedback.selectionClick();
      notifyListeners();
      return;
    }

    final word = normalizeTr(selectedWord);
    if (word.length < kMinWordLength) {
      message = 'En az $kMinWordLength harf gerekli.';
      selected.clear();
      HapticFeedback.heavyImpact();
      notifyListeners();
      return;
    }
    if (!dictionary!.contains(word)) {
      message = 'Sözlükte yok';
      selected.clear();
      HapticFeedback.heavyImpact();
      notifyListeners();
      return;
    }

    AdventureLevelDef? task;
    if (mode == RunMode.adventure) {
      task = adventureTask;
      if (task == null) return;
      if (playedThisLevel.contains(word)) {
        message = '"$word" bu seviyede zaten oynandı.';
        selected.clear();
        HapticFeedback.heavyImpact();
        notifyListeners();
        return;
      }
      if (!task.accepts(word)) {
        message = _adventureRejectReason(task);
        selected.clear();
        HapticFeedback.heavyImpact();
        notifyListeners();
        return;
      }
    }

    comboStreak += 1;
    final breakdown = scoreWord(word: word, comboStreak: comboStreak);
    lastScore = breakdown;
    HapticFeedback.lightImpact();

    for (final t in List<LetterTile>.from(selected)) {
      hand.remove(t);
    }
    selected.clear();
    _refillHand();

    var earnedPass = false;
    _wordsTowardNextPass += 1;
    if (_wordsTowardNextPass >= kWordsPerPass) {
      _wordsTowardNextPass -= kWordsPerPass;
      passesAvailable += 1;
      earnedPass = true;
    }

    if (mode == RunMode.classic) {
      classicScore += breakdown.total;
      final beatRecord = stats.noteClassicScore(classicScore);
      if (beatRecord) stats.save();
      message = '+${breakdown.total} · $classicScore puan';
    } else {
      playedThisLevel.add(word);
      adventureProgress += task!.scoreBased ? breakdown.total : 1;
      adventureAttemptsLeft -= 1;

      if (adventureProgress >= task.target) {
        phase = RunPhase.adventureComplete;
        stats.noteAdventureLevelCleared(adventureLevelNumber);
        stats.save();
        message = 'Seviye tamamlandı!';
        HapticFeedback.mediumImpact();
      } else if (adventureAttemptsLeft <= 0) {
        message = 'Görev tamamlanamadı — tekrar deniyorsun.';
        _resetAdventureAttempt();
        HapticFeedback.heavyImpact();
      } else {
        message = '+${breakdown.total} · $adventureProgress/${task.target}';
      }
    }
    if (earnedPass) message = '$message · +1 pas hakkı!';
    notifyListeners();
  }
}
