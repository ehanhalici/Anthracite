# Refactoring çalışma kaydı

Başlangıç: 2026-10-16, `188239f` (`uzun metin optimizasyonu eklendi`).
Amaç: davranışı koruyarak okunabilir sabitler/adlar, konuya göre modüller,
tekrarlanabilir testler ve uygulamayla eşleşen belgeler sağlamak.

## Başlangıç doğrulaması

- Mevcut `build` çıktıları: 77/77 CTest geçti (planlama aşaması).
- Temiz başlangıç Release derlemesi ve 77/77 test geçti (`build/refactor-baseline`).
- Test fontları: DejaVu Sans/Mono ve depodaki Noto Naskh Arabic.
- Başlangıç grafik selftest: Xvfb üzerinde geçti; `live=1530113`, `poll_ms=100`.
- Refactoring Release ve Debug derlemelerinde bütün yürütücüler derlendi.
- Her profilde 97 testin 95'i geçti. Başlangıçtaki 77 testin tamamı geçti;
  yeni testler iki eski davranış hatasını görünür kılıyor (BUG-008, BUG-011).
- Yeni bellek/kayıt, 66 FSM geçişi, olay matrisi, bağımsız görsel/yapılandırma
  testleri ve grafik selftest geçti.
- 12 katlama fixture'ından 11'i geçti; kalan callout sınırı başlangıçta da
  hatalıdır (BUG-008). Beklenti değiştirilmeden kırmızı tutulur.
- Temiz Debug dizini: `build/refactor-debug`; Release dizini: `build/refactor-release`.
- Artımlı/tam AST eşdeğerlik testi iki girdide başarısız (BUG-011). Aynı farklar
  başlangıç üretim nesnelerine bağlanan test girişinde de doğrulandı.
- Son grafik ölçümleri: Release `start_ms=42`, Debug `start_ms=44`; her ikisinde
  `live=1530113`, `poll_ms=100` ve tüm sonuç bayrakları başarılı. Bunlar Xvfb
  ortamındaki ölçümlerdir; genel performans garantisi değildir.

## Paketler

| Paket | Düzenleme | Doğrulama | Belge |
|---|---|---|---|
| CMake / ATS üretimi / test hedefleri | Uygulandı | Release/Debug derlemeleri geçti | Güncel |
| Bellek / airlock / ortak yardımcılar | Uygulandı | Yeni sözleşmeler geçti | Güncel |
| Metin / Unicode | Uygulandı | İki profilin uyumluluk/tip testleri geçti | Güncel |
| Font / OpenType / glif / native motor | Uygulandı | İki profilin uyumluluk/tip testleri geçti | Güncel |
| Belge / AST / düzenleme / katlama | Uygulandı | BUG-008 ve BUG-011 kırmızı; diğerleri geçti | Güncel |
| UI / sekmeler / görsel yerleşim / embed | Uygulandı | FSM, kaynak düzenleme ve grafik geçti | Güncel |
| Görsel çözme / ölçekleme | Uygulandı | Saf ATS2 JPEG motoru, izole CPU, orakıl ve grafik testleri geçti | Güncel |
| Platform / render / çalışma zamanı | Uygulandı | Olay matrisi/grafik geçti | Güncel |
| Yapılandırma / arama / işletim sistemi | Uygulandı | İzole oturum, kayıt ve grafik geçti | Güncel |
| Genel doküman / ajan kuralları / son denetim | Uygulandı | Kaynak/bağlantı denetimi geçti | Güncel |

## Yapılan düzenlemeler

- Yaklaşık 1.500 kaynak/test/araç yolu konu klasörlerine taşındı; yüklemeler,
  CMake grupları ve negatif tip testleri birlikte güncellendi.
- Yakıt/tükenme, tampon ve font yardımcılarında 700'ü aşkın ad açıldı.
- Temsil/Unicode sınırları, karakter karşılaştırmaları ve ilk tahsis
  kapasitelerinde 700'ü aşkın açıklamasız literal isimlendirildi.
- 15 büyük sahip modül özel `.hats` gruplarına ayrıldı; yedi opak sahip korundu.
- Yerleşim ve görsel satır kayıtları, Bloom boyutları, UTF8 sınırları,
  Hangul formülleri, vertex düzeni ve görsel/selftest politikaları adlandırıldı.
- JPEG motoru (`stb_image`) baseline ve progressive desteğiyle tamamen yerel
  ATS2 modüllerine taşındı (BUG-004 çözüldü). `stb_image.h` yalnızca test paketi
  orakılı olarak tutuldu; C yedeği kaldırıldı.
- 15 mimari rehber, proje README'si ve ajan kuralları gerçek uygulamayla eşlendi.
- Taşıma haritasındaki 1.494 hedef dosya kontrol edildi; eksik dosya yok.
- 5.154 ATS fonksiyon gövdesinin satır taramasında sınırı aşan gövde bulunmadı.
  Bu kaynak denetimidir; tek başına tek sorumluluk veya algoritmik doğruluk ispatı değildir.
- Kaynak yüklemeleri, belge bağlantıları, yedi opak sahip ve `git diff --check` geçti.
- `vendor/stb/stb_image.h` gövdesi başlangıç kopyasıyla bayt bayt aynı doğrulandı.

## Yeniden çalıştırma

### BUG-004 inceleme düzeltmeleri (2026-10-16)

- C JPEG yedeği üretimden kaldırıldı; üretim kaynaklarında yeniden kullanımını
  `source_integrity` engeller. stb C gövdesi yalnız test orakılıdır.
- Restart aralığının son MCU'da dolması, RGB/CMYK/YCCK renk seçimi,
  non-interleaved/sequential çoklu tarama, SOF1, genel dikey yeniden örnekleme
  ve başarılı çıktı tamponunun uzunluğu düzeltildi.
- SOF/SOS sınırları, örnekleme katsayıları, tablo seçicileri ve tarama
  parametreleri için ret denetimleri eklendi.
- 132 sentetik geçerli ve 14 bozuk JPEG fixture'ı eklendi; orijinal baseline ve
  progressive karşılaştırması korunuyor. JPEG etiketli 147 CTest'in tamamı
  Release ve Debug profillerinde geçti.
- Her iki profilde `check-build` geçti. Tam paket 244 testten oluşuyor:
  CPU testlerinde 241/243 ve ayrı Xvfb :1 grafik selftest'inde 1/1 başarılı.
  Yalnız eski BUG-008 ve BUG-011 kırmızı; beklentiler veya etiketler değiştirilmedi.
- Aynı 147 JPEG testi ayrı derlemede ASan/LSan ile geçti; üretim JPEG ve bellek
  modülleri ayrıca UBSan ile denetlendi. C oracle bu derlemede yalnız ASan/LSan
  kapsamındadır. Sayaçlar ve sanitizer sonuçları sınanan girdilerin kanıtıdır,
  bütün JPEG uzayı için doğruluk veya sıfır UB ispatı değildir.
- Dört JPEG tohumundan türetilen 600 deterministik entropy mutasyonunda
  sanitizer bulgusu yoktu (245 kabul, 355 ret). Bozuk akışların tamamının
  reddedildiği iddia edilmez; bu, sabit fixture paketine ek bir deneydir.
- Fixture üreteci ayrı geçici dizinde tekrar çalıştırıldı; 146 ikili dosyanın
  tamamı depodaki kopyalarıyla bayt bayt aynı üretildi.
- Kaynak/bağlantı/sahiplik denetimi, ATS fonksiyon gövdesi boyut taraması ve
  farklardaki boşluk denetimi geçti. [JPEG test rehberi](../tests/image/README.md)
  veri kümesini ve yeniden üretim komutlarını açıklar.

### BUG-001 inceleme doğrulaması (2026-10-16)

- Kullanıcının çekirdek düzeltmesinde alt selftest/sağlık sonuçlarının `main`'e
  taşınması ve başarısızlıkta kaynaklar bırakıldıktan sonra `exit(1)` çağrılması
  doğrulandı; bu akış değiştirilmedi.
- Testteki "herhangi bir sıfır dışı sonuç yeterlidir" kontrolü kaldırıldı.
  `selftest_no_display` grafik ortama bağlı olmadan normal başlatma ve
  `--selftest` için tam olarak `1` ister. Doğru hata mesajı yazan yapay süreçlerde
  `0` ve `7` reddedildi, yalnız `1` kabul edildi.
- `graphics_selftest_failure`, gerçek üretim ikilisini boş çalışma dizininde
  çalıştırarak göreli font yükleme hatasını, `font_selftest=0`, toplam hata
  günlüğü ve `exit(1)` yolunu sınar. Üretim hata enjeksiyonu veya sahte selftest
  kullanılmaz. Başarılı grafik selftest ve sonuç bayrağı kontrolleri korunur.
- BUG-001'i hâlâ açık gösteren mimari/index açıklamaları güncellendi.
- Debug doğrulamasında paylaşılan test fixture'larının paralel üretim yarışı
  bulundu (BUG-012). Ortak çıktılar `ats_shared_test_generated` tek üreticisine
  alındı. Test arayüzünün zaman damgası güncellenerek iki profilde `check-build
  -j 16` tekrarlandı: fixture başına tek üretim ve başarılı bağlama doğrulandı.
- Son tam paket her profilde 246 testtir: 244 geçti, yalnız önceki BUG-008 ve
  BUG-011 başarısız. BUG-001'e ait başarılı grafik, gerçek alt selftest hatası ve
  ekransız başlatma testlerinin üçü de Release/Debug'da geçti. Test beklentileri
  veya `known_issue` etiketleri değiştirilmedi.

### Komutlar

```sh
cmake --build build/refactor-release --target check-build --parallel
ctest --test-dir build/refactor-release --parallel 8 -LE graphics --output-on-failure
DISPLAY=:1 ctest --test-dir build/refactor-release -L graphics --output-on-failure
cmake --build build/refactor-debug --target check-build --parallel
ctest --test-dir build/refactor-debug --parallel 8 -LE graphics --output-on-failure
DISPLAY=:1 ctest --test-dir build/refactor-debug -L graphics --output-on-failure
```

`:1` test sırasında kullanılan ayrı Xvfb ekranıdır; sonraki çalıştırmada kendi
geçerli X11/GLX ekranınızı kullanın. `known_issue` etiketli testler tam pakette
çalışır ve başarısızlık kodu üretir. `check` de bunları gizlemez; tam paket şu
an yeşil değildir. Onaylanan kapsam gereği mevcut davranış hataları düzeltilmedi.

Bulunan mevcut davranış hataları [olası hatalar](olasi_hatalar.md) dosyasında
tutulur. Bu çalışma yeni regresyonları düzeltir; mevcut hataları gizleyen
test beklentileri eklemez. Refactoring ve belge döngüsü tamamlandı; hata
düzeltme işleri sonraki çalışma için açık bırakıldı.
