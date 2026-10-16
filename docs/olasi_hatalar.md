# Olası hatalar ve sonraki işler

Refactoring sırasında bulunan mevcut sorunlar. `Doğrulandı` statik kaynak
kanıtını da kapsar; çalışma zamanı yeniden üretimi ayrıca belirtilir.

## BUG-001 — Selftest başarısızlığı çıkış koduna yansımıyor

- Durum: doğrulandı (kaynak incelemesi); düzeltme bekliyor.
- Konum: çalışma zamanı selftest orkestrasyonu ve `main0`.
- Kanıt: font/belge/görsel/UI sonuçları yazdırılıyor; başarısız sonuçlar için
  süreç başarısız çıkış kodu üretmiyor. Ekran açılamaması da normal dönüş yapıyor.
- Yeniden üretme: `DISPLAY= ./build/anthracite --selftest`; günlükte
  `status=failed` varken süreç kodunu kontrol et.
- Beklenen: başarısız selftest ve ekran başlatma başarısızlığı başarısız süreç
  kodu üretmeli. Test koşucusu bu düzeltilene kadar sonuç satırlarını da doğrulamalı.

## BUG-002 — Menü modal durumu belgeyle uyuşmuyor

- Durum: doğrulandı (kaynak incelemesi); davranış kararı bekliyor.
- Konum: `editor_fsm_is_modal`.
- Kanıt: uygulama yalnız `StatePrompt` için true döndürüyor; eski kılavuz
  `StateMenu` için de true gösteriyordu.
- Yeniden üretme: `editor_fsm_is_modal(StateMenu(MenuText()))` sonucunu incele.
- Beklenen: menünün arka plan olaylarını engelleyip engellememesi ayrıca
  kararlaştırılmalı; refactoring geçiş davranışını değiştirmemeli.

## BUG-003 — Yakıt tükenmesi bazı taramalarda sessiz sonuç döndürüyor

- Durum: doğrulandı (kaynak incelemesi); düzeltme bekliyor.
- Konum: katlama satır taramaları, UI taramaları ve arama sorgusu ayrıştırıcısı.
- Kanıt: bazı `{recfuel:nat}` yordamları yakıt bittiğinde `0`, `false`, kısmi
  sonuç veya `()` döndürüyor. Eski yönerge bütün yordamların abort ettiğini söylüyordu.
- Yeniden üretme: ilgili özel yakıtlı yordamı sıfır yakıtla çağıran ayrı fixture.
- Beklenen: her API için tükenme politikası açık olmalı; mevcut kısmi sonuçlar
  bu davranış değişikliği gerektirdiğinden ayrıca düzeltilmeli.

## BUG-004 — JPEG yedek çözümleyicisi ATS ispat sınırı dışında

- Durum: doğrulandı (kaynak incelemesi); mimari borç.
- Konum: JPEG fallback ve gömülü `stb_image`.
- Kanıt: ATS JPEG çözümü başarısızsa C çözümleyici çağrılıyor; ham çıktı
  `Buf` içine kopyalanıyor. Bu C tahsisleri `mem_live` tarafından sayılmıyor.
- Yeniden üretme: ATS çözücünün desteklemediği progressive JPEG yükle.
- Beklenen: üçüncü taraf sınırı ve lisansı korunmalı; ATS2'ye taşıma ayrı iş.
  `w*h*RGBA` boyut hesabında taşma ve başarısızlık yolları ayrıca incelenmeli.

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
  yerel indeksi kullanıyor; görüntü motorunda gömülü C JPEG yedeği var.
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
