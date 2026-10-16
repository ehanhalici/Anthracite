# Belge modeli, AST ve ayrıştırma

[Doc arayüzü](../src/data_ast/document/doc.sats) doğrusal belge sahibini,
düzenleme/geçmiş, satır/düğüm sorguları ve katlama işlemlerini sunar.
[Doc uygulaması](../src/data_ast/document/doc.dats) özel `.hats` gruplarını
aynı çeviri biriminde birleştirir; iç temsil dışa açılmaz.

## Kaynak yapısı

| Grup | İçerik |
|---|---|
| [document](../src/data_ast/document) | Gap buffer, tablolar, sahiplik ve mevcut belge işlemleri |
| [editing](../src/data_ast/editing) | Native metinle kaynak düzenleme/navigasyon köprüsü |
| [parser](../src/data_ast/parser) | Belge, blok ve satır içi ayrıştırma |
| [syntax](../src/data_ast/syntax) | AST sözleşmeleri, döküm ve doğrulama |
| [folding](../src/data_ast/folding) | Bölge tablosu ve görünürlük |
| [layout](../src/data_ast/layout) | Satır/düğüm ölçümü ve görsel satırlar |
| [selftest](../src/data_ast/selftest) | Mevcut AST selftest paketi |

## Temsil ve değişmezler

Düğüm kayıtlarında `AST_NODE_WORDS` ve `NF_*` alan sabitleri kullanılır.
`buf_get32` kelime indeksi alır; kayıt bayt boyutu kelime sayısından türetilir.
Gap buffer ve satır ofsetleri düzenlemelerle güncellenir; artımlı ayrıştırma
yeniden eşzamanlama sınırlarını kullanır. Her düzenlemenin O(1) veya yalnız
tek düğümle sınırlı olduğu iddia edilmez.

`doc_insert`, `doc_backspace`, `doc_delete_range`, `doc_undo`, `doc_redo`,
`doc_load`, `doc_save` gerçek arayüzlerdir. Ham kaynak bayt ofsetleri Unicode
skalar veya görsel sütun indeksleriyle karıştırılmaz. Native düzenleme katmanı
grafem sınırlarını kullanır.

## Yerleşim ve doğrulama

Satır/düğüm yerleşim kayıtları isimli kelime alanlarıyla okunur.
Gizli satırların adımı sıfırdır; katlama tercihi ve görünürlük ayrı tutulur.
Önbellek eşleşmesinde belge/geometri durumu dikkate alınır.

`core_contracts` kayıt/önbellek sınırlarını, `source_edit_conformance`
düzenleme ve görsel entegrasyonu, AST selftest ayrıştırma/geçmişi sınar.
`workspace_document_contracts` sekiz ASCII/Unicode/Markdown girdisini bayt bayt
ekleyerek çıkan ağacı tam ayrıştırma referansı ve AST doğrulayıcısıyla karşılaştırır.
Başlık/liste işaretlerindeki mevcut eşdeğerlik hatası BUG-011 olarak kaydedilmiştir;
bu test doğru beklentiyle kırmızı kalır.
[Katlama testleri](../tests/folds) bölge sınırları ve görünürlük için bağımsızdır.
Mevcut sorunlar [hata listesinde](olasi_hatalar.md) tutulur.
