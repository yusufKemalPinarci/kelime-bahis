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
import 'word_length.dart';

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

  int level = 1;
  int score = 0;
  int target = 32;
  int handsLeft = 4;
  int discardsLeft = 2;
  int hintsLeft = 1;
  int shopRerollsLeft = 1;
  int gold = 0;
  int shortWordsThisLevel = 0;
  bool endless = false;
  BossModifier? activeBoss;
  RunPhase phase = RunPhase.starter;
  RunMode mode = RunMode.classic;
  DailySeed? dailySeed;
  int? runSeed;
  String message = '2–8 harfli Türkçe kelime kur, hedefi geç.';
  String? hintWord;
  int? hintEstimatedScore;
  ScoreBreakdown? lastScore;
  int lastEfficiencyBonus = 0;
  int lastGoldEarned = 0;
  int bestWordScore = 0;
  String? bestWordPlayed;
  bool ready = false;

  static const handSize = kHandSize;

  bool get isBossLevel => !endless && level % 4 == 0;

  bool get dailyAvailableToday {
    final today = DailySeed.today();
    return stats.lastCompletedDailyKey != today.storageKey;
  }

  String get dailyLabel => DailySeed.today().label;

  int get jokerSlotsLeft => kMaxJokerSlots - ownedJokers.length;

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
        .where((w) => w.isNotEmpty)
        .where((w) {
          final n = normalizeTr(w);
          return isValidWordLength(n.length);
        });
    dictionary = WordDictionary(words);
    dictionary!.buildAnagramIndex();

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
    gold = 4;
    shortWordsThisLevel = 0;
    handsLeft = 4;
    discardsLeft = 2;
    hintsLeft = 1;
    shopRerollsLeft = 1;
    hintWord = null;
    hintEstimatedScore = null;
    lastScore = null;
    lastEfficiencyBonus = 0;
    lastGoldEarned = 0;
    bestWordScore = 0;
    bestWordPlayed = null;
    _setupLevel();
    _refillHand();
    phase = RunPhase.playing;
    message = mode == RunMode.daily
        ? 'Günlük · 2–8 harfli Türkçe kelime kur'
        : '2–8 harfli Türkçe kelime kur · hedefi geç';
    notifyListeners();
  }

  void _setupLevel() {
    // Tek sürekli eğri — L3→L4 uçurumu yok
    final growth = endless ? 1.2 : 1.22;
    final baseTarget = endless ? 48 : 32;
    final baseLevel = endless ? (12 + (level - 12)) : level;
    target = (baseTarget * pow(growth, baseLevel - 1)).round();
    score = 0;
    handsLeft = 4;
    discardsLeft = 2;
    hintsLeft = 1;
    shortWordsThisLevel = 0;
    hintWord = null;
    hintEstimatedScore = null;
    lastEfficiencyBonus = 0;
    lastGoldEarned = 0;
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
    } else if (selected.length < kMaxWordLength) {
      selected.add(tile);
    } else {
      message = 'En fazla $kMaxWordLength harf seçebilirsin.';
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

  void sortHand() {
    if (phase != RunPhase.playing) return;
    hand.sort((a, b) => _trLetterCompare(a.letter, b.letter));
    notifyListeners();
  }

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

  int? get livePreviewScore {
    if (dictionary == null || !isValidWordLength(selected.length)) return null;
    final word = normalizeTr(selectedWord);
    if (!dictionary!.contains(word)) return null;
    if (playedThisLevel.contains(word)) return null;
    if (activeBoss?.validate(word) != null) return null;
    if (word.length <= 3 && shortWordsThisLevel >= kMaxShortWordsPerLevel) {
      return null;
    }
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
        if (w.length <= 3 && shortWordsThisLevel >= kMaxShortWordsPerLevel) {
          return false;
        }
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
    if (!isValidWordLength(word.length)) {
      message =
          'Kelime $kMinWordLength–$kMaxWordLength harf olmalı (şimdi ${word.length}).';
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
    if (word.length <= 3 && shortWordsThisLevel >= kMaxShortWordsPerLevel) {
      message =
          'Bu seviyede en fazla $kMaxShortWordsPerLevel kısa (≤3) kelime.';
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
    if (word.length <= 3) shortWordsThisLevel += 1;
    if (breakdown.total > bestWordScore) {
      bestWordScore = breakdown.total;
      bestWordPlayed = word;
    }
    HapticFeedback.lightImpact();

    for (final t in List<LetterTile>.from(selected)) {
      hand.remove(t);
    }
    selected.clear();
    _refillHand();

    final notesHint = breakdown.notes.isEmpty
        ? ''
        : ' · ${breakdown.notes.take(2).join(' · ')}';

    if (score >= target) {
      lastEfficiencyBonus = handsLeft * 3;
      score += lastEfficiencyBonus;
      lastGoldEarned = 2 + handsLeft * 2;
      gold += lastGoldEarned;
      message = lastEfficiencyBonus > 0
          ? 'Seviye geçildi! +${breakdown.total}$notesHint · '
              'verim +$lastEfficiencyBonus · +$lastGoldEarned altın'
          : 'Seviye geçildi! +${breakdown.total}$notesHint · '
              '+$lastGoldEarned altın';
      HapticFeedback.mediumImpact();
      stats.noteLevelReached(level);
      stats.save();
      _openShop();
    } else if (handsLeft <= 0) {
      phase = RunPhase.lost;
      final gap = target - score;
      final best = bestWordPlayed != null
          ? ' En iyi: $bestWordPlayed (+$bestWordScore).'
          : '';
      message = 'Turlar bitti. $score / $target (−$gap).$best';
      HapticFeedback.heavyImpact();
    } else {
      message = '+${breakdown.total}$notesHint · $score / $target';
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
    final dumped = List<LetterTile>.from(selected);
    for (final t in dumped) {
      hand.remove(t);
    }
    selected.clear();
    hintWord = null;
    hintEstimatedScore = null;
    bag.returnTiles(dumped);
    _refillHand();
    message =
        'Atılanlar torbaya döndü · atma $discardsLeft · torba ${bag.remaining}';
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
      (runSeed ?? 1) + level * 31 + (1 - shopRerollsLeft) * 97 + gold,
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
    if (gold < kShopRerollCost) {
      message = 'Reroll için $kShopRerollCost altın gerekli.';
      notifyListeners();
      return;
    }
    gold -= kShopRerollCost;
    shopRerollsLeft -= 1;
    _rollShopOffers();
    message = 'Mağaza yenilendi (−$kShopRerollCost altın).';
    notifyListeners();
  }

  /// Joker satın al; slot doluysa en ucuzu yarım fiyata satılır.
  void buyJoker(JokerCard joker) {
    if (phase != RunPhase.shop) return;
    if (!shopOffers.any((j) => j.id == joker.id)) return;
    if (gold < joker.cost) {
      message = 'Yetersiz altın (${joker.cost} gerekir).';
      notifyListeners();
      return;
    }

    var soldNote = '';
    if (ownedJokers.length >= kMaxJokerSlots) {
      ownedJokers.sort((a, b) => a.cost.compareTo(b.cost));
      final sold = ownedJokers.removeAt(0);
      final refund = (sold.cost / 2).floor();
      gold += refund;
      soldNote = ' · ${sold.name} satıldı (+$refund)';
    }

    gold -= joker.cost;
    ownedJokers.add(joker);
    shopOffers.removeWhere((j) => j.id == joker.id);
    message = '${joker.name} alındı (−${joker.cost})$soldNote';
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void sellJoker(JokerCard joker) {
    if (phase != RunPhase.shop) return;
    final idx = ownedJokers.indexWhere((j) => j.id == joker.id);
    if (idx < 0) return;
    ownedJokers.removeAt(idx);
    final refund = (joker.cost / 2).floor().clamp(1, joker.cost);
    gold += refund;
    message = '${joker.name} satıldı (+$refund altın)';
    notifyListeners();
  }

  void advanceAfterShop(JokerCard? bought) {
    if (bought != null) {
      buyJoker(bought);
      if (!ownedJokers.any((j) => j.id == bought.id)) {
        // Satın alma başarısız (altın yok) — mağazada kal
        return;
      }
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

  void skipShop() => advanceAfterShop(null);

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
    message = 'Endless başladı · hedefler büyümeye devam';
    notifyListeners();
  }
}
