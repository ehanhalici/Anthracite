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
