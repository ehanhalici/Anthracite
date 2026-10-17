# Metin ve Unicode motoru

Motor, depodaki [Unicode 18.0.0 verilerini](../vendor/unicode/18.0.0) kullanır;
sistem Unicode sürümüne veya ICU/Pango gibi bir metin kütüphanesine dayanmaz.
Veri sürümü güncellemesi bu refactoring'in kapsamı dışındadır.

| Kaynak grubu | Görev | Doğrulama |
|---|---|---|
| [source](../src/data_text/source) | Kaynak akışı ve alanlar | Metin/Unicode sözleşmeleri |
| [utf8](../src/data_text/utf8) | Katı çözümleme ve kaynak bayt aralığı | `utf8_conformance`, `utf8_flat_step` |
| [unicode](../src/data_text/unicode) | Özellik verisi, semboller ve sıralama | `unicode_contracts`, alan retleri |
| [grapheme](../src/data_text/grapheme) | UAX #29 grafem sınırları | `text_conformance` |
| [word_break](../src/data_text/word_break) | Kelime sınırları | `word_conformance` |
| [line_break](../src/data_text/line_break) | UAX #14 satır kesme | `line_conformance`, `line_contracts` |
| [normalization](../src/data_text/normalization) | NFC/NFD/NFKC/NFKD | Normalizasyon uyumluluk ve aşama testleri |
| [bidi](../src/data_text/bidi) | UAX #9 paragraf ve satır sıralama | Bidi karakter/sınıf/belge testleri |
| [script](../src/data_text/script) | Script özellikleri ve itemization | Script / script-items testleri |
| [arabic](../src/data_text/arabic) | Birleştirme ve hareke sırası | Arabic join/marks testleri |

## Akış ve sözleşmeler

UTF8 çözümü geçersiz girdilerde maximal-subpart davranışını ve orijinal bayt
aralıklarını korur. `utf8_encoding.hats` önek ve devam baytı sınırlarını isimlendirir.
Grafem, kelime ve satır motorları özellik sınıflarını kullanır; normalizasyon,
script ve bidi analizleri native shaping hattına veri sağlar.

Hangul ayrıştırma/birleştirme sabitleri hece/Jamo tabanları ile L/V/T
sayılarından türetilir. Kısıt ve faz tipleri yanlış alanların veya tamamlanmamış
ara yapıların kullanılmasını derleme aşamasında reddeder; dosyadan gelen
değerler için çalışma zamanı doğrulaması da gereklidir.

## Veri üretimi ve testler

[Unicode araçları](../tools/unicode) ve [script araçları](../tools/script)
CMake üzerinden ikili veri üretir. Üretilen `.bin` dosyaları derleme dizinindedir;
elle düzenlenmez. Uyumluluk testleri depodaki resmi test girdilerini kullanır.
Vaka sayıları veri sürümüne bağlıdır; değişken sayılar sabit başarı garantisi
yerine test çıktısından kaydedilir.

Kaynakları taşıdıktan sonra `cmake --build build --target check-build --parallel`
ile üreticiler ve tüm test yürütücüleri derlenir. Yalnız uygulamayı derlemek
`EXCLUDE_FROM_ALL` testlerini hazırlamaz.
