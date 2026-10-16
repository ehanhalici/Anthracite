# Katlama bölgesi modeli

[fold_region.sats](../src/data_ast/folding/fold_region.sats) satır tabanlı FRT
(Fold Region Table) arayüzüdür. Her kayıtta sahibi olan satır, özel bitiş satırı,
sahibin kaynak bayt ofseti ve tür bulunur. Kelime alanları `FR_*` sabitleriyle,
bayt boyutu `FR_ENTRY_WORDS * BYTES_PER_WORD` ile ifade edilir.

## Sınırlar ve durum

- Başlık bölgesi aynı veya daha üst seviyedeki sonraki başlığa ya da EOF'a kadar sürer.
- Girinti bölgesi gerçek alt satırları kapsar; boş satırlar sınırı tek başına kesmez.
- Çok satırlı kod/alıntı/callout/frontmatter bağlamları ayrı ele alınır;
  içlerindeki `#` işaretleri başlık olarak taranmamalıdır.
- Tab görsel girintide dört sütun kabul edilir; bu mevcut davranıştır.
- `folds` kullanıcının tercihlerini, `hidden` türetilen görünürlüğü tutar.
  Normal geçiş `doc_toggle`, alt ağaç geçişi `doc_toggle_deep` üzerinden yapılır.
- Yığından çıkan öğenin en uzak alt satırı üst öğeye aktarılır
  (`stack_propagate_last`); aksi halde iç içe bölge eksik kapanır.

`buf_zero(hidden)` uzunluğu sıfırlar; ardından geçerli bayt uzunluğu atanır.
Katlama görünürlüğü görsel izdüşüm öncesinde senkronize edilir. Üst bölgeyi
açmak alt bölgenin kullanıcı tercihlerini silmez.

## Karmaşıklık

Satır/yığın taraması monotonik ilerler. Bölge tablosu 32 bit sahip anahtarına göre
kararlı dört geçişli radix sıralama ile O(R) zamanda, O(R) ek bellekte düzenlenir.
Eşit sahiplerde eski sıra korunur. `region_sort_contracts` gerçek döngü adımlarını,
tam kayıt taşımayı ve kararlılığı sınar; BUG-006 çözülmüştür.

## Testler

[tests/folds](../tests/folds) altında 12 Markdown fixture'ı ve beklenen bölge
tabloları vardır: paragraf/liste, girintili devam, iç içe liste, durum koruma,
başlık hiyerarşisi, kod içi diyez, callout/alıntı, boş satır, tab girintisi,
derin katlama, ofset kayması ve yaprak madde.

`fold_contracts` her bölgenin tek başına katlanmasında görünürlük maskesini
`owner < line < end` aralık modeliyle karşılaştırır; açıldığında maske temizliğini
ve sahiplik sayacını denetler. `.golden` dosyaları bölge sınırlarının regresyon
kontrolüdür. Mevcut belge selftest'i ayrıca üst/alt durum, derin geçiş ve ofset
kaydırma işlemlerini sınar; fixture adı tek başına bütün işlem dizisinin
exhaustive testi anlamına gelmez.

`ctest --test-dir build -R '^fold_' --output-on-failure` paketi çalıştırır.
`./build/anthracite --fold-dump dosya.md` ekran açmadan mevcut ayrıştırma ve
katlama dökümünü verir; çıktı içindeki sabit hiyerarşi örnekleri genel oracle değildir.
