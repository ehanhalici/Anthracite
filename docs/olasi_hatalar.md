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
  Bu düzeltmelerden sonraki genişletilmiş suite 45.196 tahsiste 360.952 bayt
  kalan kayıp raporladı; LSan hâlâ kırmızıdır.
- TODO: `glyph_position_finish` içindeki `PositionFinal(d)` ve diğer eski
  font/OpenType payload'lı `datatype`/`Option` geçicilerini incele. Tek kullanımlı
  değerleri düz kayıt veya tüketilen lineer sonuç yap; paylaşılan değerleri
  gelişigüzel serbest bırakma. Sonrasında LSan'ı bastırmasız tekrar çalıştır.
- Sınır: ASan/UBSan'ın erişim/UB kontrolü ile LSan'ın sızıntı sonucu ayrı
  raporlanır. Grafik LSan koşusu temiz sayılmıyor; toplu suppression veya yeni
  bir GC bağımlılığı bu maddeyi çözmüş kabul edilmez.

## BUG-033 — Küçülen gömü sonrası yeni yakın işler kaçırılıyor

- Durum: doğrulanıyor; yakın görünüm sabitlenene veya bütçe dolana kadar yeniden taranıyor.
- Kanıt: görünür hazırlık sonrası taşma payı yalnız bir kez taranıyordu.
  Bir gömü kısalınca alttaki başka gömü taşma payına girse de tarama bittiği
  için bekleyen iş bayrağı false kalabiliyordu. İlk ölçümde sonraki sabit
  karelerde yükleme olmadan üç/iki yeni layout ve azalan belge yüksekliği görüldü.
- Çözüm: geometri değiştiğinde görünür + yakın hazırlığı tekrar edilir;
  yeni miss bütçeyi aşarsa bekleyen iş işaretlenir ve olay döngüsü devam eder.
- Doğrulama: kısa gömülerle tahmin küçülmesinin yeni yakın kaynakları açması
  ve sonraki sabit karede sıfır layout/wrap kurması kontrol edilecek.
