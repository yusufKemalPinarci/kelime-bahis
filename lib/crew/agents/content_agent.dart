import 'dart:convert';
import 'dart:io';

import '../agent.dart';
import '../context.dart';

Agent createContentAgent() {
  return Agent(
    role: 'İçerik Üreticisi',
    goal:
        '[aşama content] jokers.json ve bosses.json senkronla; Türkçe isim '
        've kısıt metinlerini balance sınırlarına uyumlu tut',
    backstory:
        'balance sonrası çalışır; engine/ui’den önce içerik paketini kilitler. '
        'Offline; kumar yok; eğlence odaklı joker isimleri.',
    execute: (CrewContext ctx) async {
      // Prefer committed asset files so crew sync does not shrink content.
      final jokersFile = File('assets/content/jokers.json');
      final bossesFile = File('assets/content/bosses.json');
      List<dynamic> jokers = [];
      List<dynamic> bosses = [];
      if (jokersFile.existsSync() && bossesFile.existsSync()) {
        jokers = jsonDecode(await jokersFile.readAsString()) as List<dynamic>;
        bosses = jsonDecode(await bossesFile.readAsString()) as List<dynamic>;
      }
      ctx.set('jokers', jokers);
      ctx.set('bosses', bosses);
      return 'İçerik senkron: ${jokers.length} joker, ${bosses.length} boss';
    },
  );
}
