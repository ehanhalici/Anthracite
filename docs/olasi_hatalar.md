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

## BUG-035 — Acilamayan dosya var
- Numaralandırma: kullanıcı tarafından BUG-033 olarak eklenen bu kayıt,
  aynı numaradaki eski çözülmüş sorunla çakışmaması için BUG-035'e taşındı.
- Durum: acik
- /home/emrehan/notes/obsidian_notlar/kod/araçlar/obsidian.md acilmiyor, daha dogrusu uygulama kilitleniyor
- ayrica bunun icindeki mathx bolumu de duzgun basilamiyor, karakter kodlamasinda sorun var

## BUG-034 — Arama bolumu duzgun calismiyor
- Durumu: acik
- Kasa/belge de ara bolumu birbiri icine girmis, buton mantigi buraya da gelmeli
- arama yerine bir kelime yazilinca birbirine girmis sonuclar cikiyor, ! ile gosterilen alt agac mantigi buraya da gelmeli
- bulunan bir veriye tikladigimda duz o sayfa aciliyor, ama internal link gibi o sayfa acilmali, o aranan kelimenin oldugu yere kaymali ve 1 sn boyunca mor ile vurgulanmali
- bulunan sonuclar, kelime eslemesi olarak bulunmuyor, burda ast kullaniliyor olabilir ama rg tarzi paralel cpu kullanan ve belgede/kasada arama yapan bir yapiya gecilebilri, regex destegine gerek yok, sadece birebir metin eslemesine baksa yeterli. buyuk/kucuk harfe duyarsiz olmali
