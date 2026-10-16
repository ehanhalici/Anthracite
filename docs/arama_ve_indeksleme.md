# Yerel arama ve indeksleme

[search](../src/search) yerel dosya/sembol indeksini ve sorgu eşlemesini taşır.
Mevcut uygulama için `ix_ripgrep`, `search_workspace_start` veya asenkron
`rg` alt süreci yoktur; önceki belgelerdeki açıklama uygulamayla uyuşmuyordu.

## Modüller

- `ix_store`: dosya/sembol kayıtları ve dosya başına Bloom filtresi.
- `ix_fold`: arama için metin katlama ve kaynak ofset eşlemesi.
- `ix_query`: sorgu terimleri; düz metin, `#`, `[[`, `h:`, `file:`, `task:`, `code:`.
- `ix_build`: dosya tarama ve AST üzerinden sembol/indeks üretimi.
- `ix_match`: terim, dosya ve sembol eşleme; sonuç ofsetleri.
- `ix_test`: mevcut Türkçe katlama, sorgu ve filtre selftest'leri.

[UI arama grubu](../src/ui_workspace/search) sonuçları panelle birleştirir.
Katlama tercihlerinin ve eşleşmeye gitme davranışının gerçek akışı UI/belge
tarafından okunur; uygulanmamış otomatik açma API'leri varsayılmaz.

## Kayıt ve sorgu sözleşmesi

Dosya/sembol kayıtlarında alan indeksleri ve stride sabitleri kullanılır;
bayt boyutu stride ile `WORD32_BYTES` çarpımından türetilir. Bloom bit sayısı
bayt boyutundan hesaplanır. Hash katsayıları ve bit konumu hesabı isimlidir;
bit maskesi sıralı sayı dalları yerine kaydırmayla üretilir.

Sorgu önekleri sayısal karakter zincirleri yerine okunabilir metinlerden
eşleştirilir. Alıntılı/alınmamış terim ayrıştırma ile terim kaydı üretimi ayrıdır;
mevcut işlem sırası ve seri durum kodları korunur.

## Testler

`core_contracts` kayıt sınırlarını, alan izolasyonunu ve bütün bayt değerleri
boyunca dosyalar arası Bloom izolasyonunu sınar. Mevcut `ix_selftest` grafik
selftest'in uygulama paketinde çalışır. Tüm indeksleme uzayının bu örneklerle
tamamen tarandığı veya O(1) ek bellek kullanıldığı iddia edilmez.
