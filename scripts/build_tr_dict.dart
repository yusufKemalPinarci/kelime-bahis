import 'dart:io';

/// Build-time: kaynaktan 2–8 harfli TR kelimeleri çıkarır + seed birleştirir.
///
/// Kullanım:
///   dart run scripts/build_tr_dict.dart [kaynak.txt]
///
/// Blocklist her uzunlukta elenir. Min uzunluk 2 (daha kolay giriş kelimeleri).
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

  final source = File('assets/dictionary/source/turkish_words_raw.txt');
  if (source.existsSync() && args.isEmpty) {
    for (final line in await source.readAsLines()) {
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
  for (final sample in ['çay', 'su', 'ev', 'aşk', 'kısa', 'elma', 'kitap', 'bh']) {
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

/// Yaygın Türkçe — kaynak eksik olsa bile düşmesin.
const _seedWords = '''
ada ama ana ara ayak ayna baba bebek beyaz bilgi birlik buz cadde cam can deniz
ders dil dilek dost duvar ekmek elma emek fener gemi gece haber hava hayal
hikaye inek ipucu kalem kale kar kedi kent kitap kulak kutu lale limon lira
masa mavi mektup meyve mutfak nehir nokta ocak orman otel oyun pamuk para park
pembe pilav saat sabah sahil sakız sevgi simit sokak tabak tatlı tepe toprak
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
domates soğan patates elma armut muz portakal kayısı erik karpuz kavun süt
çay kahve ayran limonata bardak tabak kaşık tencere tava fırın ocak oda
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
çiçek içecek hemşire
göz kulak burun ağız dil diş saç boy boyun kol bacak el ayak
aşk can canım dost dostluk sevgi sevmek sevilen sevda
işçi işlemek işlek iştah işte
gün gece sabah akşam öğle
gaz taş toprak ateş hava ışık ses
evde eve evli
bonus mağaza kaybetmek günlük çarpan
anlam anlamak anlatı anlatmak anılar anımsamak
atıcı atılım atış ayırt ayırmak ayrılık
bağış bağlamak baharat bakış bakmak balıkçı banka
baraj başarmak başkan başkent başlangıç başlamak
beklemek bellek belki beyin bildiri bilgisayar bilim
bilmek binmek bitirmek bitki boşluk boya bölge börek
buzdolabı cazibe ceket ceza ceviz çekmek çevirmek
çıkarmak çıkış çizmek çocukluk çözmek dalga dalgıç
damla davet dayanmak değerli değişmek delik demir
deney deneyim derinlik destek detay dikkat dilbilim
dilemek dinlemek dolap dolmak dönmek dönüş duygusal
düşmek düşünmek düşünce düzeltmek ebeveyn efsane
eğilim eğitmek ekonomi elektrik elektronik eldiven
emekli emniyet endüstri enkaz esinti esnek eşya
etiket etki fikir flama formül fotoğraf fırtına
galeri garaj geçmek gelişmek gerçek gerçeklik
getirmek giymek gizemli göndermek gönüllü görünmek
göstermek hafıza hakikat hamle hareket harita hasat
hatıra havuz hazırlık hediye hesap heyecan hizmet
hissetmek hukuk ılık ışıldak ıslak icat içermek
içmek ikilem ilerlemek iletişim ilham ilkbahar imza
incelemek indirim insan istemek işaret işletme
itibar itiraz izin jeton jilet kabuk kaçmak
kadife kahraman kalabalık kalıcı kalmak kampanya
kanat kapamak kaplan karar karışmak kasaba katılmak
kavga kaymak kazanç kelebek kemer kenar kestirmek
kılavuz kıvılcım kızarmak kilit kimya kişilik
kitaplık klasik koku koltuk komedi komutan konum
konuşmak kontrol koridor koşmak korkmak korku
koşul kredi kristal kurmak kurulum kuşak kutlamak
kuvvet kuyruk kuzey kürk laboratuvar lahana liman
lisan madde makine mantık maraton marul masal maske
mecaz mekan melodi merak merkez mesafe meslek metal
metre mezarlık mikrop mimar mimari minik model
modern molekül mücadele mümkün müthiş müzisyen
neden nesil netice nişan nöbet numune odun okyanus
olası olanak onarmak onaylamak operasyon ortak
oturmak oymak oyuncu ödeme öğrenmek öğüt öksürük
ölçmek ölçüt önermek öpücük örgüt örme özetlemek
paketlemek paraşüt parlamak parmak peçete pelikan
petek peyzaj pilot planlamak porselen portre poster
proje psikoloji pürüzsüz rahat rakam rakip rapor
reçete reklam renkli restoran ritim robot rota
sabır sabırlı sağanak sahne saklamak sanat sanatçı
sarımsak satmak savaşmak sayfa saygı saymak sebep
seçmek seçenek sefer seminer senaryo seramik sergi
seslenmek seyirci sıcaklık sıkılmak silah silmek
simetri sistem sohbet sokmak soluk sonsuzluk sorun
söylemek sözcük sözlük sporcu sunmak sürgün sürpriz
şafak şakacı şanslı şarap şarkıcı şaşkın şekerli
şifalı şiirsel şişirmek şüpheci taban tabiat
tabure tahin takmak taklit tamamlamak tanımak
tanışmak tartışmak tatil tatmak tehlikeli teknoloji
temas tembel temizlemek teori terazi tercih
teslim teşvik ticaret tırmanmak titremek toplantı
trafik turuncu tutmak tutku tuvalet uçmak uçuş
uyanmak uyarmak uygulamak uymak uzaklaşmak uzunluk
ücretsiz üflemek ümit ünlü üretmek üstün ütülemek
vakit varmak vasiyet vekil veri vermek vicdan
vizyon yabancı yağlamak yakalamak yaklaşmak yanmak
yaratmak yardım yaşamak yatırmak yazmak yeniden
yenmek yerçekimi yetişmek yetenek yırtmak yıldırım
yıkanmak yolculuk yorumlamak yönetmek yükselmek
yüklemek yüzmek zabıt zambak zafer zanaat zarar
zevk zihin zincir zorlamak zorluk zümrüt

internet teknoloji donanım ekran klavye fare yazıcı kamera kablo şarj
pil uygulama sosyal medya video dijital veri sunucu program kod robot
yapay mutluluk endişe kıskanç gurur utanç pişmanlık sabır cesaret
dürüstlük sadakat nezaket kibarlık cömertlik cimrilik tembellik
şimşek gürültü deprem sel çöl kıta gezegen evren dolu sis buğu çiy
kalp akciğer böbrek mide bağırsak damar kas kemik deri tırnak kirpik
kaş alın çene dirsek bilek topuk döner baklava lokum poğaça mantı
dolma sarma şerbet komposto reçel bal tereyağı yumurta voleybol
güreş boks satranç avukat mühendis terzi kuaför mimar hem ise ile
gibi kadar sonra önce hala hiç çok biz siz sen kim nasıl neden niye
evet hayır tamam lütfen merhaba selam

vur gel git gör bil bak dur koş sor ver çık gir
otur kalk oku sil çiz kes dök bin sat sev gez
düş geç döv öp sık çek yat dinle izle oyna taşı
sür tut bırak kapat kapa pişir yıka kurut süpür
topla dağıt böl çarp öde harca kazan bul ara
gönder getir götür indir bindir başla bitir dene
çalış dinlen uyu uyan ağla bağır konuş sus anlat
düşün hatırla unut öğren öğret boya yapıştır kır
ört yükle paylaş beğen yorumla kaydet değiştir
seç karıştır çevir dön yüz dal batır tırman atla
yürü bekle yavaşla hızlan gülümse sıkıl üzül
korkut şaşır sevin

bu şu ne ol su ev et al at ay az an av iz iç ip iş
ki mi mı mu mü on ok öz ön ün ve ya ye ad af ah üç de da
''';
