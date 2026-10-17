# Açık hatalar ve sonraki işler

Bu listede yalnız açık sorunlar tutulur. Çözülen maddeler listeden çıkarılır;
kanıtları, düzeltmeleri ve test kayıtları Git geçmişinden erişilebilir.
Yeni bulgular mevcut en yüksek BUG numarasından devam eder; numaralar yeniden kullanılmaz.

## BUG-032 — GC'siz derlemede kutulanmış yardımcı değerler sızıyor

- Durum: açık; performans/sanitizer çalışmasında bulundu, ilgili yeni yollar
  düzeltildi fakat bütün eski font/OpenType yardımcıları henüz dönüştürülmedi.
- Kanıt: `ATS_MEMALLOC_LIBC` ile native grafik suite'inin LeakSanitizer koşusu
  başlangıçta 249.623 tahsiste 2.038.628 bayt kayıp raporladı. Bu sayı o geniş
  fixture koşusuna aittir, belge veya kare başına evrensel oran değildir.
  `mem_live` yalnız kayıtlı Buf payload'ını saydığı için bu testte sıfıra
  dönebilir; kutulanmış yardımcıların kaybını ispatlayamaz.
- Düzeltildi: shaping partition'ındaki `PartitionCandidate` her kümede
  kutulanmak yerine düz kayıtla taşınıyor. Geometri anahtarı, görsel düğüm alt
  sınırı ve embed seçim/koruma sonuçları `Option_vt` ile tüketilip bırakılıyor.
  Bu yeni sahiplik yollarına nonlinear `Some` kaybı eklenmemeli.
  Son genişletilmiş suite 45.601 tahsiste 363.280 bayt kalan kayıp raporladı;
  LSan hâlâ kırmızıdır.
- TODO: `glyph_position_finish` içindeki `PositionFinal(d)` ve diğer eski
  font/OpenType payload'lı `datatype`/`Option` geçicilerini incele. Tek kullanımlı
  değerleri düz kayıt veya tüketilen lineer sonuç yap; paylaşılan değerleri
  gelişigüzel serbest bırakma. Sonrasında LSan'ı bastırmasız tekrar çalıştır.
- Sınır: ASan/UBSan'ın erişim/UB kontrolü ile LSan'ın sızıntı sonucu ayrı
  raporlanır. Grafik LSan koşusu temiz sayılmıyor; toplu suppression veya yeni
  bir GC bağımlılığı bu maddeyi çözmüş kabul edilmez.
