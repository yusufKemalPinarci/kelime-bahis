import 'dart:io';

/// Build-time: kaynaktan 2–8 harfli TR kelimeleri çıkarır + seed birleştirir.
///
/// Kullanım:
///   dart run scripts/build_tr_dict.dart [kaynak.txt]
///
/// 2-harf: yalnızca allowlist. Blocklist her uzunlukta elenir.
Future<void> main(List<String> args) async {
  const allowed = 'abcçdefgğhıijklmnoöprsştuüvyz';
  const minLen = 2;
  const maxLen = 8;

  final blocklist = await _loadBlocklist();
  final words = <String>{};

  void addLine(String raw) {
    var w = raw.trim();
    if (w.startsWith('"') && w.endsWith('"') && w.length >= 2) {
      w = w.substring(1, w.length - 1);
    }
    if (w.contains(',')) {
      w = w.split(',').first.trim();
    }
    w = _normalizeTr(w);
    if (w.length < minLen || w.length > maxLen) return;
    if (!_onlyTurkish(w, allowed)) return;
    if (blocklist.contains(w)) return;
    if (w.length == 2 && !_twoLetterAllowlist.contains(w)) return;
    words.add(w);
  }

  for (final line in _seedWords.split(RegExp(r'\s+'))) {
    if (line.isNotEmpty) addLine(line);
  }

  final existing = File('assets/dictionary/tr_words.txt');
  if (existing.existsSync()) {
    for (final line in await existing.readAsLines()) {
      addLine(line);
    }
  }

  if (args.isNotEmpty) {
    final src = File(args.first);
    if (!src.existsSync()) {
      stderr.writeln('Kaynak yok: ${src.path}');
      exit(66);
    }
    for (final line in await src.readAsLines()) {
      addLine(line);
    }
  }

  final sorted = words.toList()..sort();
  final out = File('assets/dictionary/tr_words.txt');
  await out.parent.create(recursive: true);
  await out.writeAsString('${sorted.join('\n')}\n');

  final byLen = <int, int>{};
  for (final w in sorted) {
    byLen[w.length] = (byLen[w.length] ?? 0) + 1;
  }
  stdout.writeln('Yazıldı: ${out.path} (${sorted.length} kelime, $minLen–$maxLen)');
  stdout.writeln('Dağılım: $byLen');
  for (final sample in ['çay', 'su', 'ev', 'aşk', 'elma', 'kitap', 'bh', 'zn']) {
    stdout.writeln('  $sample: ${words.contains(sample) ? "OK" : "YOK"}');
  }
}

Future<Set<String>> _loadBlocklist() async {
  final file = File('assets/dictionary/blocklist.txt');
  if (!file.existsSync()) return {};
  final out = <String>{};
  for (final line in await file.readAsLines()) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    out.add(_normalizeTr(t));
  }
  return out;
}

String _normalizeTr(String input) {
  return input
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('i̇', 'i')
      .trim();
}

bool _onlyTurkish(String word, String allowed) {
  for (final rune in word.runes) {
    if (!allowed.contains(String.fromCharCode(rune))) return false;
  }
  return true;
}

/// Gerçek Türkçe 2 harfli kelimeler (element kısaltmaları hariç).
const _twoLetterAllowlist = {
  'ad', 'af', 'ah', 'ak', 'al', 'an', 'ar', 'as', 'at', 'av', 'ay', 'az',
  'ba', 'be', 'bi', 'bu',
  'ce', 'ci',
  'da', 'de', 'di', 'do',
  'ek', 'el', 'en', 'er', 'et', 'ev', 'ey',
  'ha', 'he', 'hi',
  'il', 'im', 'in', 'ip', 'ir', 'is', 'it', 'iç',
  'ka', 'ki', 'ko',
  'la', 'le', 'li',
  'ma', 'mi', 'mu',
  'na', 'ne', 'ni', 'nu',
  'of', 'oh', 'ok', 'ol', 'on', 'or', 'ot', 'oy',
  'su', 'sü',
  'ta', 'te', 'ti', 'tu',
  'un', 'us', 'ut',
  'üf', 'ün',
  've', 'ya', 'ye', 'yo',
  'şu',
};

/// Yaygın Türkçe (özellikle kısa) — kaynak eksik olsa bile düşmesin.
const _seedWords = '''
ada ama ana ara ayak ayna baba bebek beyaz bilgi birlik buz cadde cam can deniz
ders dil dilek dost duvar ekmek elma emek ev fener gemi gece haber hava hayal
hikaye inek ipucu kalem kale kar kedi kent kitap kulak kutu lale limon lira
masa mavi mektup meyve mutfak nehir nokta ocak orman otel oyun pamuk para park
pembe pilav saat sabah sahil sakız sevgi simit sokak su tabak tatlı tepe toprak
tuz umut usta uyku vadi vapur vazo vergi yaprak yatak yazı yelken yemek yol
zaman zarf zeka zengin zeytin zil aile armut asker bakkal balkon benzin berber
bisiklet bulut dakika davul defter demlik eczane elbise enerji fabrika futbol
gazete hamam hastane helva ibrik iplik kahve kamp kanepe kavanoz kebap kilim
kira klima lamba lastik lavabo lokanta madalya makarna manav mantar market
mendil merdiven minare motor müzik nane nar nazar numara okul olta omuz paket
palto pantolon pastane pencere perde pizza pazar radyo raf renk resim roman
salata sandalye saray savaş sebze semt sevda sigorta silgi sinema spor tablo
takım tamir taksi telefon terlik tohum tren vagon valiz vitrin zemin zirve
anne baba kardeş dede nine amca teyze dayı hala çocuk bebek kız erkek adam
kadın doktor polis asker çiftçi işçi usta şoför garson ekmek peynir zeytin
domates soğan patates elma armut muz portakal kayısı erik karpuz kavun su süt
çay kahve ayran limonata bardak tabak kaşık tencere tava fırın ocak ev oda
salon mutfak banyo balkon pencere kapı duvar tavan zemin merdiven bahçe sokak
cadde mahalle semt şehir köy araba otobüs tren metro vapur uçak bisiklet motor
taksi kamyon okul ders sınav kitap defter kalem silgi çanta futbol tenis saha
top raket müzik dans film konser radyo telefon yaz kış gün ay yıl hafta dakika
saat pazartesi salı cuma pazar mavi sarı beyaz gri pembe bir iki beş on yirmi
otuz elli mutlu yorgun temiz kirli sıcak soğuk genç uzun balık başarı çocuk
çorba dağ doğru dünya fırın göl güneş güzel hızlı ırmak ışık kapı köprü köy
kuş neşe öğrenci ördek rüya rüzgar sarı sıcak süt şarkı şehir şeker şişe uçak
üzüm yağmur yıldız yürek akşam bahçe çanta çatı çiftçi diş doğum dükkan
eğlence fırsat gözlük gümüş halı ıspanak işçi kardeş kayık köfte ölçüm örgü
özlem sınav soğan şapka şemsiye şoför turşu uçurtma ütü üzüntü yağ yakıt yüzük
ağaç ağır akıllı altın ayakkabı ayrı bağ barış başlık boğaz borç büyük canlı
çelik çember çene çeviri çevre çikolata çift çizgi çorap çözüm dağcı değer
dişçi doğa doğal dolmuş düğme düğün düşük düzen eğitim gökyüzü gölge gönül
görev görsel görüş güç gül günlük güvenlik hız hücre ilaç ilişki inanç inşaat
işlem iştah kahvaltı karşı keçi keşif kılıç kışın kıyafet kıyı komşu koşu köşe
kültür kumaş mısır müze nabız öğretmen ödev öğle örnek örtü öykü özel özgür
sağlık sayı seçim sıkıntı sıfır sıra soğuk suç süre şahin şair şaka şampiyon
şart şerit şifre şiir şirket şömine şüphe tahıl tanım tarım taş tavşan yargı
yaş yaşam yayın yazılım yeğen yeşil yılan yoğurt yüz yüzme çarşamba perşembe
kırmızı üç dört altı kırk güzel yavaş hızlı üzgün kızgın açık kapalı yaşlı
genç kısa küçük çilek şeftali çatal bıçak asansör sınıf ödev aşçı aşk çay
çiçek içecek hemşire at it ot un iç o da de ki mi ne ya ve en
göz kulak burun ağız dil diş saç boy boyun kol bacak el ayak
aş aşk can canım dost dostluk sevgi sevmek sevilen sevda
iş işçi işlemek işlek iştah işte
gün gece sabah akşam öğle
su ay gaz taş toprak ateş hava ışık ses
ev evde eve evli
''';
