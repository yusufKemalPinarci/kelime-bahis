import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'daily_seed.dart';
import 'letter_bag.dart';
import 'local_stats.dart';
import 'rank.dart';
import 'scoring.dart';
import 'turkish.dart';
import 'word_dictionary.dart';
import 'word_length.dart';

enum RunPhase { starter, playing, shop, won, lost }

enum RunMode { classic, daily }

// --- Tur 8 design hooks (DesignerAgent) ---
/// Başlangıç altını. Eski: 4. Playtest: 5 → ilk mağazada ucuz joker + reroll hissi.
const int kStartingGold = 5;

// Boss hedef çarpanı: scoring.dart `kBossTargetMultiplier` / `computeLevelTarget`.

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
  int passesLeft = 1;
  int gold = 0;
  int requiredLength = 2;
  int comboStreak = 0;
  bool endless = false;
  BossModifier? activeBoss;
  RunPhase phase = RunPhase.starter;
  RunMode mode = RunMode.classic;
  bool _pregameShop = false;

  /// Koşu başlamadan önceki tek seferlik "hazırlık" mağazası mı?
  bool get isPregameShop => _pregameShop;
  DailySeed? dailySeed;
  int? runSeed;
  String message = '';
  String? hintWord;
  int? hintEstimatedScore;
  ScoreBreakdown? lastScore;
  int lastEfficiencyBonus = 0;
  int lastGoldEarned = 0;
  int bestWordScore = 0;
  String? bestWordPlayed;
  bool ready = false;

  /// Bootstrap sırasında ölümcül hata (sözlük yüklenemedi vb.); UI hata ekranı
  /// gösterir ve tekrar denemeye izin verir.
  String? bootstrapError;

  /// Koşu başındaki ömür boyu puan — bitişte kazanılan puanı hesaplamak için.
  int _lifetimeScoreAtRunStart = 0;

  int get lifetimeScoreGainedThisRun =>
      stats.lifetimeScore - _lifetimeScoreAtRunStart;

  bool get rankedUpThisRun =>
      rankForScore(stats.lifetimeScore).threshold >
      rankForScore(_lifetimeScoreAtRunStart).threshold;

  static const handSize = kHandSize;

  bool get isBossLevel =>
      !endless && (isBossLevelNumber(level) || level == kClassicLevels);

  bool get dailyAvailableToday {
    final today = DailySeed.today();
    return stats.lastCompletedDailyKey != today.storageKey;
  }

  String get dailyLabel => DailySeed.today().label;

  int get jokerSlotsLeft => kMaxJokerSlots - ownedJokers.length;

  BossModifier? get upcomingBossPreview {
    if (phase != RunPhase.shop || endless || bosses.isEmpty) return null;
    final next = level + 1;
    if (!isBossLevelNumber(next)) return null;
    final idx = _seededIndex(bosses.length, salt: next * 17 + (runSeed ?? 0));
    return bosses[idx];
  }

  /// `boss_score_pressure` HUD metin kuralı — tek satır, ikincil; ana CTA değil.
  /// Örnek: «Boss · hedef +10%». UI agent chip olarak okur.
  String? get bossPressureHudText {
    if (!isBossLevel || activeBoss == null) return null;
    final pct = ((kBossTargetMultiplier - 1.0) * 100).round();
    return 'Boss · hedef +$pct%';
  }

  Future<void> bootstrap() async {
    bootstrapError = null;
    stats = await LocalStats.load();
    _pruneStaleSavedRun();

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

    catalog = await _loadContentList(
      'assets/content/jokers.json',
      JokerCard.fromJson,
    );
    bosses = await _loadContentList(
      'assets/content/bosses.json',
      BossModifier.fromJson,
    );

    ready = true;
    startNewRun();
  }

  /// İçerik JSON'unu güvenli yükler: dosya/parse hatasında boş liste,
  /// bozuk tek girdilerde o girdiyi atla — oyun çalışmaya devam etsin.
  Future<List<T>> _loadContentList<T>(
    String asset,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final raw = await rootBundle.loadString(asset);
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final items = <T>[];
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) continue;
        try {
          items.add(fromJson(entry));
        } catch (e) {
          debugPrint('$asset içinde bozuk girdi atlandı: $e');
        }
      }
      return items;
    } catch (e) {
      debugPrint('$asset yüklenemedi: $e');
      return [];
    }
  }

  /// Günlük kaydedilmiş koşu bugüne ait değilse (gün değişmiş) sil.
  void _pruneStaleSavedRun() {
    if (stats.savedRunMode == 'daily' &&
        stats.savedRunDailyKey != DailySeed.today().storageKey) {
      stats.clearSavedRun();
    }
  }

  /// Seviye ilerledikçe koşuyu diske yazar — uygulama kapansa/çıkılsa bile
  /// `resumeRun()` ile kaldığı yerden devam edilebilir. Endless kalıcı
  /// değildir (skor-avı modu, bilerek kaydedilmez).
  void _persistRunState() {
    if (endless) return;
    stats.saveRun(
      mode: mode == RunMode.daily ? 'daily' : 'classic',
      level: level,
      gold: gold,
      jokerIds: ownedJokers.map((j) => j.id).toList(),
      dailyKey: mode == RunMode.daily ? dailySeed?.storageKey : null,
    );
    stats.save();
  }

  /// Kaydedilmiş koşuyu geri yükler (bkz. `LocalStats.hasSavedRun`).
  void resumeRun() {
    if (!stats.hasSavedRun) return;
    mode = stats.savedRunMode == 'daily' ? RunMode.daily : RunMode.classic;
    endless = false;
    if (mode == RunMode.daily) {
      dailySeed = DailySeed.today();
      runSeed = dailySeed!.value;
    } else {
      dailySeed = null;
      runSeed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    }

    bag = LetterBag.standard(seed: runSeed);
    hand.clear();
    selected.clear();
    ownedJokers
      ..clear()
      ..addAll(catalog.where((j) => stats.savedRunJokerIds.contains(j.id)));
    shopOffers.clear();
    playedThisLevel.clear();
    level = stats.savedRunLevel!;
    gold = stats.savedRunGold;
    _lifetimeScoreAtRunStart = stats.lifetimeScore;
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
    message = 'Seviye $level · $requiredLength harfli kelime · hedef $target';
    notifyListeners();
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
    gold = kStartingGold;
    _lifetimeScoreAtRunStart = stats.lifetimeScore;
    handsLeft = 4;
    discardsLeft = 2;
    hintsLeft = 1;
    hintWord = null;
    hintEstimatedScore = null;
    lastScore = null;
    lastEfficiencyBonus = 0;
    lastGoldEarned = 0;
    bestWordScore = 0;
    bestWordPlayed = null;
    _setupLevel();
    _refillHand();
    if (runMode == RunMode.classic) {
      // Koşuya girmeden önce oyuncu başlangıç altınını harcayabilsin.
      _openShop(pregame: true);
      message = '';
    } else {
      phase = RunPhase.playing;
      message = 'Günlük meydan okuma';
    }
    notifyListeners();
  }

  void _setupLevel() {
    requiredLength = lengthForLevel(level);
    // Tek kaynak: scoring.computeLevelTarget (uzunluk-temelli, gerçek
    // sözlük verisiyle kalibre edilmiş — bkz. kMedianRawWordScore).
    target = computeLevelTarget(level: level, endless: endless);
    score = 0;
    handsLeft = 4;
    discardsLeft = 2;
    hintsLeft = 1;
    comboStreak = 0;
    final extraPasses = ownedJokers
        .where((j) => j.kind == JokerKind.extraPass)
        .fold<int>(0, (a, j) => a + j.value.round());
    passesLeft = 1 + extraPasses;
    hintWord = null;
    hintEstimatedScore = null;
    lastEfficiencyBonus = 0;
    lastGoldEarned = 0;
    playedThisLevel.clear();
    if (isBossLevel && bosses.isNotEmpty) {
      // Uzunlukla uyumsuz boss hiç seçilmesin (örn. "en fazla 4 harf"
      // kuralı 6 harfli bir seviyede asla kazanılamaz).
      final pool = dictionary == null
          ? bosses
          : bosses
              .where((b) => dictionary!.hasWordOfLength(
                    requiredLength,
                    validate: (w) => b.validate(w) == null,
                  ))
              .toList();
      if (pool.isNotEmpty) {
        final idx = _seededIndex(pool.length, salt: level * 17 + (runSeed ?? 0));
        activeBoss = pool[idx];
      } else {
        activeBoss = null;
      }
      message = '';
    } else {
      activeBoss = null;
      message = '';
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
    _ensureSolvable();
  }

  /// Eldeki harflerle bu seviyenin gerektirdiği uzunlukta, henüz
  /// oynanmamış ve boss kuralına uyan bir kelime kurulamıyorsa, sözlükten
  /// böyle bir kelime seçip elin içine "eker" — oyuncuya asla kelimesiz
  /// bir el gösterilmez.
  void _ensureSolvable() {
    if (dictionary == null) return;

    bool valid(String w) {
      if (playedThisLevel.contains(w)) return false;
      return activeBoss?.validate(w) == null;
    }

    final solvable = dictionary!.findPlayableWordOfLength(
          requiredLength,
          hand.map((t) => t.letter),
          validate: valid,
        ) !=
        null;
    if (solvable) return;

    final rng = Random(
      ((runSeed ?? 1) + level * 53 + hand.length * 7 +
              DateTime.now().microsecondsSinceEpoch) &
          0x7fffffff,
    );
    final word = dictionary!.pickRandomWordOfLength(
      requiredLength,
      validate: valid,
      rng: rng,
    );
    if (word == null) return; // sözlükte bu uzunlukta uygun kelime yok

    bag.returnTiles(hand);
    hand.clear();
    var synth = 0;
    for (final ch in word.split('')) {
      final tile = bag.drawLetter(ch) ??
          LetterTile(id: '${ch}_g${level}_${synth++}', letter: ch);
      hand.add(tile);
    }
    final fillerNeeded = handSize - hand.length;
    if (fillerNeeded > 0) {
      hand.addAll(bag.draw(fillerNeeded));
    }
  }

  void toggleSelect(LetterTile tile) {
    if (phase != RunPhase.playing) return;
    if (selected.contains(tile)) {
      selected.remove(tile);
    } else if (selected.length < requiredLength) {
      selected.add(tile);
    } else {
      message = 'Bu seviye tam $requiredLength harf istiyor.';
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

  /// Anlık skor önizlemesi (tam detay) — hangi joker'lerin tetiklendiğini
  /// göstermek için UI tarafından da kullanılır.
  ScoreBreakdown? get livePreviewBreakdown {
    if (dictionary == null || selected.length != requiredLength) return null;
    final word = normalizeTr(selectedWord);
    if (!dictionary!.contains(word)) return null;
    if (playedThisLevel.contains(word)) return null;
    if (activeBoss?.validate(word) != null) return null;
    return scoreWord(word: word, jokers: ownedJokers);
  }

  int? get livePreviewScore => livePreviewBreakdown?.total;

  double get progressToTarget =>
      target <= 0 ? 0 : (score / target).clamp(0.0, 1.0);

  void useSoftHint() {
    if (phase != RunPhase.playing || dictionary == null) return;
    if (hintsLeft <= 0) {
      message = 'İpucu hakkı bitti.';
      notifyListeners();
      return;
    }
    final word = dictionary!.findPlayableWordOfLength(
      requiredLength,
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
      message = 'Harf seç.';
      HapticFeedback.selectionClick();
      notifyListeners();
      return;
    }

    final word = normalizeTr(selectedWord);
    if (word.length != requiredLength) {
      message = 'Bu seviye tam $requiredLength harf istiyor.';
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
    if (playedThisLevel.contains(word)) {
      message = '"$word" bu seviyede zaten oynandı.';
      selected.clear();
      HapticFeedback.heavyImpact();
      notifyListeners();
      return;
    }

    final bossError = activeBoss?.validate(word);
    if (bossError != null) {
      message = bossError;
      selected.clear();
      HapticFeedback.heavyImpact();
      notifyListeners();
      return;
    }

    comboStreak += 1;
    final breakdown =
        scoreWord(word: word, jokers: ownedJokers, comboStreak: comboStreak);
    lastScore = breakdown;
    score += breakdown.total;
    stats.addScore(breakdown.total);
    handsLeft -= 1;
    hintWord = null;
    hintEstimatedScore = null;
    playedThisLevel.add(word);
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
      stats.addScore(lastEfficiencyBonus);
      final extraGold = ownedJokers
          .where((j) => j.kind == JokerKind.extraGold)
          .fold<int>(0, (a, j) => a + j.value.round());
      lastGoldEarned = 2 + handsLeft * 2 + extraGold;
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
      // Eller bitti, hedefe ulaşılamadı — koşu burada biter (klasik/günlük/
      // endless hepsi aynı: yenilgi ekranı, ana ekrana dönüş).
      phase = RunPhase.lost;
      final gap = target - score;
      final best = bestWordPlayed != null
          ? ' En iyi: $bestWordPlayed (+$bestWordScore).'
          : '';
      message = 'Kaybettin. $score / $target (−$gap).$best';
      HapticFeedback.heavyImpact();
      if (!endless) {
        stats.clearSavedRun();
      }
      stats.save();
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
        'Atıldı · $discardsLeft kaldı';
    notifyListeners();
  }

  /// "Bu ellerde kelime göremiyorum" için mulligan — tüm eli yeniler,
  /// `handsLeft`'e dokunmaz. Seviye başına sınırlı (bkz. `passesLeft`).
  void usePass() {
    if (phase != RunPhase.playing) return;
    if (passesLeft <= 0) {
      message = 'Pas hakkı yok.';
      notifyListeners();
      return;
    }
    passesLeft -= 1;
    bag.returnTiles(hand);
    hand.clear();
    selected.clear();
    hintWord = null;
    hintEstimatedScore = null;
    _refillHand();
    message = 'Yeni harfler geldi.';
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void _openShop({bool pregame = false}) {
    _pregameShop = pregame;
    phase = RunPhase.shop;
    _rollShopOffers();
    if (shopOffers.isEmpty) {
      advanceAfterShop();
    }
  }

  void _rollShopOffers() {
    final pool =
        catalog.where((j) => !ownedJokers.any((o) => o.id == j.id)).toList();
    final rng = Random((runSeed ?? 1) + level * 31 + gold);
    pool.shuffle(rng);
    shopOffers = pool.take(2).toList();
  }

  /// Ödüllü reklam sonunda mağazaya altın ekler (bkz. `AdsController`).
  void grantBonusGold(int amount) {
    if (phase != RunPhase.shop || amount <= 0) return;
    gold += amount;
    message = 'Reklam ödülü: +$amount altın';
    notifyListeners();
  }

  /// Joker satın al. Slot doluysa alma — otomatik satış yok.
  void buyJoker(JokerCard joker) {
    if (phase != RunPhase.shop) return;
    if (!shopOffers.any((j) => j.id == joker.id)) return;
    if (ownedJokers.length >= kMaxJokerSlots) {
      message = 'Bonus slotların dolu.';
      notifyListeners();
      return;
    }
    if (gold < joker.cost) {
      message = 'Yetersiz altın';
      notifyListeners();
      return;
    }

    gold -= joker.cost;
    ownedJokers.add(joker);
    shopOffers.removeWhere((j) => j.id == joker.id);
    message = '${joker.name} (−${joker.cost})';
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Mağazadan çıkıp bir sonraki seviyeye (veya koşu bitişine) geçer.
  /// Joker satın alma bundan tamamen ayrı (bkz. `buyJoker`) — mağazada
  /// birden fazla joker alıp gezinebilir, yalnızca bu çağrıldığında çıkılır.
  void advanceAfterShop() {
    if (_pregameShop) {
      _pregameShop = false;
      phase = RunPhase.playing;
      shopOffers.clear();
      selected.clear();
      notifyListeners();
      return;
    }

    final finishedClassic = !endless && level >= kClassicLevels;
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
      stats.clearSavedRun();
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
    _persistRunState();
    notifyListeners();
  }

  void skipShop() => advanceAfterShop();

  void enterEndless() {
    if (phase != RunPhase.won) return;
    endless = true;
    level = kClassicLevels + 1;
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

  /// Screenshot QA: zor durumlara atla (yalnızca debug build).
  void debugQaPrepare(String scene) {
    if (!kDebugMode) return;
    startNewRun(runMode: RunMode.classic);
    switch (scene) {
      case 'shop':
        lastGoldEarned = 4;
        lastEfficiencyBonus = 6;
        gold = gold < 8 ? 8 : gold;
        _openShop();
      case 'boss_shop':
        level = 3;
        _setupLevel();
        lastGoldEarned = 6;
        lastEfficiencyBonus = 3;
        gold = gold < 10 ? 10 : gold;
        _openShop();
      case 'boss_playing':
        level = 4;
        _setupLevel();
        hand.clear();
        selected.clear();
        _refillHand();
        phase = RunPhase.playing;
      case 'won':
        level = kClassicLevels;
        phase = RunPhase.won;
        message = 'Koşu tamam! Endless ile devam edebilirsin.';
      case 'lost':
        level = 2;
        target = 40;
        score = 12;
        phase = RunPhase.lost;
        bestWordPlayed = 'masa';
        bestWordScore = 18;
        message = 'Turlar bitti. 12 / 40 (−28). En iyi: masa (+18).';
      default:
        break;
    }
    notifyListeners();
  }
}
