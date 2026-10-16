# Native metin hattı ve uygulama entegrasyonu

Uygulama başlangıcında [text_engine_startup](../src/core_runtime/text_engine_startup.dats)
veriyi ve fontları yükler. Ortam yolları [şablonda](../src/core_runtime/text_engine_paths.dats.in)
tanımlıdır: `ANTHRACITE_TEXT_DATA`, `ANTHRACITE_UNICODE_SOURCE`,
`ANTHRACITE_PRIMARY_FONT`, `ANTHRACITE_ARABIC_FONT`; `ANTHRACITE_FONT`
birincil font için mevcut geri dönüş anahtarıdır.

## Paylaşılan hat

[Native text](../src/data_font/native/text) kaynak analizi, script/bidi
bağlamı, kapsama ve shaping orkestrasyonunu;
[native shape](../src/data_font/native/shape) dönüşüm planı/çıktılarını taşır.
Metin/Unicode, OpenType ve glif modülleri bu CPU hattında birleşir.

`native_text_engine` nesne hedefi uygulama ile uyumluluk yürütücülerince
paylaşılır. UI/OS/GPU tarafı `anthracite_host` nesnelerinde tutulur; testler kendi
giriş noktalarını sağlar. Test fixture'ları üretim CPU motoruna eklenmez.

## Ekran koordinatları

[visual](../src/ui_workspace/visual) ve [belge yerleşimi](../src/data_ast/layout)
sarılmış satırları, kaynak/görsel ofset dönüşümünü, hit-test ve dikey navigasyonu
paylaşır. Katlama görünürlüğü görsel izdüşüm öncesi güncellenir; önbellek anahtarı
belge ve font/geometri sürümlerini kapsar.

`native_text_assets_conformance`, `native_text_analysis_conformance`,
`native_text_shape_conformance`, `source_edit_conformance` ve font paketleri
bu katmanları doğrular. Üretimde hazır olma ve performans, yalnız test sayısına
veya eski bir ölçüme bakılarak garanti edilmez. Güncel sonuçlar çalışma kaydındadır.
