# ATS2 geliştirme ve refactoring kuralları

Bu belge proje içi geliştirme rehberidir. Özel değişmezler
[ajan kurallarında](../.agents/rules) tutulur; gerçek uygulama sınırları ilgili
alt sistem rehberinden ve `.sats` sözleşmesinden okunur.

## Tipler ve güven sınırı

- ATS üretimi önce `patsopt -tc`, sonra C üretimi üzerinden geçer.
- `$UNSAFE`, denetlenmeyen `castfn` ve ispatı atlayan dönüşümler eklenmez.
- Mevcut opak sahipler `Buf`, `Doc`, `Font`, `Image`, `Rend`, `Plat`, `App`;
  özel temsil aynı sahip içinde kalır. Kaynağı bölmek yeni `assume` gerektirmez.
- Dış tamsayılar `airlock_*` kapılarından geçer. Dinamik denetim, C ABI,
  işletim sistemi ve GPU güven sınırına dahildir. JPEG algoritması ATS2 içindedir;
  [C stb](../vendor/stb/README.md) yalnız test orakılıdır, üretim yedeği değildir.
- Sonlanma metriği azalan çağrıları doğrular; tek başına yığın taşmasını veya
  algoritmik doğruluğu kanıtlamaz. Yapay `recfuel` bütçeleri
  `recursion_fuel_available` üzerinden denetlenir ve tükenince abort edilir
  (BUG-003 çözüldü); doğal sayaçların sıfırda normal bitmesi farklı bir politikadır.

## Okunabilirlik ve modüller

- Fonksiyon tek sorumluluk taşır. Gövde en fazla 20 kod satırıdır; imza,
  boş satır, yorum ve dış `let`/`end` sarmalayıcısı sayılmaz. Sınır satır
  sıkıştırılarak sağlanmaz; ayrılabilir işler yardımcı fonksiyonlara çıkarılır.
- Anlamlı sayılar birimleri belirtilmiş sabitlere veya açıklayıcı hesaplara taşınır.
  `*_WORDS`, `*_BYTES`, `*_PIXELS`, `*_MS` birbirinin yerine kullanılmaz.
- Sıfır, bir, basit sayma adımları ve açık test/format verileri bağlamları zaten
  açıksa kalabilir. Bir durum kodu olan `0/1` ise isimli sabit veya tip ister.
- UTF8, AST, GSUB, GPOS gibi alan terimleri korunur; belirsiz fiiller ve
  kısaltılmış yardımcılar açılır. `buffer_append_string` ekler; tamponu temizlemez.
- İlk tahsis kapasiteleri isimli politikalardır. Kaydı oluşturan alan ve kelime
  sayısından bayt boyutunu türetin; aynı boyutu farklı yerlerde tekrar tanımlamayın.
- Konu klasörlerinde `.sats` ve uygulamaları birlikte tutun. Özel `.hats`
  grupları sahibinin çeviri birimine aittir; bağımsız bağlanan modüller değildir.
- Kaynak taşındığında ATS yüklemeleri, C başlıkları, CMake grupları, araçlar,
  negatif derleme testleri ve belge bağlantıları birlikte güncellenir.

## Sahiplik, kayıtlar ve performans

`!Buf` ödünç verir; `Buf` tüketen arayüz sahipliği aktarır. Kaynak tam olarak
bir kez bırakılır. `buf_get32`/`buf_set32` kelime indeksi alır; `buf_len`,
`buf_ensure` ve bayt erişimi bayt birimindedir. `buf_zero` uzunluğu sıfırlar;
sıfırlanmış geçerli kayıt için önce sıfırlayın, sonra `buf_set_len` çağırın.

Görsel izdüşümden önce katlama görünürlüğü eşzamanlı güncellenir. Satır ve
AST eşleştirmelerinde monotonik imleç veya aralık araması kullanılır. Önbellek
isabetinde belgeyi yeniden açmayın; tahliye ve kapanışta `Doc` sahipliğini bırakın.
Karmaşıklık bütün çağrı zinciri için değerlendirilir: katlama bölgesi sıralaması
32 bit sahip anahtarında kararlı dört geçişli radix sıralamadır (O(R), ek O(R)
bellek). Kararlılık ve döngü adımları `region_sort_contracts` ile korunur.

## Test kapısı ve belge eşlemesi

`check-build` bütün yürütücüleri derler, `check` ardından CTest'i çalıştırır.
Grafik testlerde geçerli ekran gerekir. Sonlu durum matrislerini tamamen tarayın;
parametreli/büyük uzaylarda sınır, özellik, uyumluluk ve negatif tip testlerini
birleştirin. Test başarısı keyfî girdiler için kusursuzluk iddiası değildir.

Belleği aynı yaşam döngüsü noktalarında karşılaştırın. `mem_live` yalnız proje
sayacına kaydedilmiş tahsisleri ölçer; X11/GPU/stb tahsislerini kapsamaz.
`live=1530113` başlangıç ortamında gözlenen referanstır, evrensel değişmez değildir.

Bulunan eski davranış hatalarını [hata listesine](olasi_hatalar.md) kanıt ve
yeniden üretmeyle yazın. Refactoring regresyonlarını düzeltin; eski hataları
onaylanmamış davranış değişikliğiyle kapatmayın. Belgelerde bulunmayan API'ler
uygulanmış gibi gösterilmez; tasarım hedefleri ayrıca etiketlenir.
