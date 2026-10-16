# Mimari ve geliştirme rehberleri

Bu belgeler güncel kaynak düzenini ve doğrulama sınırlarını açıklar.
Uygulanmış davranış, tasarım hedefi ve ölçüm sonucu birbirinin yerine kullanılmaz.

| Alan | Rehber | Kaynak |
|---|---|---|
| Genel tasarım | [Sistem tanımı](tanim.md) | [src](../src) |
| Belge / ayrıştırma | [AST](ast_sozdizim_agaci.md) | [data_ast](../src/data_ast) |
| Katlama | [Katlama modeli](katlama_ozelligi.md) | [folding](../src/data_ast/folding) |
| Çalışma alanı | [UI](ui_kullanici_arayuzu.md) | [ui_workspace](../src/ui_workspace) |
| GPU çizimi | [Render](cizim_motoru.md) | [core_render](../src/core_render) |
| Unicode | [Metin](metin_ve_unicode_motoru.md) | [data_text](../src/data_text) |
| Font / shaping | [Glif motoru](yazi_tipi_glif_motoru.md) | [data_font](../src/data_font) |
| Native entegrasyon | [Metin hattı](native-text-engine.md) | [native](../src/data_font/native) |
| Görseller | [Görsel motoru](gorsel_isleme_motoru.md) | [data_image](../src/data_image) |
| Platform / olaylar | [Platform](platform_ve_olay_dongusu.md) | [core_runtime](../src/core_runtime) |
| Bellek / FFI | [Güvenlik sınırları](bellek_ve_guvenlik_mimarisi.md) | [mem.sats](../src/mem.sats) |
| Dosya / ayarlar | [OS ve dosya sistemi](isletim_sistemi_ve_dosya_sistemi.md) | [os](../src/os) |
| Arama | [İndeksleme](arama_ve_indeksleme.md) | [search](../src/search) |

[Kod kuralları](skill.md), [ilerleme kaydı](refactoring_durumu.md) ve
[hata listesi](olasi_hatalar.md) çalışma sırasında birlikte güncellenir.
`.agents/rules` belirli bellek, sahiplik, önbellek ve karmaşıklık kurallarını taşır.

## Doğrulama

Önce `cmake --build build --target check-build --parallel`, ardından CTest
çalıştırılır. `check` hedefi iki işlemi birleştirir. Grafik etiketli testler
X11/GLX ekranı ister; CPU paketini `ctest --test-dir build -LE graphics
--output-on-failure` ile ayrı çalıştırabilirsiniz.

Test sayısı CMake yapılandırmasındaki isteğe bağlı fontlara göre değişebilir.
Başlangıç ölçümü 77 testtir; güncel sonuç ve ortam ilerleme kaydında tutulur.
`--selftest` bütün alt selftest ve sağlık bayrakları başarılıysa `0`, bir denetim
başarısızsa `1` döndürür. Ekran açılamaması da normal başlatmada ve selftest'te
`1` üretir (BUG-001 çözüldü). Grafik CTest sarmalayıcısı çıkış koduna ek olarak
sonuç satırlarını denetler; ekransız hata yolu ayrı CPU testiyle sınanır.
