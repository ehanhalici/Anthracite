# Yerel literal arama ve indeksleme

Kasa ve belge arama paneli ham kaynak üzerinde büyük/küçük harfe duyarsız
literal eşleme yapar. Sorgunun tamamı aranır: boşluk, `file:`, `[[` veya `.*`
operatör/regex değildir. Eşleşme için Doc/AST oluşturulmaz; bir sözcüğün içinde
geçen alt metin de eşleşir. Harici `rg` süreci veya worker thread kullanılmaz.

## Modüller ve veri akışı

| Katman | Sorumluluk |
|---|---|
| [literal](../src/search/literal) | Unicode case haritası, UTF8 ofset eşlemesi, KMP ve özgün byte aralıkları |
| [results](../src/search/results) | Salt metin/VFS okuma, bounded snippet, dosya grupları, satır/kolon hedefleri |
| [UI search](../src/ui_workspace/search) | Ortak boyama/hit geometrisi, varsayılan veri yolu, senkron test/araç yardımcıları |
| [search job](../src/ui_workspace/application/private/ui/search_job.hats) | App sahipli sorgu ömrü, iptal ve kareler arası ilerleme |

`LiteralPattern` case tablosu, katlanmış sorgu ve KMP failure tablosuna sahiptir;
yeni sorguda/eski işin iptalinde/kapanışta bırakılır. Kaynak metin ve ofset
tamponları dosya işinin sonunda serbest bırakılır. KMP eşleşme taraması doğrusal;
case lookup scalar başına O(log U), U sabit sürümün harita boyutudur. Bütün hat
keyfî Unicode tablo boyutu için O(N) diye sunulmaz; ek bellek kaynak uzunluğuna bağlıdır.

## Unicode ve özgün ofsetler

[Derleyici](../tools/search/compile_case_map.py), deponun Unicode 18
`UnicodeData.txt` upper/lower/title ilişkilerinden case eşdeğerlik sınıfları
üretir. Host Python'un Unicode sürümü kullanılmaz. `search-case-map.bin`
derleme varlığıdır; başlık/sürüm/boyut/sıra/scalar/idempotence denetimleri ATS'tedir.
Mevcut Türkçe `I/İ/ı/i` eşdeğerliği korunur. Her kaynak scalar tek scalar'a
eşlenir; NFKC/NFC normalizasyonu veya çok karaktere genişleme yoktur: `ß/ẞ`
eşleşir, `ss/ß` eşleşmez. Greek/Armenian/Georgian/Deseret dahil 2/3/4 byte
case ilişkileri sınanır. Bu sözleşme tam Unicode full-case-fold olarak adlandırılmaz.

Sonuç metni katlanmış kopya değildir. Başlangıç/bitiş ve kolon özgün UTF8 byte
ofsetleridir; `İ` gibi uzunluğu değişen eşlemede de doğru kalır. Snippet en fazla
80 byte öncesinden 240 byte sonrasına uzanır; kenarlar scalar sınırına hizalanır.
Sorgunun aynı satırdaki bütün ve çakışan eşleşmeleri korunur, sonuç sınırı uygulanır.

## Kapsam, çalışma ve sınırlar

Belge kapsamı etkin bölmedeki bellekteki belgeyi tarar; belge kimliği veya parse
generation değişince sonuç yenilenir. Kasa kapsamı her yeni sorguda `.md`
dosya kataloğunu yeniler. Açık dosyanın kaydedilmemiş metni önceliklidir; diğer
dosyalarda Doc yüklemeyle aynı nonempty VFS shadow politikası, ardından fiziksel
kaynak kullanılır. Katalog taraması sembol/AST indeksleme değildir.

UI işi dosyalar arasında kontrol edilen 4 ms esnek bütçeyle takip karelerine
ayırır; işler beklerken yeni giriş gerekmez, tamamlanınca olay beklemesine döner.
Katalog oluşturma, tek dosya okuma/katlama ve GPU/OS çağrıları atomiktir; 4 ms
kesin kare süresi veya paralel CPU çalışması garanti edilmez. Değişmeyen
`EditNone` olayları sorguyu yeniden başlatmaz. Eski sorgu işi yeni metinle karışmaz.

Katalog sınırı 20.000 dosya/12 dizin derinliği, sonuç sınırı dosya başlıkları
dahil 200 satırdır. Tek kaynak sınırı 16 MiB, sorgu sınırı 4 KiB'dir. Sonuç/kaynak
sınırı, katalog truncation veya okuma hatası kısmi sonuç olarak gösterilir;
başlatma/veri hatası ayrı durumdur. Varsayılan veri yolu diğer native varlıklar
gibi `ANTHRACITE_TEXT_DATA` altındadır.

## Panel ve hedefe gitme

Kasa/Belge düğmeleri başlıkla çakışmaz; dar panelde alt alta geçer. Satır
yüksekliği gerçek font metriklerinden türetilir. Boyama, tıklama ve kaydırma aynı
geometriyi kullanır; her sonuç kendi satır clip'iyle sınırlandırılır. Dosya
başlığı grubu açar/kapatır, alt eşleşme hedef dosya ve özgün satır/kolona gider.
Mevcut sekme yeniden kullanılır; belge kapsamı yanlışlıkla başka sekme açmaz.
Enter/Shift+Enter başlıkları atlayarak eşleşmeler arasında döner.

Hedefin katlanmış ataları açılır. Kaydırma isteği gerçek layout hazırlandıktan
sonra uygulanır; satır bir saniye mor vurgulanır. Olay beklemesi flash sonuna
kadar süreli bekler ve giriş olmasa da temizleme karesi üretir; animasyon için
sürekli busy-loop yapılmaz.

## Eski indeks API'leri ve testler

`ix_store`, `ix_fold`, `ix_query`, `ix_build`, `ix_match` dosya/sembol/Bloom ve
eski yapılandırılmış sorgu sözleşmelerini korur; `ix_selftest` bunları sınar.
Bu önek/filtre ayrıştırıcısı UI'nin varsayılan literal sorgu yolu değildir.
UI kapalıyken arka planda AST indeksleme adımı çalıştırılmaz.

`literal_search_contracts`, `search_results_contracts`, `search_geometry_contracts`
ve `search_case_map_compiler_contracts` case ilişkileri, özgün ofsetler, literal
önekler, çakışmalar, gruplama/hit eşlemesi ve zamanlayıcı sınırlarını denetler.
Grafik selftest ayrıca query iptali, EditNone kararlılığı, AST'siz tarama, iki
kapsam, grup tıklaması ve gerçek layout sonrası hedefe kaydırma/flash'ı çalıştırır.
`search_performance VAULT QUERY` salt okunur benchmark'ı içerik yazdırmadan süre,
sonuç satırı, read-byte ve AST/Doc sayaçlarını raporlar. Test başarısı tüm
belge/dosya sistemi durumlarının eksiksiz ispatı değildir.
