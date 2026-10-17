# Font, OpenType ve glif motoru

[data_font](../src/data_font) font dosyalarının doğrulanması, shaping,
rasterizasyon ve atlas sahipliğini yönetir. HarfBuzz/FreeType çağrısı yerine
projenin ATS uygulamaları kullanılır; FFI ve GPU sınırları ayrıca değerlendirilir.

## Gruplar

- [sfnt](../src/data_font/sfnt): tablo dizini, metrikler ve cmap doğrulaması.
  Dört baytlık tablo etiketleri okunabilir ASCII etiketlerinden üretilir.
- [opentype](../src/data_font/opentype): tablo/layout/context, GSUB, GPOS,
  GDEF, coverage ve lookup grupları; biçim doğrulama ve uygulama ayrıdır.
- [glyph](../src/data_font/glyph): koşular, seçim/geçişler, bağlam,
  ikame, konumlandırma ve ortak glif işlemleri.
- [native](../src/data_font/native): shape/text servisleri ve doğrusal cache sahipliği.
- [text](../src/data_font/text): span ve koşu geometrisi/ölçümü.
- [raster](../src/data_font/raster), [atlas](../src/data_font/atlas),
  [resources](../src/data_font/resources): outline/piksel üretimi, önbellek ve Font sahibi.
- [legacy](../src/data_font/legacy): mevcut uyumluluk/C köprüleri; saf ATS
  ispat kapsamındaymış gibi belgelenmez.

## Temel arayüz

[font.sats](../src/data_font/resources/font.sats) `font_open`/`font_free`,
`font_use_file`, `font_use_fallback_file`, `font_set_px`, `font_glyph`,
`font_draw_buf` ve `font_width_buf` işlemlerini sunar. `gmet` mevcut metrik
kaydıdır; belgede yeni bir `GlyphMetric` uygulaması varmış gibi gösterilmez.

`GlyphRun(phase)` gibi indeksli tipler ikame/konumlandırma/dondurma sırasını
denetler. Özel sahiplik sözleşmeleri ilgili grupların `private` bölümündedir.
`Font` temsili ve özel uygulama grupları aynı çeviri biriminde kalır.

GC'siz metadata/sonuç politikası: `SfntInfo` ve cmap, Font'un birincil/fallback
slotlarında düz `SfntMetadata` kayıtlarıyla saklanır; aynı kaydı kopyalamak
sahiplik veya tahsis üretmez. SFNT ayrıştırma/tablo, compound glif ve metin
servisi sonuçları lineerdir ve eşleşirken tüketilir. OpenType feature parametreleri
doğrulamadan sonra `ot_feature_params_dispose` ile bırakılır. Paint/hit/graph
istekleri düz kayıttır; kare/glif başına GC'siz kutu biriktirmez.

## Testler

[Font testleri](../tests/font) SFNT/cmap/compound glif, OpenType tabloları,
GSUB/GPOS, koşu/faz, sahiplik, native hat ve atlas davranışlarını kapsar.
Negatif derleme testleri [contracts](../tests/contracts) altındadır.
Gerçek font testleri ilgili CMake font yolları sağlandığında kaydedilir;
sentetik fixture testleri bunlardan ayrıdır. Grafik selftest ayrıca X11/GLX ister.
