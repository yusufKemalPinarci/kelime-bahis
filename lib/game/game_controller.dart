import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'daily_seed.dart';
import 'letter_bag.dart';
import 'local_stats.dart';
import 'scoring.dart';
import 'turkish.dart';
import 'word_dictionary.dart';

enum RunPhase { starter, playing, shop, won, lost }

enum RunMode { classic, daily }

const _trOrder = 'abcçdefgğhıijklmnoöprsştuüvyz';

int _trLetterCompare(String a, String b) {
  final na = normalizeTr(a);
  final nb = normalizeTr(b);
  final ia = _trOrder.indexOf(na);
  final ib = _trOrder.indexOf(nb);
  return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
}

class GameController extends ChangeNotifier {
  WordDictionary? dictionary;
  List<JokerCard> catalog = [];
  List<BossModifier> bosses = [];
  LocalStats stats = LocalStats();

  late LetterBag bag;
  final List<LetterTile> hand = [];
  final List<LetterTile> selected = [];
  final List<JokerCard> ownedJokers = [];
  final Set<String> playedThisLevel = {};
  List<JokerCard> shopOffers = [];
  List<JokerCard> starterOffers = [];

  int level = 1;
  int score = 0;
  int target = 40;
  int handsLeft = 4;
  int discardsLeft = 2;
  int hintsLeft = 1;
  int shopRerollsLeft = 1;
  bool endless = false;
  BossModifier? activeBoss;
  RunPhase phase = RunPhase.starter;
  RunMode mode = RunMode.classic;
  DailySeed? dailySeed;
  int? runSeed;
  String message = 'Kelime kur, hedefi geç.';
  String? hintWord;
  int? hintEstimatedScore;
  ScoreBreakdown? lastScore;
  int lastEfficiencyBonus = 0;
  bool ready = false;

  static const handSize = 8;

  bool get isBossLevel => !endless && level % 4 == 0;

  bool get dailyAvailableToday {
    final today = DailySeed.today();
    return stats.lastCompletedDailyKey != today.storageKey;
  }

  String get dailyLabel => DailySeed.today().label;

  /// Shop'ta bir sonraki seviye boss ise önizleme.
  BossModifier? get upcomingBossPreview {
    if (phase != RunPhase.shop || endless || bosses.isEmpty) return null;
    final next = level + 1;
    if (next % 4 != 0) return null;
    final idx = _seededIndex(bosses.length, salt: next * 17 + (runSeed ?? 0));
    return bosses[idx];
  }

  Future<void> bootstrap() async {
    stats = await LocalStats.load();

    final wordsRaw =
        await rootBundle.loadString('assets/dictionary/tr_words.txt');
    final words = wordsRaw
        .split(RegExp(r'\r?\n'))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty);
    dictionary = WordDictionary(words);

    final jokersRaw = await rootBundle.loadString('assets/content/jokers.json');
    catalog = (jsonDecode(jokersRaw) as List)
        .cast<Map<String, dynamic>>()
        .map(JokerCard.fromJson)
        .toList();

    final bossesRaw = await rootBundle.loadString('assets/content/bosses.json');
    bosses = (jsonDecode(bossesRaw) as List)
        .cast<Map<String, dynamic>>()
        .map(BossModifier.fromJson)
        .toList();

    ready = true;
    startNewRun();
  }

  void startNewRun({RunMode runMode = RunMode.classic}) {
    mode = runMode;
    endless = false;
    if (runMode == RunMode.daily) {
      dailySeed = DailySeed.today();
      runSeed = dailySeed!.value;
    } else {
      dailySeed = null;
      runSeed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    }

    bag = LetterBag.standard(seed: runSeed);
    hand.clear();
    selected.clear();
    ownedJokers.clear();
    shopOffers.clear();
    playedThisLevel.clear();
    level = 1;
    score = 0;
    handsLeft = 4;
    discardsLeft = 2;
    hintsLeft = 1;
    shopRerollsLeft = 1;
    hintWord = null;
    hintEstimatedScore = null;
    lastScore = null;
    lastEfficiencyBonus = 0;
    _setupLevel();
    _refillHand();
    starterOffers.clear();
    // Tur 5: starter atlanır — joker mağazada öğrenilir
    phase = RunPhase.playing;
    message = mode == RunMode.daily
        ? 'Günlük · Türkçe kelime kur, hedefi geç'
        : 'Türkçe kelime kur · hedefi geç';
    notifyListeners();
  }

  void pickStarter(JokerCard? joker) {
    if (phase != RunPhase.starter) return;
    if (joker != null) {
      ownedJokers.add(joker);
    }
    starterOffers.clear();
    phase = RunPhase.playing;
    message = 'Türkçe kelime kur · hedefi geç';
    notifyListeners();
  }

  void _setupLevel() {
    // İlk 3 seviye daha kolay (öğrenme)
    final double growth;
    final int baseTarget;
    if (endless) {
      growth = 1.2;
      baseTarget = 40;
    } else if (level <= 3) {
      growth = 1.15;
      baseTarget = 24;
    } else {
      growth = 1.32;
      baseTarget = 36;
    }
    final baseLevel = endless ? (12 + (level - 12)) : level;
    target = (baseTarget * pow(growth, baseLevel - 1)).round();
    score = 0;
    handsLeft = 4;
    discardsLeft = 2;
    hintsLeft = 1;
    hintWord = null;
    hintEstimatedScore = null;
    lastEfficiencyBonus = 0;
    playedThisLevel.clear();
    if (isBossLevel && bosses.isNotEmpty) {
      final idx = _seededIndex(
        bosses.length,
        salt: level * 17 + (runSeed ?? 0),
      );
      activeBoss = bosses[idx];
      message = 'BOSS: ${activeBoss!.name} — ${activeBoss!.description}';
    } else {
      activeBoss = null;
      message = endless
          ? 'Endless $level — hedef $target'
          : 'Seviye $level — hedef $target';
    }
  }

  int _seededIndex(int length, {required int salt}) {
    if (length <= 0) return 0;
    return Random(salt).nextInt(length);
  }

  void _refillHand() {
    final need = handSize - hand.length;
    if (need > 0) {
      hand.addAll(bag.draw(need));
    }
  }

  void toggleSelect(LetterTile tile) {
    if (phase != RunPhase.playing) return;
    if (selected.contains(tile)) {
      selected.remove(tile);
    } else {
      selected.add(tile);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (phase != RunPhase.playing) return;
    selected.clear();
    notifyListeners();
  }

  void sortHand() {
    if (phase != RunPhase.playing) return;
    hand.sort((a, b) => _trLetterCompare(a.letter, b.letter));
    notifyListeners();
  }

  /// Selects hand tiles matching [word] in order (auto_select_hint).
  bool selectWordFromHand(String word) {
    if (phase != RunPhase.playing) return false;
    final target = normalizeTr(word);
    selected.clear();
    final available = List<LetterTile>.from(hand);
    for (final ch in target.split('')) {
      final idx = available.indexWhere((t) => normalizeTr(t.letter) == ch);
      if (idx < 0) {
        selected.clear();
        return false;
      }
      selected.add(available.removeAt(idx));
    }
    hintWord = target;
    if (hintEstimatedScore != null) {
      message = 'İpucu seçildi: $target (~$hintEstimatedScore)';
    } else {
      message = 'İpucu seçildi: $target';
    }
    notifyListeners();
    return true;
  }

  String get selectedWord => selected.map((t) => t.letter).join();

  /// Seçili harflerin anlık skor önizlemesi (geçerli kelimeyse).
  int? get livePreviewScore {
    if (dictionary == null || selected.length < 3) return null;
    final word = normalizeTr(selectedWord);
    if (!dictionary!.contains(word)) return null;
    if (playedThisLevel.contains(word)) return null;
    if (activeBoss?.validate(word) != null) return null;
    return scoreWord(word: word, jokers: ownedJokers).total;
  }

  double get progressToTarget =>
      target <= 0 ? 0 : (score / target).clamp(0.0, 1.0);

  void useSoftHint() {
    if (phase != RunPhase.playing || dictionary == null) return;
    if (hintsLeft <= 0) {
      message = 'İpucu hakkı bitti.';
      notifyListeners();
      return;
    }
    final word = dictionary!.findPlayableWord(
      hand.map((t) => t.letter),
      validate: (w) {
        if (playedThisLevel.contains(w)) return false;
        return activeBoss?.validate(w) == null;
      },
    );
    hintsLeft -= 1;
    if (word == null) {
      hintWord = null;
      hintEstimatedScore = null;
      message = 'Bu elde uygun kelime bulunamadı.';
      notifyListeners();
      return;
    }
    final estimate = scoreWord(word: word, jokers: ownedJokers);
    hintEstimatedScore = estimate.total;
    hintWord = word;
    selectWordFromHand(word);
  }

  void playWord() {
    if (phase != RunPhase.playing || dictionary == null) return;
    if (selected.isEmpty) {
      message = 'Önce harf seç (sırayla dokun).';
      HapticFeedback.selectionClick();
      notifyListeners();
      return;
    }

    final word = normalizeTr(selectedWord);
    if (word.length < 3) {
      message = 'Kelime en az 3 harf olmalı.';
      HapticFeedback.heavyImpact();
      notifyListeners();
      return;
    }
    if (!dictionary!.contains(word)) {
      message = '"$word" sözlükte yok — başka bir kelime dene.';
      HapticFeedback.heavyImpact();
      notifyListeners();
      return;
    }
    if (playedThisLevel.contains(word)) {
      message = '"$word" bu seviyede zaten oynandı.';
      HapticFeedback.heavyImpact();
      notifyListeners();
      return;
    }

    final bossError = activeBoss?.validate(word);
    if (bossError != null) {
      message = bossError;
      HapticFeedback.heavyImpact();
      notifyListeners();
      return;
    }

    final breakdown = scoreWord(word: word, jokers: ownedJokers);
    lastScore = breakdown;
    score += breakdown.total;
    handsLeft -= 1;
    hintWord = null;
    hintEstimatedScore = null;
    playedThisLevel.add(word);
    HapticFeedback.lightImpact();

    for (final t in List<LetterTile>.from(selected)) {
      hand.remove(t);
    }
    selected.clear();
    _refillHand();

    if (score >= target) {
      lastEfficiencyBonus = handsLeft * 3;
      score += lastEfficiencyBonus;
      message = lastEfficiencyBonus > 0
          ? 'Seviye geçildi! +${breakdown.total} · verim +$lastEfficiencyBonus'
          : 'Seviye geçildi! +${breakdown.total}';
      HapticFeedback.mediumImpact();
      stats.noteLevelReached(level);
      stats.save();
      _openShop();
    } else if (handsLeft <= 0) {
      phase = RunPhase.lost;
      message = 'Turlar bitti. $score / $target';
      HapticFeedback.heavyImpact();
    } else {
      message = '+${breakdown.total} · $score / $target';
    }
    notifyListeners();
  }

  void discardSelected() {
    if (phase != RunPhase.playing) return;
    if (discardsLeft <= 0 || selected.isEmpty) {
      message = discardsLeft <= 0 ? 'Atma hakkı yok.' : 'Harf seç.';
      notifyListeners();
      return;
    }
    discardsLeft -= 1;
    for (final t in List<LetterTile>.from(selected)) {
      hand.remove(t);
    }
    selected.clear();
    hintWord = null;
    hintEstimatedScore = null;
    _refillHand();
    message = 'Harfler yenilendi · atma $discardsLeft';
    notifyListeners();
  }

  void _openShop() {
    phase = RunPhase.shop;
    shopRerollsLeft = 1;
    _rollShopOffers();
    if (shopOffers.isEmpty) {
      advanceAfterShop(null);
    }
  }

  void _rollShopOffers() {
    final pool =
        catalog.where((j) => !ownedJokers.any((o) => o.id == j.id)).toList();
    final rng = Random(
      (runSeed ?? 1) + level * 31 + (1 - shopRerollsLeft) * 97,
    );
    pool.shuffle(rng);
    shopOffers = pool.take(3).toList();
  }

  void rerollShop() {
    if (phase != RunPhase.shop) return;
    if (shopRerollsLeft <= 0) {
      message = 'Reroll hakkı bitti.';
      notifyListeners();
      return;
    }
    shopRerollsLeft -= 1;
    _rollShopOffers();
    message = 'Mağaza yenilendi.';
    notifyListeners();
  }

  void advanceAfterShop(JokerCard? bought) {
    if (bought != null) {
      ownedJokers.add(bought);
    }

    final finishedClassic = !endless && level >= 12;
    if (finishedClassic) {
      phase = RunPhase.won;
      message = mode == RunMode.daily
          ? 'Günlük koşu tamam · ${dailySeed?.label ?? ''}'
          : 'Koşu tamam! Endless ile devam edebilirsin.';
      if (mode == RunMode.daily && dailySeed != null) {
        stats.noteDailyWin(dailySeed!);
      } else {
        stats.noteClassicWin();
      }
      stats.noteLevelReached(level);
      stats.save();
      notifyListeners();
      return;
    }

    level += 1;
    phase = RunPhase.playing;
    shopOffers.clear();
    selected.clear();
    _setupLevel();
    if (bag.remaining < handSize) {
      bag = LetterBag.standard(seed: (runSeed ?? 1) + level);
    }
    hand.clear();
    _refillHand();
    notifyListeners();
  }

  void enterEndless() {
    if (phase != RunPhase.won) return;
    endless = true;
    level = 13;
    phase = RunPhase.playing;
    shopOffers.clear();
    selected.clear();
    _setupLevel();
    if (bag.remaining < handSize) {
      bag = LetterBag.standard(seed: (runSeed ?? 1) + 1300);
    }
    hand.clear();
    _refillHand();
    message = 'Endless başladı · hedefler x1.2 büyür';
    notifyListeners();
  }
}
