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

- Durum: doğrulandı (kaynak incelemesi); belge ve test altyapısı işi.
- Kanıt: selftest `mem_live()` değerini bazı kalıcı kaynaklar hâlâ açıkken
  yazdırıyor; `1530113` eşitliğini test etmiyor. Sayaç GPU/X11/C tahsislerini kapsamaz.
- Beklenen: aynı yaşam döngüsü noktalarında önce/sonra ölçümü; ortam ve
  açık kaynakları belirtilmiş performans ölçümleri.

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

- Durum: doğrulandı (kaynak incelemesi); performans iyileştirmesi bekliyor.
- Konum: `regions_sort_with_fuel` / `regions_sort_inner_with_fuel`.
- Kanıt: bölge tablosu eklemeli sıralamayla düzenleniyor. Ters sıralı R
  bölge için O(R²) takas gerekebilir; yalnız satır/yığın taramasının lineer
  olması bütün katlama hazırlığını lineer yapmaz.
- Beklenen: kararlı lineer/radix sıralama veya sıralı üretim; boyutu artan
  ters sıralı bölgelerle işlem sayısını ölçen test.

## BUG-007 — Eski grafik selftest sabit geçici yollar kullanıyor

- Durum: doğrulandı (kaynak incelemesi); test izolasyonu borcu.
- Kanıt: eski selftest `/tmp/anth-s`, `/tmp/anth-t.png` gibi yolları paylaşıyor.
- Beklenen: tüm fixture yollarının benzersiz bir test kökünden üretilmesi.
  Yeni grafik test ayrı yapılandırma dizini ve seri çalıştırma kullanır;
  eski selftest'in fixture yolları sonraki davranış değişikliğine bırakılmıştır.

## BUG-008 — Callout'un son alıntı satırı katlama bölgesi dışında

- Durum: başlangıç ve refactoring derlemelerinde yeniden üretildi; düzeltme bekliyor.
- Girdi: `tests/folds/callout_alinti.md` içindeki üç alıntı satırı.
- Kanıt: `--fold-dump` sahibi 0 olan bölgenin özel bitişini 2 gösteriyor;
  üçüncü `> devam` satırı katlanmıyor. Beklenen özel bitiş 3.
- Yeniden üretme: `./build/anthracite --fold-dump tests/folds/callout_alinti.md`
  veya `ctest --test-dir build/refactor-release -R fold_callout_alinti --output-on-failure`.
- Beklenen: callout gövdesindeki son satırın da aralığa dahil edilmesi. Golden
  beklenti 3 olarak korunur; test bu mevcut hatayı görünür tutar, sessizce geçirilmez.

## BUG-009 — Kelime erişiminde çarpımın temsil sınırı

- Durum: şüphe; sanitizer ile yeniden üretme bekliyor.
- Konum: `src/mem.dats`, `word_get` / `word_put`.
- Kanıt: dinamik `int` indeksinde `4*i+4 <= cap` koşulu, `airlock_word`
  çağrısından önce hesaplanıyor. Çok büyük pozitif indekslerde signed int
  çarpım/toplam taşması ihtimali ayrıca denetlenmeli.
- Beklenen: çarpımdan önce bölme temelli kapasite kontrolü veya geniş türde
  denetim; INT_MAX çevresindeki indekslerle UB/sınır testleri. Bu kayıt bir
  doğrulanmış çalışma zamanı taşması iddiası değildir.

## BUG-010 — Eski görsel selftest kişisel dosya yoluna bağlı

- Durum: doğrulandı (kaynak incelemesi); test taşınabilirliği borcu.
- Konum: `src/data_image/image.dats`, `selftest_png_ok`.
- Kanıt: fixture testlerine ek olarak geliştiricinin not dizinindeki sabit
  bir görsel varsa yükleniyor. Test sonucu makinedeki özel dosyaya bağlı olabilir.
- Beklenen: yalnız fixture verileriyle çalışan selftest. Yeni
  `workspace_image_contracts` benzersiz dizin ve üretilmiş fixture kullanır.

## BUG-011 — Artımlı ayrıştırmada başlık/liste işaret düğümleri kayboluyor

- Durum: başlangıç üretim nesneleri ve refactoring derlemesinde aynı girdilerle
  yeniden üretildi; düzeltme bekliyor.
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
  eşleşmesi. Test `known_issue` etiketlidir; devre dışı veya ters beklentili değildir.

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
