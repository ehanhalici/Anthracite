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

## Ölçüm altyapısı gözden geçirmesi — 2026-11-17

Önceki turdaki telemetri (alt-faz zamanlayıcıları, GL/bellek sayaçları,
SIGPROF örnekleyici, `map_c_to_ats.py`) incelendi; dört ölçüm hatası düzeltildi.
Araçların kullanımı [tools/performance/README.md](../tools/performance/README.md)
içindedir.

| Sorun | Etki | Düzeltme |
|---|---|---|
| Kaydırma örnekleri her karede `max/29` px (~3 ekran) atlıyordu | "Kaydırmada kare başına 37 shape, 4,8k tahsis" bulgusu bu desenin ürünü; 30 konum × ~42 satır, 128 slotlu `VisualPlans`'a sığamaz | `jump` / `wheel` (uygulamanın 48 px tekerlek adımı) / `page` senaryoları |
| Kare süresi `glFinish` + swap içeriyordu | NVIDIA'da VBlank beklemesi `glFinish` içinde; tüm kareler ~16,6 ms | `cpu_ns` / `gpu_wait_ns` / `swap_ns` ayrımı |
| `addr2line -f` satır içi kodu en içteki inline fonksiyona yazıyordu | `atspre_g0int_*`, `buf_get` "sıcak fonksiyon" görünüyordu; ikilide bu semboller yok | `addr2line -i`, en dıştaki gerçek fonksiyon |
| Süreç geneli `ITIMER_PROF`, 16 kare derinlik, faz etiketi yok | Sürücü iş parçacıkları ve `glFinish` meşgul-beklemesi profili boğuyordu; ilk kare ile kaydırma karışıktı | Ana iş parçacığı CPU zamanlayıcısı, 64 kare, `--tag first/scroll/...`; `glFinish`/swap etiketsiz |

Ek olarak: deterministik fixture üreteci (`gen_fixture.py`, 87 KB / 1296 satır),
20 tekrarlı arama benchmark'ı (`live_delta` sızıntı kontrolü), faz bazlı
`summarize.py --json/--compare` ve sayaç bütçeli `performance_budgets` CTest'i
(süre değil iş sayaçları; ekran yoksa Xvfb, o da yoksa SKIP). Selftest artık
`/tmp/anthracite-selftest-*` dizinini çıkışta siler (`ANTHRACITE_KEEP_SELFTEST_DIR`
ile korunur); önceki koşulardan 123 artık dizin birikmişti.

### Sonuçlar (5 taze süreç medyanı, 1280×800, 18 px, NVIDIA GLX, VSync açık)

Release = `-O2 -flto=thin -march=native` + `-g -fno-omit-frame-pointer`.
Süreler `cpu_ms` (çizim + `rend_flush` gönderimi); duvar saati her senaryoda
p95 ≈ 16,7 ms (VSync).

| Senaryo (read) | Debug ilk kare | Release ilk kare | Debug kaydırma med / p95 | Release kaydırma med / p95 | shape/kare med / p95 | tahsis/kare p95 |
|---|---|---|---|---|---|---|
| jump | 372 ms | 165 ms | 5,04 / 6,38 ms | 2,15 / 2,69 ms | 34 / 37 | 4284 |
| wheel | 363 ms | 164 ms | 0,35 / 0,95 ms | 0,17 / 0,46 ms | 0,5 / 4 | 464 |
| page | 366 ms | 167 ms | 4,74 / 5,62 ms | 2,12 / 2,73 ms | 33 / 35 | 4016 |

Edit modu her satırda Read ile ±%3 içindedir. Boşta kare: 0,28 / 0,15 ms CPU,
0 shape, 12 tahsis. Arama (50 not, 41 KB, 20 tekrar): 2,23 / 1,21 ms,
koşu başına 1080 tahsis, `live_delta=0`.

İlk kare Release profili (`--tag first`, inline düzeltmeli):
`visual_wrap_fill` %96 → `font_text_line_plan`/`font_span_fill` (OpenType
GSUB/GPOS) %70, `font_text_paragraph_analysis` (Unicode/normalizasyon
analizi) %24. En yüksek self: `unicode_property.dats` `property_value` %8,7,
`normalization_row.dats` `search` %6,4, `unicode_db.dats` `properties` %3,5,
GPOS grafik yürüyüşü (`glyph_position_lookup_graph_*`) ~%10.

### Öneriler (yeniden sıralı)

1. **İlk kare: görünür bölgeyi önce sar** — 87 KB notta ilk kare Release'de
   ~160 ms, tamamı `visual_wrap_fill`'in 1296 satırı tek seferde şekillendirmesi.
   Görünür satırlar + overscan kesin şekillendirilip geri kalanı tahminî yükseklikle
   başlatılmalı, `cache_work` bütçesiyle karelere yayılmalı. En büyük kazanç.
2. **Unicode özellik aramaları için doğrudan tablo** — ilk karenin ~%19'u ikili
   arama (`property_value`, normalizasyon satırı, `unicode_db`). U+0000–U+07FF
   (Latin/Türkçe/Arapça temel bloklar) için düz dizi; NFC hızlı kontrolü (ASCII
   ve "quick check = yes" aralıkları) normalizasyonu tamamen atlatır.
3. **Shape-plan / kelime önbelleği** — aynı (font, script, dil, özellik) için
   `native_text_shape_plan.dats` planı her item'da yeniden kuruluyor; tekrar eden
   kelimeler için (metin, stil) → glif dizisi önbelleği ilk kareyi ve jump/page
   kaydırmayı birlikte düşürür.
4. **`VisualPlans` boyutu ikincil öncelik** — tekerlek kaydırmasında kare başına
   medyan 0,5 shape, Release p95 0,46 ms CPU: 128 slot normal okuma için yeterli.
   Kaydırma çubuğu sürükleme / PageDown'da (33–34 shape, ~2,1 ms Release)
   bütçe hâlâ 16,7 ms'nin çok altında; slot artırmak yerine öneri 1 ve 3 bunu da
   çözer.
5. **GL flush** — ilk karede 74 atlas yüklemesi 91 flush üretiyor; boşta ve
   kaydırmada 14–20 flush/kare `ShadeSolid ↔ ShadeAlpha` geçişlerinden. Atlas
   yüklemelerini karenin başında toplu yapmak ve düz dolguları ayrı geçişte
   çizmek; CPU maliyeti şu an küçük (`rend_flush` ~1 ms ilk kare).
6. **Sürücü beklemesi** — uygulama `glFinish` çağırmıyor (iyi); benchmark çağırıyor
   ve NVIDIA bunu meşgul-bekleme ile yapıyor. Uygulamada `glXSwapBuffers`'ın da
   çekirdek yakıp yakmadığı `__GL_YIELD=USLEEP` ile karşılaştırılarak ölçülmeli.

Raporun önceki "Debug'da `buf_get`/prelude çağrı yükü %6,5" ve "kaydırmada
128-slot çakışması" bulguları ölçüm hatası olarak geri çekildi; aramada ASCII
hızlı yolu önerisi geçerli ama öncelik düşük (50 notta 1,2 ms).

## Görünür bölge önce sarma (visible-first wrap) — 2026-11-18

Öneri 1 uygulandı. 4 KB'tan büyük üst düzey belgeler (gömülü olmayan,
`doc_embed_level = 0`) artık ilk karede yalnızca görünür bandı şekillendiriyor:

- `visual_layout_prepare_deferred` anahtar eskiyse satırları şekillendirmeden
  kurar. Her satır için tüm satırı kapsayan tek bir yer tutucu satır yazılır
  (`width = VISUAL_ROW_PENDING_WIDTH = -1`). `doc_visual_line_rows` bu satırlar
  için 0 döner, böylece layout karakter sayısına dayalı tahmini kullanır.
- `visual_layout_prepare_band` layout yapar, görünür alanın yarım ekran üstü ile
  yarım ekran altı arasındaki bekleyen satırları şekillendirir ve bant
  oturana kadar yeniden layout yapar (en çok 4 tur).
- `visual_layout_background` her karede 6 ms bütçeyle önce bandın altını, sonra
  üstünü şekillendirir. İş kaldıkça `cache_work_pending` doğru döner ve olay
  döngüsü bir sonraki kareyi hemen çizer.
- Satırlar yerinde değiştirilir (`visual_wrap_lines`): değişmeyen satırlar blok
  kopyalanır. Kaymış satır indekslerine ait plan önbelleği
  `visual_plans_forget_from` ile atılır.
- Kaydırma, mevcut anchor mekanizmasıyla (`work_top` = anchor satırının y'si +
  ofset) sabit kalır. Üstteki satırların yüksekliği değişse de görünen satır
  yerinden oynamaz. Arama sonucuna atlama (`pending_anchor_scroll`) de hedef
  satıra bağlı bandı kullanır.
- Yazı tipi yüzleri ilk şekillendirmede tembel yüklenir. Bu yüzden şekillendirmeden
  sonra anahtar tazelenir (`rekey`). Tazelenmezse ilk karede iskelet iki kez
  kurulur ve Arapça fallback yüklenince arka plan işi baştan başlar.
- Klavyeyle dikey gezinme, imleç satırının ±8 satırını şekillendirir.

Sonuçlar (fixture, 5 süreç medyanı, CPU):

| | Debug önce → sonra | Release önce → sonra |
|---|---|---|
| İlk kare | 363–372 → 26 ms | 164–167 → 14 ms |
| Arka plan karesi (medyan / p95) | — / — → 11,4 / 12,4 ms | — / — → 9,0 / 9,7 ms |
| Arka planın bitmesi | — → ~54 kare | — → ~26 kare (~0,43 s) |
| Tekerlek kaydırma p95 | 0,95 → 0,91 ms | 0,46 → 0,47 ms |
| Boşta kare | 0,28 → 0,27 ms | 0,15 → 0,15 ms |

İlk karede şekillendirilen satır sayısı 1296'dan 13'e, shape çağrısı 824'ten 40'a,
tahsis sayısı 173 bin'den 111 bin'e indi. Doğruluk testi `deferred_rows_match_full`
(`tests/workspace/visual_layout_cases.dats`): arka plan bittikten sonra satırlar ve
layout yüksekliği tam senkron sarma ile birebir aynı. `performance_budgets` yeni
sınırlarla güncellendi (ilk kare `wrap_lines ≤ 16`, arka planda `wrap_builds = 0`).

Kalan maliyetler ve sonraki adımlar:

- İlk karedeki kalan ~14 ms'nin çoğu iki tam layout geçişi (~2,7 ms × 2) ve
  belge boyu projeksiyon (`visual_projection_make`). Layout'un artımlı olması
  (yalnızca değişen satırdan sonrasını yeniden hesaplamak) hem ilk kareyi hem
  arka plan karelerini düşürür.
- Arka planın toplam CPU'su (~26 × 9 ms) eski tek seferlik sarmadan (165 ms)
  fazla, çünkü her arka plan karesi layout'u baştan yapıyor. Artımlı layout bunu
  da çözer.
- Önceki listedeki öneri 2 (Unicode tablo) ve 3 (shape-plan önbelleği) artık arka
  plan süresini ve sıçrama/PageDown kaydırmasını hedefliyor.

## Artımlı layout — 2026-11-18

Arka plan karelerinin her biri layout'u baştan yapıyordu (Release'de ~2,7 ms). Artık:

- `visual_wrap_lines` şekillendirdiği satır aralığını döndürüyor.
  `doc_layout_mark_rows` bu aralığı layout kaydına "kirli" olarak yazıyor
  (`LH_DIRTY0/1`). Belge sürümü ve layout anahtarı değişmiyor.
- `doc_layout_mode` anahtar eşleşirken kirli aralık varsa `doc_layout_update`
  çalıştırıyor:
  - yalnızca kirli satırların adımını yeniden hesaplıyor;
  - sonraki satırların y'sini kaydırıyor;
  - sonu ilk kirli satırdan sonra biten düğümleri yeniden damgalıyor;
  - görsel indeksi yeniden kuruyor.
- `doc_layout_ast_prepare` (katlama, görünürlük, widget yükseklikleri) atlanıyor,
  çünkü bunlar yalnızca belge sürümüne bağlı. Tam layout `layout_builds`
  sayacına, artımlı layout yeni `layout_updates` sayacına yazılıyor.
- `deferred_rows_match_full` testi artık her satırın y/adım değerini ve her
  düğümün y/yükseklik değerini de tam layout ile karşılaştırıyor; fark yok.

Release, fixture, 5 süreç medyanı:

| | Önce | Sonra |
|---|---|---|
| İlk kare CPU | 13,8–15,2 ms | 11,9–13,0 ms |
| Arka plan karesinde layout | 2,7 ms | 0,46 ms |
| Arka plan karesi (medyan / p95) | 9,0 / 9,7 ms | 6,9 / 7,5 ms |
| Arka planın toplam CPU'su | ~234 ms | ~180 ms |
| Arka plan kare sayısı | ~26 | ~26 (6 ms şekillendirme bütçesi sınırlıyor) |

İlk karenin kalan ~12 ms'si: tam layout ~2,7 ms, ilk artımlı geçiş ~0,8 ms,
projeksiyon ve iskelet ile bant şekillendirme ~4,2 ms; kalanı medya bağlama,
çizim ve flush.

## Unicode doğrudan tablolar — 2026-11-18

Önceki listedeki öneri 2 uygulandı. Yüklenen üç tablo türü (9 özellik haritası,
grafem veritabanı, normalizasyon satırları) doğrulamadan sonra U+0000–U+07FF
için bir doğrudan tablo kuruyor (`UNICODE_DENSE_SCALARS = 2048`, tablo başına
8 KB, toplam ~88 KB). Tablo verinin sonuna, aynı tampona ekleniyor; bu aralıktaki
arama tek okumaya iniyor, diğer kod noktaları ikili aramaya devam ediyor.
`property_dense_match`, `unicode_properties_dense_match` ve
`normalization_dense_match` 2048 kod noktasının tümünde tabloyu ikili aramayla
karşılaştırıyor (`line_contracts` ve `normalization_contracts`:
`dense_errors=0`).

Release, fixture, 5 süreç medyanı:

| | Önce | Sonra |
|---|---|---|
| Arka plan kare sayısı (çalıştırma başına) | ~26 | ~21 |
| Sıçrama/PageDown kaydırma CPU (medyan / p95) | 2,2–2,3 / 2,7–2,9 ms | 2,0 / 2,4–2,6 ms |
| İlk kare | 11,9–13,0 ms | 11,3–12,3 ms |
| Arama (50 not) | 1,24 ms | 1,22–1,28 ms (değişmedi) |

`property_value` arka plan profilinde %6,2 self süreden ~%1,4'e indi.

Denenip geri alınan: NFC birleştirmesinde ikinci kod noktası birleşemiyorsa çift
aramasını atlayan bir bayrak tablosu. Ölçülebilir fark çıkmadı (profildeki %4,2
yalnızca 6 örnekti), bu yüzden eklenmedi.

Kalan şekillendirme maliyetinin çoğu OpenType GSUB/GPOS yürüyüşünde
(`glyph_substitution_step`, `ot_coverage_index`, GPOS grafiği) ve özellik kümesi
sıralamasında (`radix_round`, `ot_layout_feature_set`). İkisini de öneri 3
(shape-plan / kelime önbelleği) hedefliyor.

## Shape-plan önbelleği — 2026-11-18

Önceki listedeki öneri 3'ün plan kısmı uygulandı. `native_text_item_shape` her
öğe için (profil, script, dil, yön, maskeler) planını yeniden kuruyordu: GSUB/GPOS
özellik kümesi, sıralama (`radix_round`) ve lookup programı. Profilde bu, öğe
şekillendirme süresinin arka planda ~%6–9'u, sıçrama kaydırmasında ~%11–19'uydu.

- `NativeShapeCache` (yüz başına) artık en son kullanılan 16 planı tutuyor
  (`NativePlanCache`). Anahtar planın kendi `NativePlanInfo` bilgisi.
- `native_shape_plan_take` eşleşen planı listeden çıkarıyor, yoksa planı kuruyor.
  `native_shape_plan_keep` planı başa koyuyor ve listeyi 16 girdide kesiyor.
  Planlar şekillendirme sırasında yalnızca ödünç alınıyor ve yüz önbelleğiyle
  birlikte atılıyor.
- Test (`native_shape_faces.dats`): saklanan plan eşit istek için geri dönüyor ve
  beklenen glifleri aynen üretiyor; farklı istek ıskalıyor ve önbelleği
  değiştirmiyor (`native_plan_cache kept=1 after_miss=1 taken=0 errors=0`).
  Bu test, `ANTHRACITE_OT_LATIN_TTF` / `ANTHRACITE_OT_ARABIC_TTF` ayarlıysa
  `native_shape_font_conformance` içinde koşuyor. Bu ortamda ayarlı olmadığı için
  DejaVu Sans Mono + Noto Naskh Arabic ile elle çalıştırıldı.

Release, fixture, 5 süreç medyanı:

| | Önce | Sonra |
|---|---|---|
| Sıçrama/PageDown kaydırma (medyan / p95) | 2,0–2,1 / 2,5–2,6 ms | 1,6 / 1,9–2,1 ms |
| Kaydırma karesi tahsisi p95 (jump / wheel) | 4284 / 464 | 2064 / 222 |
| Arka plan kare sayısı | ~21 | ~19,6 |
| İlk kare | 11,2–12,3 ms | 10,7–11,3 ms |

Kelime düzeyinde glif önbelleği (aynı metin+stil için glif dizisi) hâlâ açık bir
fırsat; kalan maliyet GSUB/GPOS lookup yürüyüşünün kendisi.

## Arena, kalıcı işçi havuzu, paralel işleme ve agresif önbellekler — 2026-11-18

Makine: Ryzen 9 7900X3D (iki CCD; CPU 0–5/12–17 96 MB L3, 6–11/18–23 32 MB L3),
çekirdek başına 1 MB L2, 124 GB RAM. Ölçümler Release, fixture, 5 süreç medyanı.

### Bellek: arena ayırıcı (`src/core_runtime/kernel/arena.dats`)
- Bütün ATS tahsisleri `ATS_MEMALLOC_USER` ile arenaya gidiyor (uygulama ve tüm
  testler). Açılışta 100 MB commit, sonra 64 MB adımlar, huge page; bellek
  çalışırken işletim sistemine geri verilmiyor (gecikmeli temizlik).
- İş parçacığı başına 2 MB segmentler, 40 boyut sınıfı, kilitsiz boş listeler.
  Başka iş parçacığının serbest bıraktığı blok sahibin ayrı önbellek satırındaki
  kuyruğuna gidiyor; biten iş parçacığının yığını yeni iş parçacığına devrediliyor.
- `mem_live` artık çağıran iş parçacığının baytları; bir Buf onu ayıran iş
  parçacığının hesabından düşülüyor. İşçilerin kalıcı önbellekleri ana iş
  parçacığında sızıntı gibi görünmüyor.
- Tek başına etkisi: tüm kareler ~%10 hızlı (ilk kare 11,4 → 10,5 ms, sıçrama
  kaydırma 1,67 → 1,48 ms).

### Kalıcı işçi havuzu (`src/core_runtime/kernel/workers.dats`)
- Metin motoru başlarken bir kez kuruluyor, program kapanana kadar yaşıyor.
- Fiziksel çekirdek başına bir işçi; işçi çekirdeğinin iki mantıksal CPU'suna
  atanıyor. Ana iş parçacığının L3 alanı önce, sonra diğer çekirdekler.
  Affinity maskesi ve cgroup kotası dikkate alınıyor; ana iş parçacığına bir
  çekirdek bırakılıyor ve ana iş parçacığı sabitlenmiyor.
- `/proc/stat` ile o an başka programların meşgul ettiği çekirdekler (kendi
  işçilerimizin süresi düşülerek) iş dağıtımında atlanıyor.
- İş halkası tek üretici/çok tüketici: boştaki işçi başka işçinin işini CAS ile
  çalıyor. Sonuç halkaları SPSC. Üretici ve tüketici indeksleri ayrı satırlarda.
- Parça bütçesi: işçinin L2 payının yarısı (burada 512 KB).

### Paralel satır şekillendirme
- Görünür bant ana iş parçacığında, geri kalan satırlar işçilerde. İşçi ana
  `Font` ile aynı yüz dosyalarından kendi `Font`'unu açıyor; `Doc`'a dokunmuyor.
  Sonuç: satırlar + paragraf analizi; ana iş parçacığı splice + artımlı layout.
- `VisualKey.build` her satır kurulumunu damgalıyor; eski sonuçlar atılıyor.

| | Önce | Sonra |
|---|---|---|
| Arka planın bitmesi | ~19,6 kare | ~4 kare |
| Arka plan karesinde ana iş parçacığı CPU'su | 6,9 ms | 1,1–1,6 ms |
| Sıçrama kaydırma (medyan / p95) | 1,65 / 2,10 ms | 0,32 / 0,37 ms |
| Tekerlek kaydırma, boşta kare, ilk kare | — | değişmedi |

Ölçekleme (`pool_scaling_contracts`, donanım sayaçları): 2 işçide 1,6–1,8×,
4 işçide 2,9×, 11 işçide 4,9× duvar süresi hızlanması; toplam komut +%1,2,
toplam çevrim +%5,5 (çekirdekler birbirini bekletmiyor), 1000 komutta 0,14
cache-miss. Hızlanmanın sınırı ana iş parçacığının seri kısmı (splice, layout).

### Paralel arama
- Katalog L2 parçalarına bölünüyor; bir dosya asla bölünmüyor, bütçeden büyük
  dosya tek başına bir parça. Parçalar aynı işçiye tercih edilerek gidiyor
  (dosya önbelleği isabeti), gerekirse çalınıyor. Ana iş parçacığı sonuçları
  katalog sırasıyla birleştiriyor; 200 satır sınırı ve "kesildi" bayrağı
  sıralı aramayla birebir aynı. Sekmede açık dosyalar ana iş parçacığında.
- Yolda bulunan darboğaz: katalog taraması her dosya için önceki tüm yolları
  karşılaştırıyordu (O(n²)) ve dosya başına üç `stat` yapıyordu. Karma tablo ve
  `readdir` tipi + tek `stat` ile düzeltildi.

| 5000 not, 20 MB, eşleşmeyen sorgu | Süre |
|---|---|
| Önce (sıralı, eski katalog) | 998 ms |
| Sıralı, yeni katalog | 200 ms |
| Paralel (11 işçi) | 37,5 ms |

### Agresif önbellekler
- Satır plan önbelleği: 128 → 4096 slot, belge başına 64 MB bütçe (sıçrama
  kaydırmadaki kazancın kaynağı).
- Yazı tipi plan önbelleği: 16 → 64 girdi.
- Kapanan sekmeler: kaydedilmiş belge (metin, AST, satırlar, layout) yol +
  mtime + boyut anahtarıyla saklanıyor (32 belge / 256 MB); aynı dosyanın
  yeniden açılışında yükleme, ayrıştırma ve sarma yok.
- Arama içerik önbelleği: işçi başına 64 MB, boyut+mtime doğrulamalı.
  Bu vault'ta ölçülebilir kazancı küçük (katalog ana maliyetti).

### Testler
- `arena_contracts` (1–12 iş parçacığı, ~10,5 milyon işlem, ~2,8 milyon çapraz
  serbest bırakma, kanaryalar) ve `arena_scaling_contracts` (donanım sayaçları,
  kasıtlı false-sharing kontrol deneyi 5× yavaşlama gösteriyor).
- `parallel_wrap_contracts`: 1/2/3/5/8/12 işçi × rastgele zamanlama × 5 tekrar;
  satırlar, satır ve düğüm geometrisi sıralıyla birebir aynı.
- `parallel_search_contracts`: 50/500/5000 not × 6 işçi sayısı × 5 sorgu;
  çıktı baytları sıralıyla aynı.
- `pool_scaling_contracts`, `closed_tab_contracts`.
- ThreadSanitizer (`-DANTHRACITE_TSAN=ON`, `ctest -L tsan`): 2/5/11 işçide sıfır
  uyarı. TSan işçi sayısını okuyan bir yarışı yakaladı ve düzeltildi.

## Çalışma zamanı çekirdeği ATS2'ye taşındı — 2026-11-18

Arena ayırıcı, işçi havuzu, iş parçacığı başına sayaçlar, kapanan sekme
önbelleği ve arama dosya önbelleği artık ATS2'de (`src/core_runtime/kernel/*.dats`,
`ui_tab/closed_docs.hats`, `search/results/search_file_cache.dats`). Altlarındaki
tek C `kernel/kernel.cats`: kök hücre depolaması ve tek satırlık, döngüsüz, dalsız
atomik/sistem çağrısı makroları (sınır: `docs/skill.md` §5). SIGPROF profilleyici
Release'ten çıkarıldı (`-DANTHRACITE_PROFILER=ON` ile derlenir).

Doğrulama: 264/264 test (iki ölçekleme testi boşta ayrıca çalıştırıldı),
`--selftest` delta_bytes=0, TSan derlemesinde `tsan` etiketi 4/4 ve 0 uyarı.
Yeni değişmez denetimi (önbellekteki aralık başlığı) taşıma sırasında gerçek bir
hatayı yakaladı: sıfırlanmış kök tablo "segment 0" olarak okunuyordu; bağlar
artık "segment + 1, 0 = yok" kodlamasında.

| | C çekirdek | ATS2 çekirdek |
|---|---|---|
| Arena ölçekleme (5 iş parçacığı) | — | 4,81×, 49 çevrim/işlem sabit |
| Havuz ölçekleme (11 işçi) | 4,9×, çevrim +%5,5 | 4,80×, çevrim +%5,2 |
| İlk kare CPU (medyan) | 10,7–11,3 ms | 11,7–12,0 ms |
| Sıçrama kaydırma CPU (medyan) | 0,32 ms | 0,36 ms |
| Arka plan karesi CPU | 1,1–1,6 ms | 1,1–1,7 ms |
| Tekerlek kaydırma, boşta kare | değişmedi | değişmedi |

### İlk kare gerilemesinin profili

Eski C arena (oturum dökümünden geri alınıp aynı ikiliye bağlandı) ile ATS2
arenası aynı oturumda dönüşümlü 25'er taze süreçle ölçüldü; saatler arası
sapma (±0,5 ms) böylece elendi. 60 koşunun birleştirilmiş `--tag first`
profili farkın tamamen tahsis/serbest bırakma yolunda olduğunu gösterdi
(`ANTHRACITE_WORKERS=0` etkisiz; libc modunda C ve ATS2 çekirdekler eşit):

| Adım | C arena | ATS2 arena | Fark |
|---|---|---|---|
| Başlangıç | 11,21 ms | 12,03 ms | +0,82 ms |
| `ensure_init`/`heap` soğuk yolları ayrı, `cold` bildirimli (hızlı denetim satır içi) + `release` segment başlığını bir kez okur + `owner_slot` sahibin satırına | 11,62 ms | 12,18 ms | +0,56 ms |
| Buf muhasebesi sahibi serbest bırakmanın kaydettiği etiketten okur (`arena_freed_slot`); ikinci başlık araması yok | 11,56 ms | 11,96 ms | +0,40 ms |

Bulgular:
- `mem_free_at` her Buf serbest bırakmasında segment başlığını ayrıca okuyordu
  (önbellek kaçırması bu fonksiyona düşüyordu) ve `owner_slot`, diğer
  iş parçacıklarının CAS ile yazdığı `remote` satırındaydı.
- `start_init`/`heap_create` tek çağıranlı olduğu için `ensure_init`/`heap`
  içine gömülüyor, bu ikisi de satır içine alınamayacak kadar büyüyordu.
- İş parçacığı satırındaki canlı bayt sayacı artık `lock` öneki almıyor:
  sahibi düz yükle/yaz yapar, başka iş parçacıklarının serbest bıraktığı
  baytlar satırın beşinci önbellek satırında tek başına duran `WORD_REMOTE`'a
  `fetch_add` ile yazılır; `live = LIVE − REMOTE`.

Kalan ~0,4 ms (%3,5): boş liste başının yüklenmesi (C ile aynı yük) ve
güvenlik denetimleri (boş liste bağının aralık denetimi, segment
büyü/tür/sınıf denetimleri). Bu denetimler bilinçli olarak tutuldu.
Ölçekleme değişmedi (arena 5 iş parçacığında 4,91×, 49 çevrim/işlem; havuz
11 işçide 4,69×), TSan `tsan` 4/4 ve 0 uyarı, 264/264 test.
