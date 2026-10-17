# Büyük belge ve gömülü referans performansı

Başlangıç: `8ca4286`, 2026-10-17. Kişisel dosyalar salt okunur ölçülür;
içerikleri ve mutlak yolları regresyon fixture'larına eklenmez.

## Başlangıç bulguları

- Gömülü belge örneği: 5.372 bayt, 37 blok referansı, 31 farklı hedef dosya.
  Yedi referans aynı dosyanın farklı bloklarını gösterir; tüm hedefler mevcuttur.
- Uzun belge örneği: 129.924 bayt, 807 mantıksal satır, 3.411 AST düğümü.
- Kaynak kanıtları BUG-017–023 altında kayıtlıdır. Başsız fold-dump ölçümü
  native font, sarma, gömülü dosyalar ve GPU çizimi için ölçüm değildir.

## Ölçüm yöntemi

`document_performance VAULT FILE [read|edit]` üretim Doc/Font/Rend hattını
1280×800 ve 18 px koşullarında çalıştırır; dosya yükleme ve ilk/sıcak kareleri
ayrı raporlar. GL tamamlanması da kare süresine dahildir. Özel oturum açmaz,
notları kaydetmez; işletim sistemi dosya önbelleği zorla temizlenmez.

Sayaçlar yalnız bu yürütücüde etkinleştirilir; C sınırı yalnız tahsissiz,
tek iş parçacıklı telemetri tamsayılarını tutar, algoritma/sahiplik içermez.
Bu sayaçlar aşama atfı içindir; keyfî girdiler için doğruluk ispatı değildir.

Hedefler: kullanılabilir ilk görünüm medyanı ≤500 ms; sıcak kaydırma/çizim
p95 ≤16,7 ms. Grafik ortamı ve fontlar ölçümle birlikte belirtilmelidir.

## Değişiklik öncesi grafik ölçümü

Release, Xvfb :93, 1280×800, 18 px; iki dosya ayrı süreçlerde sırayla
çalıştırıldı. Yeni süreç soğuk uygulama cache'idir, OS cache temizlenmedi.

| Örnek | Doc yükleme | İlk kare | Sıcak 1 / 2 | İlk kare shaping |
|---|---:|---:|---:|---:|
| Gömülü referanslı | 0,207 ms | 2.859 ms | 6,40 / 2,81 ms | 23.036 çağrı |
| Uzun metin | 2,98 ms | 9.639 ms | 1,26 / 1,02 ms | 88.269 çağrı |

Gömülü örneğin ilk karesi 38 çocuk belge yüklemesi, 39 sarma ve 39 görsel
indeks hazırlığı yaptı. Uzun metinde şekillendirilen toplam bayt 4.221.439'dur.
Bu tek koşunun başlangıç ölçümüdür; medyan/p95 veya gerçek GPU garantisi değildir.

## Katlama hazırlığı

Yeniden ayrıştırmada hazırlık bir kez yapılır. Bölge sahipleri tek monoton
düğüm imleciyle eşlenir; `fold_scaling_contracts` 32/256/2048 başlıkta ziyaret
sayısının düğüm + bölge sayısını aşmadığını ve sahip bayraklarını doğrular.

## Sarma: paragraf küme genişlikleri

Her paragraf bir kez analiz/shape edilir; mantıksal kaynak sırasındaki küme
advance'ları byte-indeksli prefix tablosuna aktarılır. Bidi görsel caret x'i
prefix olarak kullanılmaz. Ligatür içi kırılma engellenir; seçilen gerçek satır
yeniden şekillendirilir ve kenar birleşmesi genişliği artırırsa daraltılır.
U+2029 gibi bir fiziksel satırdaki çoklu paragraflar zorunlu sınırlarda ayrılır.

Ara ölçüm (aynı Release/Xvfb koşulları, tek koşu): gömülü örnek 263 ms /
777 shaping çağrısı; uzun örnek 534 ms / 2.415 çağrı. Başlangıca göre yaklaşık
11× / 18× daha hızlıdır. Henüz son medyan/p95 kabul ölçümü değildir.
64/256/1024 tekrar içeren karışık Türkçe/Arapça test, şekillendirmeyi satır
sayısına göre sınırlar; önceki her grapheme için yeniden ölçme yolunu reddeder.

Görünür satırın şekillendirilmiş planı Font ölçüm cache'inden VisualRows
sahipliğine aktarılır; bir miss'te bir kez üretilir. 128 yuvalı indeksli cache
satır boyama, yön, hit/caret ve seçim arasında paylaşılır. Çakışan yuva,
geçersiz font token'ı ve görünüm kapanışı eski planı serbest bırakır. Genel
font cache'i tahliye edilse de görünüm planı geçerliliğini korur; testte yeni
shaping sayısı sıfırdır. Offscreen satır planları yalnız ihtiyaçta oluşturulur.

Benchmark ilk kareyi ayrı ölçer. Yakın bekleyen işler bitirildikten sonra iki
sıcak sabit kare alınır; belge boyunca 30 konumluk ön-ısıtma turu yapılır.
Ön-ısıtmada maksimum kaydırma yeni gerçek yükseklikten tekrar hesaplanır ve
ertelenen işler konum başına tamamlanır. Ardından 60 sıcak kaydırma karesi
ölçülür: gerçek belge yüksekliğinde eşit aralıklı 30 konum, iki geçiş. Bu gerçek içerik
çizimidir; yalnız yer tutucu/boş kare ölçümü değildir. `tools/performance/summarize.py`
loglardan medyan ve nearest-rank p95 çıkarır. İlk görünüm medyanı için birden
çok ayrı süreç logu verilmelidir. Dosya yüklenemezse benchmark başarısız döner.
`prewarm_scroll` örnekleri sıcak p95'e karıştırılmaz. Geometri satırı gerçek
belge yüksekliğini, kanonik cache sayısını ve bekleyen iş durumunu da raporlar.

## Kaynak / anchor / görünüm ayrımı

Dosya cache'i 48 kanonik Doc ile sınırlıdır. Kaynak ve AST, anchor indeksi ve
parse-generation'a bağlı seyrek medya indeksi bu belgeye aittir. Layout ve
VisualRows ise ayrı `DocGeometry` sahipleridir; aynı dosya farklı anchor,
genişlik ve font bağlamları için yeniden ayrıştırılmaz. Geometri Y/yükseklik
tablosunu, görsel satırları/planlarını ve medya aux alanlarını taşır; AST kopyalanmaz.

128 görünüm ve 64 MiB geometri cache sınırı vardır. Ücretlendirme tampon
kapasiteleri, native analiz/item/glyph dizi kapasiteleri ve tahsis/kurucu başlıkları
için muhafazakâr pay içerir; paylaşılan font/Unicode varlıkları görünüm başına
tekrar sayılmaz. Seçili kaynak Doc'u ve sığan tam seçim görünümü tahliyede
korunur. Tek başına bütçeyi aşan geometri saklanmaz; geçici hesap maliyeti ayrı
olabilir. Kopyalama geometri cache'inden bağımsız kaynak izdüşümüyle çalışır.

Anchor görünümü dışında kalan satırlar şekillendirilmez ve medya çözülmez;
hedefin gerçek satır geometrisi kullanılır. Aktif kaynak yolları tipli pending
kayıtlarıyla tutulur; A→B→A ve A→A tekrar yüklemeye girmez. Derinlik sınırı 8'dir.

Regresyonlar: yedi anchor/tek parse; 240/480/300 px dönüşünde çocuk sarma cache
isabeti; 140'tan fazla farklı bağlamda 128 giriş/64 MiB sınırı; tahliyede seçim
görünümünün korunması; döngüler, eksik dosya ve dokuz seviyeli zincir. Native
grafik, anchor ve uygulama selftest paketleri geçti.

## Görünür alan ve aşamalı gömü hazırlığı

Uygulama karesi başında tek `CWork` kaydı sıfırlanır; bölünmüş paneller aynı
iş bütçesini paylaşır. Önce görünür gerçek içerik hazırlanır. Bir viewport üst
ve alt taşma payındaki cache miss'leri ilk arka plan işiyle başlayan 4 ms esnek
bütçeye tabidir. Bir atomik dosya okuma/parse/shape/driver işi bu süreyi aşabilir;
denetim işler arasındadır, sert gerçek zaman garantisi değildir.

Süresi dolmuş miss ertelenir, cache isabeti yeniden kullanılabilir. Uzak
kaynaklar yüklenmez ve bekleyen iş olarak işaretlenmez. Olay döngüsü yalnız
yakın iş kaldığında tekrar kare çizer; bitince bloke olay beklemesine döner.
Kanonik belgeyi almış fakat görünümü hazırlayamamış yol da aktif-path guard'ını
kapatıp kaynağı cache'e bırakır; döngü koruması ve sahiplik dengesi bozulmaz.

Yeni gömü ilk etapta dört satır + çerçeve payı ile tahmin edilir. Görünür
yükseklikler geldikçe görünür küme sabitlenene kadar tekrar değerlendirilir.
Kaydırma, üst kaynak satırı ve satır içi piksel ofsetiyle düzeltilir. Katlanmış
düğümler tahmine dahil edilmez; aksi halde sıfır yükseklik her kareyi kirletirdi.
Seçili kaynaktan/görünümden sonra bütçeye sığan görünür girdiler tahliyede
öne alınır; fazla/bütçeden büyük görünüm geçicidir, sert cache sınırını aşmaz.

Geometri değiştikçe yakın küme de yeniden taranır (BUG-033). Tek taşma taraması,
bir gömü kısaldığında yeni yakına giren sonraki işi kaçırabiliyordu. Yeni tur
geometri sabitlenene veya miss iş bütçesini doldurana kadar sürer; bütçede
kalan iş olay döngüsüne bildirilir. Beş kısa gömü fixture'ında ilk kare yalnız
dört yakın kaynağı hazırlar, beşinci uzak kalır; sonraki sabit karede yükleme,
sarma ve layout kurma sayaçları sıfır, belge yüksekliği değişmez.

Tıklama gerçek cache geometrisini geri yükler; tahmini satır Y'si hit için
kullanılmaz. En içteki wiki/Markdown bağlantısı dış gömü hedefinden önceliklidir.
Tıklanan kaynak kimliği/generation/stamp'i gezinme öncesi doğrulanır; sürükleme
gezinmeyi iptal eder. Regresyonlar iç içe hedef, aynı-dosya anchor'ı ve dış URL
çözümlemesini URL'yi gerçekten açmadan sınar.

## Paragraf analizinin satırlar arasında paylaşılması

VisualRows, yalnız görünüm kapsamındaki fiziksel satırların normalize Unicode
analizini tutar. Sarılmış satır, EGC hizalı kaynak penceresinden yerel ofsetli
bir analiz görünümü üretir; NFC/script/bidi çözümlemesi tekrarlanmaz. Paragrafın
çözülmüş seviyeleri ve tabanı korunur, satırda mevcut L1/reset ve görsel sıra
motoru kullanılır. Bu ayrım [UAX #9, bölüm 3.4](https://www.unicode.org/reports/tr9/#Reordering_Resolved_Levels)
satır düzenleme modeline dayanır; satırı bağımsız AutoLtr paragraf saymak değildir.

Paragraf ve satır planları ayrı lineer sahiplidir; pencere verisi kopyalanır,
sahip alias'ı oluşturulmaz. Kapasite ücretleri cache bütçesine dahildir ve
toplamlar O(1) saklanır. Kesin satır planı ölçümden boyamaya doğrudan geçer;
tahliye sonrası aynı paragraf analizinden yeniden üretilir.

Ara ölçüm: uzun örnekte ilk kare 478 ms, 60 kaydırma karesinde p95 5,58 ms.
Bu tek koşu sonucudur; son kabul medyanı ve profil testleri ayrıca raporlanır.

## Sanitizer sınırı ve tekrar çalıştırma

`cmake -S . -B build/refactor-asan -DCMAKE_BUILD_TYPE=RelWithDebInfo -DANTHRACITE_SANITIZERS=ON`
ile ASan+UBSan etkinleştirilir. `font_render_conformance`,
`native_text_analysis_conformance` ve `anchor_contracts` hedefleri ayrıca derlenir.
Grafik test için geçerli X11/GLX ve DejaVu Sans Mono gerekir; bu Nix ortamında
GLX yükleyicisi `LD_LIBRARY_PATH=/run/opengl-driver/lib` gerektirebilir.
Son ölçüm ve testlerde bu sürücü yolu bütün profillere açıkça verilir;
profil karşılaştırmasında GLX ortamı değiştirilmez.

`ASAN_OPTIONS=detect_leaks=1` ile CPU analiz/anchor testleri ve grafik suite'i
ayrı çalıştırılır. Grafik suite'inde LSan, `mem_live` dışında kalan boxed
yardımcı tahsislerini görünür yaptı (BUG-032). Partition, paint/hit/graph,
cmap ve font metadata kutulaması kaldırıldı; geçici metin, SFNT, compound ve
feature sonuçları lineerleştirildi. Metrik/gezinme sonuçları ve fixture
listeleri de tüketilir. Son BUG-032 grafik doğrulaması sızıntı denetimi açıkken
geçti; ayrıntılar [çalışma kaydındadır](refactoring_durumu.md).
`detect_leaks=0` yalnız erişim/UB testi için kullanılabilir; bu koşunun
başarısı sızıntısızlık olarak raporlanmaz. Hiçbir toplu LSan suppression eklenmedi.

Grafik oracle aynı 640×480 piksel uzayını kuyruk özyinelemeli tarar; Debug'ta
yığın taşmasına yol açan dönüşte toplama kaldırıldı (BUG-031). Genişletilmiş
suite için Debug/sanitizer zaman aşımı 600 s, Release 100 s'dir. Bu test süre
sınırı, uygulamanın Release ilk görünüm/kaydırma kabul hedefi değildir.

## Son kabul ölçümü — 2026-10-17

Release (-O2/LTO), Xvfb/GLX :94, Mesa 26.1.8, 1280×800, 18 px, `read`
izdüşümü. Ana font depodaki Source Code Pro, Arapça fallback depodaki Noto
Naskh Arabic. Her örnek beş ayrı süreçte, sırayla çalıştırıldı; derleme/test
yükü aynı anda çalıştırılmadı. OS dosya cache'i zorla temizlenmedi.

| Örnek | Doc yükleme medyanı | İlk kare medyanı | Yükleme + ilk kare medyanı | Sıcak kaydırma p95 |
|---|---:|---:|---:|---:|
| Gömülü referanslı | 0,137 ms | 45,037 ms | 45,171 ms | 3,023 ms |
| Uzun metin | 1,510 ms | 468,977 ms | 470,806 ms | 5,032 ms |

İlk karede beşer örnek, sıcak kaydırmada örnek başına 300 gerçek içerik karesi
vardır. Yükleme + ilk karenin gözlenen en yüksek süreleri 46,234 / 478,528 ms;
iki dosya da 500 ms ilk kullanılabilir görünüm ve 16,7 ms sıcak kaydırma p95
hedefini bu ortamda karşılar. Font/Unicode varlıklarının uygulama açılışındaki
hazırlanması bu belge-açma ölçümüne dahil değildir; GL tamamlanması ve swap dahildir.

Başlangıç ilk kare tek koşuda 2.859 / 9.639 ms idi; son ilk kare medyanlarıyla
yaklaşık 64× / 21× fark vardır. Başlangıcın tek koşu olduğu unutulmamalıdır.
Bu Xvfb sonucu gerçek masaüstü GPU'sunda veya her dosyada aynı süre garantisi değildir.

Gömülü örnekte ilk kare on hedef Doc hazırlar; tam tur sonunda 31 kanonik
kaynak cache'tedir. Beş koşunun sıcak kaydırma karelerinde belge yükleme,
AST ayrıştırma, medya indeksi, sarma ve layout kurma sayaçları sıfırdır.
Yakın işler tamamlandıktan sonraki sabit karelerde de yeniden layout/sarma yoktur;
sabit kare medyanları 2,855 / 1,008 ms'dir. Ön-ısıtma kareleri bu istatistiklere
karıştırılmadı. Not dosyaları salt okunur kullanıldı; içerikleri fixture'lara taşınmadı.

Doğrulama: Release ve Debug profillerinde ayrı ayrı 265/265 CTest geçti.
ASan+UBSan erişim/UB denetimi
grafik/Unicode analiz/anchor paketlerinde 3/3 geçti (`detect_leaks=0`). CPU
analiz/anchor paketleri ayrıca sızıntı denetimi açıkken 2/2 geçti. Grafik
Bu performans kabul anında grafik LSan BUG-032 nedeniyle kırmızıydı:
45.601 tahsiste 363.280 bayt kayıp raporladı. Sonraki BUG-032 düzeltmesinde
aynı grafik suite'i `detect_leaks=1` ile geçti; bastırma eklenmedi.
Ayrıntılı doğrulama geçmişi [çalışma kaydında](refactoring_durumu.md) tutulur.
