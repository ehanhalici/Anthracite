# Olası hatalar ve sonraki işler

Refactoring sırasında bulunan mevcut sorunlar. `Doğrulandı` statik kaynak
kanıtını da kapsar; çalışma zamanı yeniden üretimi ayrıca belirtilir.

## BUG-001 — Selftest başarısızlığı çıkış koduna yansımıyor

- Durum: çözüldü (2026-10-16; selftest ve ekran başlatma hataları çıkış koduna bağlandı).
- Konum: `src/core_runtime/selftest.dats`, `src/core_runtime/selftest.sats`,
  `src/main.dats` ve `tests/runtime/verify_*.cmake`.
- Kanıt: `runtime_selftest` ve `run_core_selftests` font/belge/görsel/uygulama,
  pano (`clip`), bekleme (`poll_ok`) ve izlenen canlı tampon bütçesi (`rss_ok`)
  denetimlerini birleştirir. Başarısızlıkta `event=selftest status=failed` yazılır;
  `main` renderer/platform kaynaklarını bıraktıktan sonra `exit(1)` çağırır.
  Ekran açılamaması da platform kapatıldıktan sonra `exit(1)` üretir.
- Yeniden üretme: `DISPLAY= ./build/anthracite --selftest` ve `DISPLAY= ./build/anthracite`
  tam olarak `1` döndürür, `event=display_error status=failed error=cannot_open_display`
  yazar. Grafik ortamında boş çalışma dizini, selftest'in göreli font yüklemesini
  başarısız kılar: `font_selftest=0`, toplam hata günlüğü ve süreç kodu `1` beklenir.
- Doğrulama: `graphics_selftest` başarılı `0` yolunu; ekran gerektirmeyen
  `selftest_no_display` iki başlatma modunun hata yolunu;
  `graphics_selftest_failure` gerçek alt selftest hata yolunu denetler.
  Negatif testler herhangi bir sıfır dışı kodu değil, tam olarak `1` ister;
  sinyal, farklı hata kodu ve zaman aşımı başarı sayılmaz. Üretim koduna test
  için sahte sonuç veya hata enjeksiyonu anahtarı eklenmedi.

## BUG-002 — Menü modal durumu belgeyle uyuşmuyor

- Durum: çözüldü; prompt ve menü durumları modal olarak sınıflandırılır.
- Konum: `editor_fsm_is_modal`.
- Kanıt: uygulama yalnız `StatePrompt` için true döndürüyor; eski kılavuz
  `StateMenu` için de true gösteriyordu.
- Yeniden üretme: `editor_fsm_is_modal(StateMenu(MenuText()))` sonucunu incele.
- Çözüm: `StateMenu` artık modal döner. Mevcut `step_menu` zaten kapatma/Escape
  dışındaki eylemleri yok sayıyordu; geçişler değiştirilmeden meta bilgi düzeltildi.
- Doğrulama: 66 FSM geçişi ve dört menü/dört prompt varyantı sınanır.

## BUG-003 — Yakıt tükenmesi bazı taramalarda sessiz sonuç döndürüyor

- Durum: çözüldü; yapay `recfuel` bütçesi tükenince açık hata ile abort edilir.
- Konum: `common.hats`, `airlock.sats`, katlama, UI, arama ve diğer `recfuel` taramaları.
- Kanıt: bazı `{recfuel:nat}` yordamları yakıt bittiğinde `0`, `false`, kısmi
  sonuç veya `()` döndürüyor. Eski yönerge bütün yordamların abort ettiğini söylüyordu.
- Yeniden üretme: ilgili özel yakıtlı yordamı sıfır yakıtla çağıran ayrı fixture.
- Çözüm: 400 koşul ortak `recursion_fuel_available` kapısından geçer. İndeksli
  boolean azalan metrik ispatını korur; sıfırda mevcut airlock hata kapısı çalışır.
  Eski fallback ifadeleri tip/sahiplik dalları olarak kalır, tükenmede çalışmaz.
  Doğal uzunluğu sıfıra sayarak biten `remaining` döngüleri değiştirilmedi.
- Doğrulama: gerçek katlama/görünürlük yardımcısı ve sorgu tarayıcısı sıfır yakıtla
  ayrı süreçte hata verir; normal taramalar sonuç üretir. Kaynak denetimi korumasız
  `recfuel > 0` kontrolünün yeniden eklenmesini engeller.

## BUG-004 — JPEG yedek çözümleyicisi ATS ispat sınırı dışında

- Durum: çözüldü (2026-10-16; tamamen yerel ATS2 modüllerine taşındı, C yedeği kaldırıldı).
- Konum: `src/data_image/private/img_jpg/` ve `tests/image/test_jpg_oracle.dats`.
- Kanıt: JPEG baseline ve progressive çözümleyicisi C sarmalayıcısı olmadan saf ATS2'ye
  taşındı. C `stb_image` yalnızca test orakılı olarak tutuldu. `image_oracle_contracts`
  testinde baseline ve gerçek progressive fixture dosyaları C `stb_image`
  ile piksel piksel karşılaştırılır. Genişletilmiş `jpeg_*` paketi restart,
  sequential çoklu tarama, SOF1, örnekleme ve renk uzayı regresyonlarını kapsar.
  Başarılı sonuçta tampon uzunluğu ve her testin tahsis öncesi/sonrası sayacı da
  denetlenir; bu sonuçlar test kümesi dışındaki girdiler için ispat değildir.
- Yeniden üretme: Önceden ATS çözücünün desteklemediği progressive JPEG C'ye düşüyordu;
  artık doğrudan saf ATS motorunda çözülmektedir.
- Çözüm: C `img_jpg_prog.cats` ve `image.dats` C include'ları silindi. Tüm çözülen
  ve yeniden örneklenen tamponların sahipliği ATS içindedir. İncelemede bulunan
  altı uyumluluk/sözleşme hatası düzeltildi; [test kapsamı](../tests/image/README.md)
  ve [doğrulama kaydı](refactoring_durumu.md) günceldir.

## BUG-005 — Sabit canlı bellek değeri sızıntısızlık kanıtı değil

- Durum: çözüldü; aynı sahiplik sınırında önce/sonra karşılaştırması eklenmiştir.
- Kanıt: selftest `mem_live()` değerini bazı kalıcı kaynaklar hâlâ açıkken
  yazdırıyor; `1530113` eşitliğini test etmiyor. Sayaç GPU/X11/C tahsislerini kapsamaz.
- Beklenen: aynı yaşam döngüsü noktalarında önce/sonra ölçümü; ortam ve
  açık kaynakları belirtilmiş performans ölçümleri.
- Çözüm: platform açıkken, renderer açılmadan önceki sayaç ile renderer ve
  selftest sahipleri kapandıktan sonraki sayaç karşılaştırılır. `memory_ok=0`
  süreç kodunu başarısız yapar. Bu denetim yalnız izlenen Buf kapasitelerini kapsar.
- Doğrulama: sıfır ve sıfır olmayan başlangıç değerlerinde canlı bir tampon
  fark olarak algılanır, serbest bırakılınca eşitlik sağlanır. Grafik testleri
  başarılı ve alt selftest hatalı yollarda `memory_ok=1` ister.

## DOC-001 — Katlama fixture'ları mevcut diye belgelenmiş

- Durum: çözüldü; 12 fixture, golden sınır tablosu ve CTest kayıtları eklendi.
- Kanıt: katlama kılavuzundaki `tests/folds/*.md` ve `.golden` dosyaları
  başlangıç ağacında yok; CTest'e kayıtlı katlama paketi yok.

## DOC-002 — Gerçek olmayan API ve bağımlılık açıklamaları

- Durum: çözüldü; mimari rehberler ve README gerçek kaynak/API ile eşlendi.
- Kanıt: eski kılavuzlarda `image_load`, `rend_push_scissor`, `vfs.dats`,
  `ix_ripgrep.dats` gibi mevcut olmayan arayüz/dosyalar var. Arama motoru
  yerel indeksi kullanıyordu; görüntü motorunda o sırada gömülü C JPEG yedeği vardı
  (sonradan BUG-004 ile kaldırıldı).
- Beklenen: gerçek imzalar ve kaynak bağlantıları; tasarım hedeflerini uygulama
  durumundan ayıran açıklamalar.

## BUG-006 — Katlama bölgesi sıralamasında karesel üst sınır

- Durum: çözüldü; kararlı dört geçişli radix sıralama kullanılır.
- Konum: `regions_sort_with_fuel` / `regions_sort_inner_with_fuel`.
- Kanıt: bölge tablosu eklemeli sıralamayla düzenleniyor. Ters sıralı R
  bölge için O(R²) takas gerekebilir; yalnız satır/yığın taramasının lineer
  olması bütün katlama hazırlığını lineer yapmaz.
- Beklenen: kararlı lineer/radix sıralama veya sıralı üretim; boyutu artan
  ters sıralı bölgelerle işlem sayısını ölçen test.
- Çözüm: 32 bit sahip anahtarı dört bayt geçişinde sıralanır; kayıtların tüm
  alanları ve eşit anahtarların eski sırası korunur. Zaman O(R), ek bellek O(R).
- Doğrulama: 6.561 sekiz elemanlı {-1,0,1} dizisi ve 65.536 bölgeye kadar
  büyüyen ters sıralı girdiler; gerçek döngü adımları `4*(2*R+256)` olmalıdır.
  Kayıt kimliği, alanlar, kararlılık, boş/tek kayıt ve tahsis dengesi denetlenir.

## BUG-007 — Eski grafik selftest sabit geçici yollar kullanıyor

- Durum: çözüldü; fixture kökü her çalışmada `mkdtemp` ile özel oluşturulur.
- Kanıt: eski selftest `/tmp/anth-s`, `/tmp/anth-t.png` gibi yolları paylaşıyor.
- Beklenen: tüm fixture yollarının benzersiz bir test kökünden üretilmesi.
  Grafik test ayrıca ayrı yapılandırma dizini ve seri çalıştırma kullanır.
- Çözüm: belge/VFS, görsel, arama, dosya taşıma ve UI/session selftest'lerine
  kök açık parametre olarak taşınır. Görsel Markdown hedefleri bu köke göre
  çözülür; paylaşılan `/tmp/anth-*` yolları okunmaz, silinmez veya yazılmaz.
  Yeni grafik fixture dizinleri hata incelemesi için `/tmp/anthracite-selftest-*`
  altında bırakılır; otomatik toplu silme yapılmaz.
- Doğrulama: iki eşzamanlı canlı kök aynı isimli dosyayı paylaşmaz; yeni
  headless sözleşme ve başarılı/hatalı grafik selftest yolları sınanır.

## BUG-008 — Callout'un son alıntı satırı katlama bölgesi dışında

- Durum: çözüldü; callout gövdesindeki tüm ardışık alıntı satırları ayrıştırılır.
- Girdi: `tests/folds/callout_alinti.md` içindeki üç alıntı satırı.
- Kanıt: `--fold-dump` sahibi 0 olan bölgenin özel bitişini 2 gösteriyor;
  üçüncü `> devam` satırı katlanmıyor. Beklenen özel bitiş 3.
- Yeniden üretme: `./build/anthracite --fold-dump tests/folds/callout_alinti.md`
  veya `ctest --test-dir build/refactor-release -R fold_callout_alinti --output-on-failure`.
- Beklenen: callout gövdesindeki son satırın da aralığa dahil edilmesi. Golden
  beklenti 3 olarak korunmuştur.
- Neden: blok ayrıştırıcısı callout başlığından sonra yalnız bir gövde satırı
  tüketiyordu; katlama doğru AST sınırını aldığı halde AST eksikti.
- Çözüm: gövde satırları monotonik taranır, her dolu satır kardeş paragraf olur;
  boş alıntılar da dış aralığa dahildir. İlk alıntı olmayan satır tüketilmez.
- Doğrulama: mevcut golden değişmeden geçer. Ek sözleşmeler sıfır/bir/çok
  satır, boş alıntı, girinti, son LF olmayan girdi ve AST yapısını denetler.

## BUG-009 — Kelime erişiminde çarpımın temsil sınırı

- Durum: çözüldü; çarpımdan önce bölme temelli sınır kontrolü yapılır.
- Konum: `src/mem.dats`, `word_get` / `word_put`.
- Kanıt: dinamik `int` indeksinde `4*i+4 <= cap` koşulu, `airlock_word`
  çağrısından önce hesaplanıyor. Çok büyük pozitif indekslerde signed int
  çarpım/toplam taşması ihtimali ayrıca denetlenmeli.
- Beklenen: çarpımdan önce bölme temelli kapasite kontrolü veya geniş türde
  denetim; INT_MAX çevresindeki indekslerle UB/sınır testleri.
- Yeniden üretme: eski Buf yolu INT_MAX indeksinde airlock abort'una ulaştı;
  aynı C kelime sarmalayıcısı UBSan altında `2147483647 * 4` taşması verdi.
  Nix derleyicisinin `-fwrapv` varsayımı testte `-fno-wrapv` ile kaldırıldı.
- Çözüm: ATS ve C tamsayı/float kelime erişimi, indeksin negatif olmadığını
  ve `(capacity-WORD32_BYTES)/WORD32_BYTES` sınırını çarpımdan önce denetler.
- Doğrulama: kalıcı UBSan testi INT_MIN/MAX, çarpım/toplam sınırı, son geçerli
  kelime, ilk geçersiz kelime ve kelimeden küçük kapasiteleri sınar; geçersiz
  yazmalar iki komşu kelimeyi değiştirmez, okumalar sıfır döner.

## BUG-010 — Eski görsel selftest kişisel dosya yoluna bağlı

- Durum: çözüldü; kişisel görselin varlığına bağlı dal kaldırıldı.
- Konum: `src/data_image/image.dats`, `selftest_png_ok`.
- Kanıt: fixture testlerine ek olarak geliştiricinin not dizinindeki sabit
  bir görsel varsa yükleniyor. Test sonucu makinedeki özel dosyaya bağlı olabilir.
- Beklenen: yalnız fixture verileriyle çalışan selftest. Yeni
  `workspace_image_contracts` benzersiz dizin ve üretilmiş fixture kullanır.
- Çözüm: eski görsel selftest yalnız özel fixture kökünde ürettiği PNG/BMP/JPEG
  ve aynı kökteki olmayan dosyayı yükler. Kaynak denetimi görsel modüldeki
  `/home/<kullanıcı>/` sabit yollarını reddeder; not dosyasına dokunulmaz.
- Doğrulama: kaynak denetimi, görsel sözleşme/orakıl testleri ve başarılı/hatalı
  grafik selftest yolları çalıştırılır.

## BUG-011 — Artımlı ayrıştırmada başlık/liste işaret düğümleri kayboluyor

- Durum: çözüldü; kopyalanan çocuklar ebeveynin ilk çocuk bağını korur.
- Girdiler: `# Baslik\nTurkce İı\n` ve `- Ana\n  - Alt\n- Son\n`.
- Kanıt: bayt bayt `doc_insert` sonrası AST, aynı metne `ast_parse_all`
  uygulanmış referans AST'den farklı. Başlıkta `Mark[0,2]`; listede ilk iki
  maddenin `Mark` düğümleri eksik. İki ağacın yapısal doğrulaması tek başına
  eşdeğerliği garantilemiyor.
- Başlangıç kontrolü: aynı tip denetimli test girişi, yalnız taşınan linker
  adları uyarlanarak `188239f` üretim nesnelerine bağlandı; aynı iki fark çıktı.
  Üretim algoritmaları bu kontrolde değiştirilmedi.
- Yeniden üretme: `ctest --test-dir build/refactor-release -R
  workspace_document_contracts --output-on-failure`; test her iki ağacı yazdırır.
- Beklenen: artımlı ve tam ayrıştırmanın işaret/çocuk düğümlerini de koruyarak
  eşleşmesi. `known_issue` etiketi düzeltmeden sonra kaldırılmıştır; beklentiler
  değiştirilmemiştir.
- Neden: `doc_node_add(..., prev_sib=-1, ...)` her kopyalanan çocukta ebeveynin
  ilk çocuk bağını değiştiriyordu. Kayıtlar kalıyor, önceki çocuklar döküm ve
  gezinmede erişilemez oluyordu.
- Çözüm: baş/kuyruk kopyasında ebeveynin kaydedilmiş ilk çocuk indeksi doğru
  indeks kaymasıyla geri yüklenir. Artımlı yeniden eşzamanlama korunur; her
  düzenleme zorunlu tam ayrıştırmaya dönüştürülmez.
- Doğrulama: eski sekiz girdinin bayt bayt testi; altı Markdown/Unicode
  fixture'ında her bayt konumunda iki parçalı ekleme, metin/LF ekleme, silme
  ve değiştirme tam ayrıştırmayla karşılaştırılır. Kind/aralık/ebeveyn/çocuk/
  kardeş/alt ağaç/içerik/aux alanları ve AST doğrulayıcısı denetlenir.

## BUG-012 — Paylaşılan ATS test fixture'ı paralel üretiliyor

- Durum: çözüldü (2026-10-16; BUG-001 doğrulamasında yeniden üretildi).
- Konum: `cmake/ATSGenerated.cmake` ve birden çok yürütücüye bağlanan test kaynakları.
- Kanıt: Debug `check-build -j 16` sırasında `font_fixture_dats.c` on kez üretildi;
  `sfnt_conformance` dosyayı boşken derledi (`-Wempty-translation-unit`) ve fixture
  simgelerini bağlayamadı. Bu, selftest çıkış kodu değişikliğinin mantıksal hatası değildir.
- Yeniden üretme: `cmake -E touch_nocreate tests/font/resources/font_fixture.sats`
  sonrasında paralel `check-build`. Önceki grafikte başarısızlık zamanlamaya bağlıydı.
- Çözüm: paylaşılan test C çıktıları `ats_shared_test_generated` tek üretici
  hedefine bağlandı; bütün tüketiciler bu hedefin tamamlanmasını bekler.
- Doğrulama: aynı test arayüzü tekrar güncelletilip her iki profilde `check-build
  -j 16` çalıştırıldı; fixture her profilde bir kez üretildi ve bağlama tamamlandı.

## BUG-013 — Selftest süreç doğrulayıcıları commit dışında kalmış

- Durum: çözüldü; iki doğrulayıcı kaynak denetimine alındı.
- Kanıt: `0046f1b` CMake kaydı `verify_no_display.cmake` ve
  `verify_selftest_failure.cmake` dosyalarını çağırdığı halde bu dosyalar
  izlenmiyordu; temiz checkout'ta ilgili testler çalışamazdı.
- Çözüm: `tests/runtime` altındaki iki dosya eklendi. Her iki profilin önceki
  süreç testlerinde doğrulanan uygulama/alt selftest hata kontrolleri korunur.

## BUG-014 — C tampon kopyalama sınırında toplam taşması

- Durum: çözüldü; UBSan ile yeniden üretildi ve çıkarma temelli kontrol eklendi.
- Konum: `src/mem.cats`, `anth_buf_copy` / `anth_copy_to_ptr`.
- Kanıt: `offset + n > capacity` denetimi signed `int` toplamasını sınır
  kontrolünden önce yapar. Büyük pozitif uzunluk/ofsette taşma olabilir.
- Beklenen: negatif değerler dışlandıktan sonra `n <= capacity - offset`
  kontrolü; küçük gerçek tamponlarda INT_MAX çevresindeki reddetme testleri.
- Yeniden üretme: eski kod 16 baytlık tamponda ofset 8, uzunluk INT_MAX için
  `8 + 2147483647` signed overflow tanısı verdi (`-fno-wrapv`, UBSan).
- Çözüm: `0 <= offset <= capacity` sonrasında `length <= capacity-offset`
  kontrolü iki kopyalama kapısında ortak kullanılır; çakışan aralıklar için
  `anth_buf_copy` mevcut `memmove` davranışını korur.
- Doğrulama: UBSan testi kapasite/ofset/uzunluk matrisi, negatif kapasiteler,
  INT_MIN/MAX sınırları, hedef/kaynak reddi ve geçerli çakışan kopyayı sınar.

## BUG-015 — Unifont yüklemesinde geliştiriciye özel yedek yol

- Durum: çözüldü; kişisel Unifont yedek yolu kaldırıldı.
- Konum: `src/core_render/gl.cats`, Unifont dosyasını açan yordam.
- Kanıt: yapılandırılmış ve göreli dosya açılamazsa geliştiricinin mutlak
  çalışma dizinindeki `unifont.bin` açılmaya çalışılıyor. Dosya eksikken
  makineye özgü yedek farklı sonuç verebilir.
- Beklenen: yapılandırılmış kaynak veya taşınabilir göreli yol; özel dizine
  bağımlılığın kaldırılması ve eksik dosya yolunun korunması.
- Yeniden üretme: boş çalışma dizini ve olmayan yapılandırılmış dosya ile
  `unifont_missing_path` eski kodda `expected=0 loaded=1` verdi; kişisel
  depodaki font istenmeden yükleniyordu.
- Çözüm: yalnız `ANTHRACITE_UNIFONT`, `src/data_font/unifont.bin` ve
  `../src/data_font/unifont.bin` denenir. Tümü eksikse mevcut boş sonuç korunur.
  Kaynak denetimi kişisel `fopen` sabitini reddeder.
- Doğrulama: ekran gerektirmeyen dört test, yalıtılmış dizinlerde eksik dosya,
  yapılandırılmış dosya ve iki göreli yerleşimi denetler.

## BUG-016 — Yakıt fixture'ının bağlantısı Release optimizasyonuna bağımlı

- Durum: çözüldü; Release ve Debug tam derleme/test paketleri geçti.
- Konum: `recursion_fuel_contracts`, `cmake/InfrastructureTests.cmake`.
- Kanıt: bu çalışmadaki BUG-003 fixture'ı bütün `ix_query.dats` dosyasını
  dahil ediyordu. Kullanılmayan sorgu fonksiyonları `ix_fold` üzerinden `Doc`
  bağımlılığı getiriyordu. Release LTO bunları eledi, Debug ise `doc_byte`
  bağlantısında hata verdi. Üretim uygulamasının bağlantı hatası değildir.
- Çözüm: gerçek boşluk tarayıcısı aynı sahip içinde özel `.hats` dosyasına
  ayrıldı. Üretim ve fixture aynı yordamı içerir; fixture yalnız Buf'a bağlanır.
  Sahte Doc uygulaması veya optimizasyonla hata gizleme eklenmedi.
- Doğrulama: her iki profilde `check-build -j12` ve 260/260 CTest geçti;
  normal tarama ile iki sıfır yakıt/abort testi Debug'da da başarıyla çalıştı.

## BUG-017 — Embed ölçümü ve çizimi aynı belgeyi paylaşmıyor

- Durum: çözüldü; ölçüm ve çizim aynı sahipli belge cache'ini kullanır.
- Kanıt: `measure_embedded_height` belgeyi yükleyip serbest bırakır; çizim
  yolunun ayrı `CEmbed` cache'i vardır. İlk ölçüm çizimde tekrar kullanılamaz.
- Çözüm: ortak obtain/save yolu hit'te belgeyi ödünç alıp geri koyar; derinlik
  yeniden kullanımda güncellenir. Ölçülen belge atılmaz. Cache 48 belgeyle sınırlıdır.
- Doğrulama: yedi farklı blok için tek Doc yükleme/AST parse, tek cache girdisi
  ve sıcak hazırlıkta sıfır yükleme; native grafik suite'i geçti. Kişisel örneğin
  ilk karesinde 38 yerine 31 çocuk belge yüklemesi ölçüldü.

## BUG-018 — Embed yükseklik anahtarı hedef bloğu içermiyor

- Durum: çözüldü; hatalı global yükseklik tablosu kaldırıldı.
- Kanıt: C yükseklik tablosu yalnız path/width/lh kullanır; aynı dosyanın
  farklı `#^blok` referansları aynı yüksekliği paylaşır. Font sürümü eksiktir.
- Çözüm: yükseklik ilgili blok aralığının güncel Doc görsel geometrisinden
  alınır. Font/ölçek/sürüm ve genişlik VisualKey tarafından denetlenir;
  farklı bloklar artık aynı path tablosu yüksekliğini paylaşmaz. Ölçüm/çizim
  aynı çocuk metin genişliği hesabını kullanır.
- Doğrulama: tek dosyadaki yedi farklı uzunluktaki blok aynı belgeyi paylaşırken
  farklı yükseklikler üretir; sıcak yükseklik ve bellek sahipliği testi geçti.

## BUG-019 — Çocuk clip'i ebeveynin görünür sınırını genişletebiliyor

- Durum: çözüldü; iç içe clip yığını ve GPU piksel regresyonu eklendi.
- Kanıt: `rend_scissor` mutlak GL dikdörtgeni kurar; embed kendi dikdörtgenini
  ebeveynle kesiştirmeden kullanır. Sekme alanına taşma mümkündür.
- Çözüm: `rend_clip_push/pop` ebeveynle kesiştirir ve önceki sınırı geri
  yükler; belge/embed, sekme, sidebar ve widget çağrıları taşındı. Boş kesişim
  çizimi kapatır; boyama sınırını genişletmez. Yığın Rend tarafından bırakılır.
- Doğrulama: Xvfb native grafik suite'i geçti. 128×128 GPU çıktısında ebeveyni
  aşan çocuk, ayrık/boş çocuk ve pop sonrası kök çizimi piksel piksel sınanır.

## BUG-020 — Gömülü metinde seçim ve hedefe gitme eksik

- Durum: çözüldü; kutu hit-test/navigasyon ve salt-okunur seçim eklendi.
- Kanıt: hit-test embed'i tek nesne sayıp parent caret'ini başına koyar;
  hedef açma yolu yalnız KWiki/KLink arar, KEmbed kabul etmez.
- İlerleme: embed kutusu hit-test ve wiki hedef açma yoluna alındı;
  kaynak/salt-okunur moddaki kutuya düz tıklama hedefe gider. Ctrl ile mousedown
  açıldıysa mouseup ikinci kez açmaz. Hedef çözümü ortak tam anchor indeksini
  kullanır. Yeni sekmenin hedef kaydırması gerçek yerleşim hazırlandıktan sonra
  uygulanır; henüz hesaplanmamış satır Y'sinden kaydırma üretilmez.
- Çözüm: seçim cache'te ebeveyn belge/kutu ve çocuk kaynak sürümüne bağlıdır;
  paylaşılan çocuk Doc'un caret/anchor'ını değiştirmez. ≥5 px sürükleme bir
  kez başladıktan sonra başlangıca dönülse de navigasyonu iptal eder. Seçim
  aynı embed aralığına sınırlandırılır; Ctrl+C mantıksal izdüşüm metnini kopyalar.
  Bu odakta düzenleme komutları engellenir; seçili dosya cache tahliyesinde korunur.
- Doğrulama: iki kutu aynı dosyayı paylaşırken yalnız ilki GPU'da seçili boyanır;
  tıklama adayı, sürükleme, kopyalanan metin ve geri dönmüş sürüklemenin iptali
  sınanır. App selftest yeni hedef sekmesini ve ikinci açışta sekme yeniden
  kullanımını denetler. CTest'e eklenen native grafik sözleşmesi ve selftest geçti.

## BUG-021 — Sarma çok sayıda örtüşen metin parçasını yeniden şekillendiriyor

- Durum: çözüldü; paragraf prefix araması ve sahipli satır planları kullanılıyor.
- Kanıt: `fit` her grapheme adayında büyüyen öneki ölçer; `line_rows` her
  satır için kalan son eki ölçer. Aynı satır yaprak boyamasında da tekrarlanır.
- Çözüm: paragraf küme advance/prefix yolu ve gerçek satır sonu doğrulaması
  eklendi; ara ölçümde 88.269 → 2.415 shaping çağrısı görüldü. Görünür satırlar
  ölçüm cache'inden plan sahipliğini devralır; yoksa bir kez şekillendirilir.
  VisualRows'a bağlı 128 yuvalı indeksli plan cache'i boyama/yön/hit/seçim
  tarafından paylaşılır; font kimliği/sürümü doğrulanır ve view kapanışında
  planlar bırakılır. Viewport altına geçildiğinde satır yürüyüşü durur.
- Doğrulama: Türkçe/Arapça, bidi/işaret/ligatür ve 64/256/1024 tekrarlı sarma
  sözleşmeleri geçti. Genel font cache'i 256 ayrı metinle tahliye edildikten
  sonra aynı satırın boyama/caret/hit işlemleri sıfır yeni shaping yapar.

## BUG-022 — Katlama hazırlığında tekrar ve bölge × düğüm taraması

- Durum: çözüldü; tek hazırlama ve monoton düğüm taraması kullanılıyor.
- Kanıt: yeniden ayrıştırma sonrası `doc_compute_foldability` ve onu tekrar
  çağıran `fold_apply` çalışır. Her bölge, sahibi için bütün AST'yi tarar.
- Çözüm: yeniden ayrıştırmanın gereksiz ilk hazırlaması kaldırıldı; sıralı
  bölgeler aynı düğüm imlecini ilerletir, aynı satırdaki sahip yeniden kullanılır.
  Önceki düğüm türü önceliği ve eşitlikte ilk düğüm davranışı korunur.
- Doğrulama: 32/256/2048 başlıklı sentetik belgelerde tek hazırlama,
  düğüm ziyaretleri ≤ düğüm + bölge sayısı, bütün başlık sahipleri ve bellek
  dengesi denetlenir. Release katlama/workspace/ayrıştırma paketinde 16/16 geçti.

## BUG-023 — Sıcak yerleşim çağrısı yine tam hazırlama işi yapıyor

- Durum: çözüldü; seyrek medya indeksi ve yerleşim-miss indeksleme kullanılıyor.
- Kanıt: `prepare_document_layout` cache isabetinde bile medya taramasını
  ve `doc_visual_index` üzerinden tam düğüm indeksi kurulumunu çalıştırır.
- Çözüm: Doc'un sürümlü medya indeksi yalnız image/embed/math düğümlerini
  tutar. Sıcak çağrı bütün AST'yi dolaşmaz; medya kaynaklarının tazelik denetimi
  korunur. Görsel düğüm indeksi yalnız gerçek yerleşim yenilendiğinde kurulur.
- Doğrulama: native grafik suite'i sıcak çağrıda sıfır wrap/layout/medya-indeks/
  görsel-indeks hazırlığı ve metin değişiminde indeks yenilenmesini denetler.
  Uzun kişisel belgede sıcak karede görsel indeks sayacı 1'den 0'a indi.

## BUG-024 — Görev kutusu dikey hit-test'te atlanıyor

- Durum: çözüldü; grafik regresyonu genişletilirken bulundu.
- Kanıt: `node_covering_impl_with_fuel` aynı Y'yi kapsayan son düğümü
  seçer; KTask sonrasındaki paragraf görev hit'ini ezer. Mevcut
  `folding_and_task` grafik testi görev düğümünü bulamıyor; ayrıca test,
  durum baytını KTask başlangıcı +3 yerine kaynak satırı +3'ten okumalıdır.
- Beklenen: görev kutusunun ilk görsel satırındaki hit-test'in görev
  düğümünü döndürmesi; katlama ve görev değiştirme regresyonunun geçmesi.
- Çözüm: görünür görev kutusunun ilk görsel satırındaki hit, sonraki
  paragraf tarafından ezilmez. Test durum baytını kaynak satırından okur.
- Doğrulama: Release/Xvfb native font/görsel yerleşim/görev suite'i geçti;
  `visual_fold` başlık/katlama/açma/görev hit/görev toggle değerleri true.

## BUG-025 — Embed tazeliği aynı saniyedeki değişimi ve VFS kaynağını kaçırıyor

- Durum: çözüldü; cache genişletilirken bulundu ve regresyon eklendi.
- Kanıt: CEmbed yalnız fiziksel yolun tamsayı saniye mtime değerini
  karşılaştırıyordu; Doc yükleme ise varsa dolu VFS gölgesini okur. Aynı
  saniyede değişen içerik veya yeni/silinen gölge eski belgeyi gösterebilirdi.
- Çözüm: etkin kaynak seçimi Doc yükleme politikasıyla aynıdır. Gölge/gerçek
  kaynak bayrağı ve stat saniye/nanosaniye/boyut/cihaz/inode kaydı tam karşılaştırılır.
  Eksik kaynak için kare başına başarısız Doc yükleme yapılmaz.
- Doğrulama: yedi referans paylaşılırken aynı boyutta fiziksel dosya değişimi,
  dolu VFS gölgesi oluşturma ve silerek fiziksel kaynağa dönüş her seferinde
  tek yeniden yükleme ve doğru ilk kaynak baytı üretir. Native grafik suite'i geçti.

## BUG-026 — Blok/başlık referansları yanlış kaynak aralığını gösterebiliyor

- Durum: çözüldü; anchor kapsamları incelenirken bulundu.
- Kanıt: blok embed yalnız işaretin bulunduğu fiziksel satırı gösteriyordu;
  bağımsız `^id` önceki paragrafı değil işaret satırını seçiyordu. Başlık embed'i
  bütün dosyaya düşüyor, navigasyon ise ilk alt dize eşleşmesini kullanıyordu.
- Çözüm: Doc sahipli, yeniden ayrıştırmada geçersizleşen ortak anchor indeksi;
  tam blok kimliği veya başlık adı eşleştirmesi, çok satırlı paragraf/liste
  kapsamı, bağımsız işaretin önceki blokla eşleştirilmesi ve başlık bölümü.
  Kod çiti içindeki işaretler hedef olmaz. Eksik hedef tüm dosyaya düşmez.
- Doğrulama: `anchor_contracts` kapsam, prefix çakışması, yanlış ilk alt dize,
  kod çiti, düzenleme sonrası yeniden indeksleme ve bellek dengesini denetler.
  Release ve native grafik suite'i geçti. Çocuk çizimi viewport kesişiminden
  başlar; üstteki görünmez düğümler tekrar boyanmaz.

## BUG-027 — Sarılmış satır paragrafın bidi bağlamını yeniden analiz ediyor

- Durum: çözüldü; paragraf analizi görünümde saklanır ve satıra aktarılır.
- Kanıt: paragraf sarması bir analiz üretse de kesin satır ölçümü/yeniden
  boyama `font_span_make` ile satır parçasını AutoLtr olarak yeniden analiz
  eder. Nötr veya sayıyla başlayan RTL devam satırında paragraf tabanı ve
  satır dışındaki çözümlenmiş bidi bağlamı kaybolabilir.
- Çözüm: EGC hizalı tek-paragraf penceresi normalize scalar'ları, kaynak
  ofsetlerini, çözülmüş bidi seviyelerini/tabanını ve script'leri devralır.
  Mevcut bidi satır motoru L1 ve yeniden sıralamayı uygular; joining gerçek
  satır kenarında hesaplanır. Unicode analizi satır başına tekrarlanmaz.
  Orijinal bayt uzunluğu ayrıca tutulur; yeniden sıralanmış son combining
  mark'ın `sourceEnd` değeri dosya/paragraf sonu kabul edilmez.
- Doğrulama: pencere seviyeleri/script'leri ve L1 sırası orijinal paragraf
  penceresiyle karşılaştırılır; RTL sayılar, embedding/izolat, trailing space,
  NFC yeniden sıralama, hatalı UTF8, EGC içi ve çapraz-paragraf reddi sınanır.
  Grafik testi, nötr/sayıyla başlayan RTL devam satırlarının sağa hizalandığını
  doğrular. Native analiz, grafik ve selftest paketleri geçti.

## BUG-028 — Görünmeyen gömüler ilk karede eşzamanlı hazırlanıyor

- Durum: çözüldü; görünür alan ve bir viewport taşma payı ile aşamalı hazırlık.
- Kanıt: medya indeksi her karede bütün gömüleri ölçüyordu; aşağıdaki kaynaklar
  ilk görünüm için gerekmese de yükleme/AST/sarma maliyetine katılıyordu.
- Çözüm: görünür gerçek içerik öncelikli hazırlanır. Yakındaki önbellek miss'leri
  4 ms esnek iş bütçesiyle sürdürülür; uzak kaynaklar yüklenmez. Bir atomik
  parse/shape işi süreyi aşabilir; denetim işler arasındadır. Olay döngüsü bekleyen
  işler bitene kadar yeni kare üretir, sonra normal olay beklemesine döner.
  Yüksekliği bilinmeyen gömü tahmin edilir; gerçek yükseklik gelince üst kaynak
  satırı + satır içi piksel ofseti korunur. Seçili görünümden sonra sığan görünür
  görünümler tahliyede öne alınır; 48 belge/128 görünüm/64 MiB sınırları korunur.
- Doğrulama: süresi baştan tükenmiş bütçe testi görünür içeriği hazırlayıp yakın
  miss'i erteler; takip kareleri işi bitirir, uzak dosyaları açmaz. Alta kaydırma
  yeni kaynakları açar; üstteki bir gömü değiştiğinde kaydırma anchor'ı korunur.

## BUG-029 — Gömü içindeki bağlantı yerine dış gömünün hedefi açılıyor

- Durum: çözüldü; en içteki bağlantı tıklaması dış kutu gezinmesini geçersiz kılar.
- Kanıt: fare bırakıldığında yalnız ana belgenin caret'i ile `app_wiki_open`
  çağrılıyordu. Gömünün çizilmiş içeriğindeki wiki/Markdown bağlantısına veya
  iç içe başka gömüye tıklamak dış gömünün dosyasını açıyordu.
- Çözüm: aynı native satır geometrisiyle koordinat iç gömülere aktarılır;
  en içteki linkin kaynak kimliği/parse generation/düğümü seçim durumunda
  tutulur. Bırakmada etkin dosya stamp'i tekrar doğrulanır. Wiki/yerel link
  mevcut sekmeyi yeniden kullanır, aynı-dosya anchor'ı çocuk dosyaya gider;
  dış URL normal platform açma yolunu kullanır. Ctrl+tıklama da aynı önceliği
  izler; sürükleme bağlantı gezinmesini iptal eder.
- Doğrulama: grafik regresyonunda iki gömü derinliğindeki wiki+anchor,
  linksiz iç kutunun kendi hedefi, aynı dosya anchor'ı, dış Markdown URL'si
  ve sürükleme sonrası gezinmenin iptali sınandı. Gerçek dış URL açılmaz;
  test çözümlenen hedef ve hedef türünü denetler. Grafik/selftest paketleri geçti.
