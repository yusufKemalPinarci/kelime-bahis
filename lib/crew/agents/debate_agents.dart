import '../agent.dart';
import '../context.dart';

/// Tur 5: sadelik + anlasilirlik + gorsel netlik
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
};

Agent createDebateDesignerAgent() {
  return Agent(
    role: 'Tasarimci',
    goal: 'Oyuna giren 5 saniyede kurallari anlasin',
    backstory: 'Asiri buton = karmaşa. Tek hedef, tek CTA.',
    execute: (CrewContext ctx) async {
      final proposals = [
        {
          'id': 'inline_how_to_play',
          'title': 'Oyun ekraninda hep gorunen 1 satir kural',
          'why': 'Dialog unutulur; HUD ogretir',
          'effort': 1,
          'impact': 5,
        },
        {
          'id': 'simplify_controls',
          'title': 'Temizle/Sirala ikincil; OYNA buyuk',
          'why': 'Ana eylem net',
          'effort': 2,
          'impact': 5,
        },
        {
          'id': 'skip_starter_default',
          'title': 'Starter joker opsiyonel; varsayilan direkt oyna',
          'why': 'Ilk engeli kaldir',
          'effort': 2,
          'impact': 4,
        },
      ];
      ctx.set('debate_designer', proposals);
      return 'Tasarimci: sadelik 3 oneri';
    },
  );
}

Agent createDebateDictionaryAgent() {
  return Agent(
    role: 'Sozluk',
    goal: 'Gunluk TR kelimeler; nadir/jargon yok',
    backstory: 'Siklik listesi + kisa gunluk kelimeler.',
    execute: (CrewContext ctx) async {
      final proposals = [
        {
          'id': 'common_tr_dict',
          'title': 'Yaygin Turkce sozluk yenile (3-7 harf)',
          'why': 'Oyuncu kelime bulabilsin',
          'effort': 3,
          'impact': 5,
        },
        {
          'id': 'inline_how_to_play',
          'title': 'Kural: Turkce kelime kur, hedefi gec',
          'why': 'Sozluk beklentisini netlestir',
          'effort': 1,
          'impact': 4,
        },
        {
          'id': 'show_word_preview_score',
          'title': 'Secili kelimenin anlik skorunu goster',
          'why': 'OYNA oncesi ne olacagini anlar',
          'effort': 2,
          'impact': 4,
        },
      ];
      ctx.set('debate_dictionary', proposals);
      return 'Sozluk: 3 oneri';
    },
  );
}

Agent createDebateBalanceAgent() {
  return Agent(
    role: 'Denge',
    goal: 'Ilk seviyeler kolay; hedef dusuk',
    backstory: 'Onboarding = kazanma hissi.',
    execute: (CrewContext ctx) async {
      final proposals = [
        {
          'id': 'easier_early_targets',
          'title': 'Ilk 3 seviye daha dusuk hedef',
          'why': 'Ogrenirken kaybetme',
          'effort': 1,
          'impact': 5,
        },
        {
          'id': 'skip_starter_default',
          'title': 'Joker secimini atla; magazada ogren',
          'why': 'Karar yuku sonraya',
          'effort': 1,
          'impact': 3,
        },
        {
          'id': 'show_word_preview_score',
          'title': 'Anlik skor onizleme',
          'why': 'Hedefe ne kadar kaldigini gorur',
          'effort': 1,
          'impact': 4,
        },
      ];
      ctx.set('debate_balance', proposals);
      return 'Denge: 3 oneri';
    },
  );
}

Agent createDebateContentAgent() {
  return Agent(
    role: 'Icerik/Gorsel',
    goal: 'Sicak toprak tonlari; net harf taslari',
    backstory: 'Kart yogunlugu azalt; atmosfer artir.',
    execute: (CrewContext ctx) async {
      final proposals = [
        {
          'id': 'visual_refresh',
          'title': 'Harf tasi + hedef cubugu + sade ana ekran',
          'why': 'Ilk bakista oyun dili',
          'effort': 3,
          'impact': 5,
        },
        {
          'id': 'common_tr_dict',
          'title': 'Sozluk kalitesi',
          'why': 'Icerik = kelimeler',
          'effort': 2,
          'impact': 5,
        },
        {
          'id': 'simplify_controls',
          'title': 'Az buton',
          'why': 'Gorsel nefes',
          'effort': 1,
          'impact': 4,
        },
      ];
      ctx.set('debate_content', proposals);
      return 'Icerik: 3 oneri';
    },
  );
}

Agent createFacilitatorAgent() {
  return Agent(
    role: 'Facilitator',
    goal: '[aşama debate] Önerileri skorla; en fazla 5 approved backlog id üret',
    backstory: 'API yok; impact/effort ile karar. design aşamasından önce biter.',
    execute: (CrewContext ctx) async {
      final shipped = {...kShippedFeatureIds};
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
          titles[id] = m['title'] as String;
        }
      }
      scores.updateAll((id, s) => s + (mentions[id]! - 1) * 2);
      final ranked = scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final decided = ranked.take(5).map((e) {
        return {
          'id': e.key,
          'title': titles[e.key],
          'score': e.value,
          'mentions': mentions[e.key],
          'status': 'approved',
          'round': 5,
        };
      }).toList();
      ctx.set('decisions', decided);
      ctx.set('deferred', ranked.skip(5).map((e) {
        return {'id': e.key, 'title': titles[e.key], 'status': 'deferred'};
      }).toList());
      return 'Tur5: ${decided.map((d) => d['id']).join(', ')}';
    },
  );
}
