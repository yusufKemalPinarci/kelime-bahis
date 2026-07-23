# -*- coding: utf-8 -*-
from pathlib import Path

allowed = set("abcçdefgğhıijklmnoöprsştuüvyz")

# Günlük Türkçe (3–8 harf) — yaygın kelimeler
raw = """
ada ama ana ara ayak ayna baba bebek beyaz bilgi birlik buz cadde cam can deniz ders dil dilek dost duvar ekmek elma emek ev fener gemi gece haber hava hayal hikaye inek ipucu kalem kale kar kedi kent kitap kulak kutu lale limon lira masa mavi mektup meyve mutfak nehir nokta ocak orman otel oyun pamuk para park pembe pilav saat sabah sahil sakiz sevgi simit sokak su tabak tatli tepe toprak tuz umut usta uyku vadi vapur vazo vergi yaprak yatak yazi yelken yemek yol zaman zarf zeka zengin zeytin zil
aile armut asker bakkal balkon benzin berber bisiklet bulut dakika davul defter demlik eczane elbise enerji fabrika futbol gazete hamam hastane helva ibrik iplik kahve kamp kanepe kavanoz kebap kilim kira klima lamba lastik lavabo lokanta madalya makarna manav mantar market mendil merdiven minare motor muzik nane nar nazar numara okul olta omuz paket palto pantolon pastane pencere perde pizza pazar radyo raf renk resim roman salata sandalye saray savas sebze semt sevda sigorta silgi sinema spor tablo takim tamir taksi telefon terlik tohum tren vagon valiz vitrin zemin zirve
ambar anahtar anne araba aslan avukat baharat banka banyo basamak beden belge bellek biber bilet bilim bitki bodrum bomba boya cami ceket dalga damla dans demir denge deney depo deprem dergi deri destek deve devlet dikey dilim diploma direk direnc dolap domates dondurma dosya eczane ekip ekonomi elektrik emanet emek engel erzak esnaf esya etiket etki faiz fark fasulye fayda film fizik galeri gecit gelenek gelisim gezi gida gitar grup hafta hak hakem halk hareket harf harita hasta hat hayvan hayat hazir hedef hekim hesap heyecan his hukuk ibadet ikram ilan ilerleme ilgi ilham imam imza ince indirim iplik irade isim isyan izin kahraman kalite kalp kamera kaptan kargo kasa kasaba kasap kavga kavun kaynak kayit kazak kazan kelime keman kemer kenar kesin keyif kilo kimya kiraz koca kol kolay koltuk kombi konu konser konuk korku kriz kule kum kural kurt kuzey lamba lezzet liman lise litre macera madde maden mahalle makine malzeme manzara marka masal matematik maymun meclis melodi memur menu merkez meslek metro mezar midye misafir moda model mum nabiz nakit namaz neden nefes nesil nisan niyet normal oda odun ofis olay onur ordu orta ortak oyuncu patates petrol plan plaj polis portakal posta proje puan randevu restoran risk robot rota sabun saha salon sanat sayfa sebep sefer sevgili seyirci silah sistem site sol sonuc soru sosyal spor sultan taban tahmin takvim talep tarak tarih tarla teknoloji temel tesis tip ticaret torba trafik tur tutku ufak ufuk ulus un usul uyari uzman uzun vakit verim vizyon yaka yalan yamac yan yapi yardim yasa yayin yazar yedek yeni yetenek yiyecek yolcu yorgan yorum yorgun zafer zar zincir ziyaret zor zorluk
anne baba kardes dede nine amca teyze dayi hala cocuk bebek kiz erkek adam kadin doktor polis asker ciftci isci usta sofor garson
ekmek peynir zeytin domates sogan patates elma armut muz portakal kayisi erik karpuz kavun
su sut cay kahve ayran limonata bardak tabak kasik tencere tava firin ocak
ev oda salon mutfak banyo balkon pencere kapi duvar tavan zemin merdiven bahce sokak cadde mahalle semt sehir koy
araba otobus tren metro vapur ucak bisiklet motor taksi kamyon
okul ders sinav kitap defter kalem silgi canta
futbol tenis saha top raket
muzik dans film konser radyo telefon
yaz kis gun ay yil hafta dakika saat
pazartesi sali cuma pazar
mavi sari beyaz gri pembe
bir iki bes on yirmi otuz elli
mutlu yorgun temiz kirli sicak soguk genc uzun
balık başarı çocuk çorba dağ doğru dünya fırın göl güneş güzel hızlı ırmak ışık kapı köprü köy kuş neşe öğrenci ördek rüya rüzgar sarı sıcak süt şarkı şehir şeker şişe uçak üzüm yağmur yıldız yürek akşam bahçe çanta çatı çiftçi diş doğum dükkan eğlence fırsat gözlük gümüş halı ıspanak işçi kardeş kayık köfte ölçüm örgü özlem sınav soğan şapka şemsiye şoför turşu uçurtma ütü üzüntü yağ yakıt yüzük ağaç ağır akıllı altın ayakkabı ayrı bağ barış başlık boğaz borç büyük canlı çelik çember çene çeviri çevre çikolata çift çizgi çorap çözüm dağcı değer dişçi doğa doğal dolmuş düğme düğün düşük düzen eğitim gökyüzü gölge gönül görev görsel görüş güç gül günlük güvenlik hız hücre ilaç ilişki inanç inşaat işlem iştah kahvaltı karşı keçi keşif kılıç kışın kıyafet kıyı komşu koşu köşe kültür kumaş mısır müze nabız öğretmen ödev öğle örnek örtü öykü özel özgür sağlık sayı seçim sıkıntı sıfır sıra soğuk suç süre şahin şair şaka şampiyon şart şerit şifre şiir şirket şömine şüphe tahıl tanım tarım taş tavşan yargı yaş yaşam yayın yazılım yeğen yeşil yılan yoğurt yüz yüzme çarşamba perşembe kırmızı üç dört altı kırk güzel yavaş hızlı üzgün kızgın açık kapalı yaşlı genç kısa küçük çilek şeftali çatal bıçak asansör sınıf ödev aşçı aşk çay çiçek içecek hemşire
sakız savaş çayır çilek çoban çorba düşün dünya düzen ekşi enişte eşya fırtına fıstık gömlek gölgelik gümüş gürültü haberleşme haftalık haklı hapishane harika hatıra hayvanat hediye hesaplı hiçbir hikaye hi̇çbir ırmak kenarı işlemez jilet kahramanlık kalabalık kamyonet karanlık kardeşlik kavanoz kayısı kelebek kenarlık kerpiç kestane kıymetli kibrit kimlik kirazlı kitaplık klima koltuklu komşu korkuluk köfteci köpek köprücük köylü kurabiye kuşak kuyumcu kültürlü labirent lezzetli limonata liralık lokum macun mahalleli makas mantıklı marketçi mektupçu mendilli merdiven metroya meyveli mısırlı midyeli minareli motorlu müzikli nazarlık nedense nehirde ninemiz notlar numara oduncu okullu oltalı ormanda otelde oyuncak öğrenci öğretmen ölçü ördekli özelik paketçi pamuklu pantolon parkta pastane patlıcan pazarda pencere perdede petrolü pilavlı pizzacı planlı plajda polisin portakal postacı projeli puantaj radyolu raftaki randevu renkli resimli restoran robotik romanlı rotası rüzgarlı sabahlık sabunlu sağlıklı sahilde salatalık sandviç sanatçı sandalyede sarımsak savaşçı saygılı sebzeli seçmen seferli sevgili seyirci sıcaklık sıkıntılı sıradan sigortalı silahlı simitçi sinemada sistemli soğukluk soğanlı sokakta soluklu sonuçlu sorumlu sosyal sporcu sultanlı süreğen şarkıcı şehirli şekerli şemsiye şirketli şişelik şoförlük tabaklık tabure tahinli takımlı takvimli talepli tamirci tanıdık tarakla tarımda tarihli tavuklu tehlikeli teknoloji telefon televizyon temizle tepelik tesisat tipik ticaret tohumluk torbalı trafik trenlik tuzluluk turistik tutkalı uçaklı uçurtma ufacık ufkumuz ulusal umutlu unutulmuş usulüne uyanık uykucu uzmanlık uzunluk ülkeler ümitli ünlüler üniversite ürünler ütücü üyeler vadide vagonlu vakitli valizli vapurda vazolu vergili verimli vitrin vizyon yağmurlu yakıtlı yalanlı yamaçta yangın yapısal yargılı yardımcı yasalı yaşam yayında yazılı yazarlık yazılım yedekli yeğenli yeşilli yemekli yenilik yetenek yılanlı yıldızlı yiyecek yoğurtlu yolculuk yorganlı yorumlu yorgunluk yürekli yüzükler zaferli zamanlı zarflık zekalı zeminli zengin zeytinli ziller zincirli zirvede ziyaret zorunlu
"""

words = set()
for w in raw.split():
    w = w.strip().lower().replace("i̇", "i")
    if 3 <= len(w) <= 8 and all(c in allowed for c in w):
        words.add(w)

out = sorted(words)
path = Path("assets/dictionary/tr_words.txt")
path.write_text("\n".join(out) + "\n", encoding="utf-8")
print(len(out))
print(out[:15])
