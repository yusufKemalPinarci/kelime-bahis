import '../agent.dart';
import '../context.dart';

/// Ship edilen özellikler (Tur 8 dahil).
const kShippedFeatureIds = {
  'clear_selection',
  'shop_reroll',
  'endless_mode',
  'soft_hint',
  'persist_stats',
  'auto_select_hint',
  'starter_joker',
  'no_repeat_words',
  'sort_hand',
  'unused_hand_bonus',
  'word_history',
  'hint_shows_points',
  'boss_preview',
  'first_run_tips',
  'new_jokers_v2',
  'invalid_shake',
  'haptic_play',
  // Tur 5
  'inline_how_to_play',
  'simplify_controls',
  'common_tr_dict',
  'show_word_preview_score',
  'skip_starter_default',
  'visual_refresh',
  'easier_early_targets',
  // Tur 6 — değişken uzunluk
  'variable_word_length_hand8',
  'wide_tr_dict',
  'length_scoring_fun',
  // Tur 7 — eğlence boşlukları
  'smooth_targets',
  'dict_quality',
  'discard_return',
  'light_economy',
  // Tur 8 — ekonomi + boss UI
  'economy_fine_tune',
  'boss_score_pressure',
  'joker_boss_dialog',
};

/// Bu turda bilinçli ertelenen id'ler (ses / Android).
const kDeferredThisRoundIds = {
  'offline_sfx',
  'android_release',
};

Agent createDebateDesignerAgent() {
  return Agent(
    role: 'Tasarimci',
    goal: 'Ekonomi ve boss baskisini tek hedef / tek CTA ile oku',
    backstory: 'Playtest sonrasi ince ayar; ses ve release bu turda yok.',
    execute: (CrewContext ctx) async {
      final proposals = [
        {
          'id': 'economy_fine_tune',
          'title': 'Magaza: baslangic altin / cost / reroll ince ayar',
          'why': 'Tur7 ekonomisi var; playtest ile fiyat hissi oturt',
          'effort': 2,
          'impact': 5,
        },
        {
          'id': 'joker_boss_dialog',
          'title': 'Boss oncesi joker-boss diyalog / UI kanca',
          'why': 'Boss preview var; joker sinerjisi metinle baglansin',
          'effort': 2,
          'impact': 4,
        },
        {
          'id': 'boss_score_pressure',
          'title': 'Boss seviyesinde skor baskisi HUD',
          'why': 'Oyuncu neden daha zor oldugunu gorsun',
          'effort': 2,
          'impact': 5,
        },
      ];
      ctx.set('debate_designer', proposals);
      return 'Tasarimci: Tur8 ekonomi+boss 3 oneri';
    },
  );
}

Agent createDebateDictionaryAgent() {
  return Agent(
    role: 'Sozluk',
    goal: 'Tur8 sozluk dondur; boss metinleri kelime kurallariyla uyumlu kalsin',
    backstory: 'dict_quality ship; bu tur filtre degil, netlik.',
    execute: (CrewContext ctx) async {
      final proposals = [
        {
          'id': 'boss_score_pressure',
          'title': 'Boss skor cezasi kelime uzunluguyla catismasin',
          'why': '2-8 harf + kisa limit zaten var; ceza sozlugu bozmasin',
          'effort': 1,
          'impact': 3,
        },
        {
          'id': 'joker_boss_dialog',
          'title': 'Diyalogda gecerli kelime kurali hatirlat',
          'why': 'Boss kisiti + sozluk beklentisi ayni cumlede',
          'effort': 1,
          'impact': 3,
        },
        {
          'id': 'economy_fine_tune',
          'title': 'Sozluk listesi sabit; ekonomi rakamlari ayri',
          'why': 'Playtest fiyat ayari sozluk degistirmez',
          'effort': 1,
          'impact': 2,
        },
      ];
      ctx.set('debate_dictionary', proposals);
      return 'Sozluk: Tur8 destek 3 oneri';
    },
  );
}

Agent createDebateBalanceAgent() {
  return Agent(
    role: 'Denge',
    goal: 'Altin/fiyat ince ayar + boss skor baskisi',
    backstory: 'startGold=4, reroll=1, cost 3-6; boss skor cezasi yok henuz.',
    execute: (CrewContext ctx) async {
      final proposals = [
        {
          'id': 'economy_fine_tune',
          'title': 'Joker cost / reroll / baslangic altin ince ayar',
          'why': 'Playtest: ucuz mu pahali mi netlestir',
          'effort': 2,
          'impact': 5,
        },
        {
          'id': 'boss_score_pressure',
          'title': 'Boss seviyelerinde skor cezasi veya hedef baskisi',
          'why': 'Sadece kelime kisiti yetmiyor; skor gerilimi lazim',
          'effort': 2,
          'impact': 5,
        },
        {
          'id': 'joker_boss_dialog',
          'title': 'Diyalog dengeyi anlatir; carpani sifirlamaz',
          'why': 'Metin kancasi; matematik balance ayri',
          'effort': 1,
          'impact': 3,
        },
      ];
      ctx.set('debate_balance', proposals);
      return 'Denge: Tur8 ekonomi+boss 3 oneri';
    },
  );
}

Agent createDebateContentAgent() {
  return Agent(
    role: 'Icerik/Gorsel',
    goal: 'Boss/joker Turkce metin; ses ve Android ertelenir',
    backstory: 'Cost etiketleri ve boss baski dili; SFX/release sonra.',
    execute: (CrewContext ctx) async {
      final proposals = [
        {
          'id': 'joker_boss_dialog',
          'title': 'Boss oncesi/sirasinda joker etkilesim metni',
          'why': 'Turkce isim + kisit + sahip joker baglantisi',
          'effort': 2,
          'impact': 4,
        },
        {
          'id': 'boss_score_pressure',
          'title': 'Boss aciklamasina skor baskisi dili',
          'why': 'Oyuncu cezayi metinden anlasin',
          'effort': 1,
          'impact': 4,
        },
        {
          'id': 'economy_fine_tune',
          'title': 'Joker cost hissi / magaza metin cilasi',
          'why': 'Fiyat bandi playtest ile hizalansin',
          'effort': 1,
          'impact': 3,
        },
        {
          'id': 'offline_sfx',
          'title': 'Offline ses efektleri (istege bagli)',
          'why': 'Atmosfer; zorunlu degil',
          'effort': 4,
          'impact': 2,
        },
        {
          'id': 'android_release',
          'title': 'Android release (ikon, splash)',
          'why': 'Dagitim; mekanik backlog sonrasi',
          'effort': 3,
          'impact': 2,
        },
      ];
      ctx.set('debate_content', proposals);
      return 'Icerik: Tur8 + deferred ses/android';
    },
  );
}

Agent createFacilitatorAgent() {
  return Agent(
    role: 'Facilitator',
    goal: '[aşama debate] Önerileri skorla; Tur8 en fazla 3 approved backlog id',
    backstory: 'API yok; impact/effort ile karar. Ses ve Android bu turda deferred.',
    execute: (CrewContext ctx) async {
      final shipped = {...kShippedFeatureIds};
      final forceDefer = {...kDeferredThisRoundIds};
      final buckets = [
        ctx.get<List<dynamic>>('debate_designer') ?? [],
        ctx.get<List<dynamic>>('debate_dictionary') ?? [],
        ctx.get<List<dynamic>>('debate_balance') ?? [],
        ctx.get<List<dynamic>>('debate_content') ?? [],
      ];
      final scores = <String, double>{};
      final titles = <String, String>{};
      final mentions = <String, int>{};
      for (final list in buckets) {
        for (final raw in list) {
          final m = Map<String, dynamic>.from(raw as Map);
          final id = m['id'] as String;
          if (shipped.contains(id)) continue;
          final impact = (m['impact'] as num).toDouble();
          final effort = (m['effort'] as num).toDouble();
          scores[id] = (scores[id] ?? 0) + (impact * 2 - effort);
          mentions[id] = (mentions[id] ?? 0) + 1;
          titles.putIfAbsent(id, () => m['title'] as String);
        }
      }
      scores.updateAll((id, s) => s + (mentions[id]! - 1) * 2);

      final deferredForced = <Map<String, dynamic>>[];
      for (final id in forceDefer) {
        if (scores.containsKey(id)) {
          deferredForced.add({
            'id': id,
            'title': titles[id],
            'status': 'deferred',
            'reason': 'Tur8 backlog: ses/Android ertelendi',
          });
          scores.remove(id);
        }
      }

      final ranked = scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final decided = ranked.take(3).map((e) {
        return {
          'id': e.key,
          'title': titles[e.key],
          'score': e.value,
          'mentions': mentions[e.key],
          'status': 'approved',
          'round': 8,
        };
      }).toList();
      final deferredRest = ranked.skip(3).map((e) {
        return {
          'id': e.key,
          'title': titles[e.key],
          'status': 'deferred',
        };
      }).toList();
      ctx.set('decisions', decided);
      ctx.set('deferred', [...deferredForced, ...deferredRest]);
      return 'Tur8: ${decided.map((d) => d['id']).join(', ')}';
    },
  );
}
