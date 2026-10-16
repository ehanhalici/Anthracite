# Bellek sahipliği ve güven sınırları

[mem.sats](../src/mem.sats) soyut doğrusal `Buf` arayüzünü;
[mem.dats](../src/mem.dats) kapasitesi statik indeksli `arrayptr` temsilini taşır.
`Buf` uzunluğu arayüzde dinamik `int` olarak tutulur; bütün çağıranların uzunluk
ve kapasitesi statik olarak kanıtlanmış gibi yorumlanmamalıdır.

## Birimler ve erişim

`buf_get`/`buf_set` bayt indeksi, `buf_get32`/`buf_set32` 32 bit kelime indeksi
alır. Kelime i, bayt `WORD32_BYTES*i` konumundadır. K alanlı kayıtta N'inci
kaydın F alanı kelime `N*K+F` olur. [Ortak birimler](../src/foundation/units.hats)
statik ifadelerde de kullanılan temsil sabitlerini tanımlar.

Kelime erişiminde negatif indeks ve kelimeden küçük kapasite reddedilir;
çarpımdan önce `i <= (capacity-WORD32_BYTES)/WORD32_BYTES` kontrolü yapılır.
ATS ve C ABI sarmalayıcıları aynı taşmasız reddetme politikasını kullanır.
`word_boundary_contracts` bunu `-fno-wrapv` ve UBSan altında sınar.

Mevcut erişim yordamları kapasite dışındaki bazı okumalar için sıfır döndürür,
bazı yazmaları yok sayar. Sessiz varsayımlarla iş mantığı kurulmaz; arayüzün
gerçek denetim politikası kaynak üzerinden değerlendirilir.

`buf_zero` kapasiteyi sıfırlar ve mantıksal uzunluğu sıfıra çeker. Geçerli
sıfırlanmış kayıt için `buf_ensure`, `buf_zero`, `buf_set_len` sırası kullanılır.
`!Buf` ödünçtür; `Buf` alan tüketici sahipliği devralır ve bırakır veya aktarır.

## Airlock ve sonlanma

[airlock.sats](../src/airlock.sats) `airlock_nat`, `airlock_pos`,
`airlock_below`, `airlock_word`, `airlock_span`, `airlock_i32` imzalarını sunar.
[C sınırı](../src/airlock.cats) çalışma zamanı denetimini yapar. Yakıt tavanı
`MAX_REC_FUEL = 268435456` değeridir. Azalan metrik sonlanmayı doğrular;
gerçek stack boyutu ve algoritmik sonuç için ayrı değerlendirme gerekir.

## Doğrulama

`core_contracts` bayt sırasını, işaretli kelimeyi, büyüme/sıfırlama yaşam
döngüsünü ve tahsis öncesi/sonrası sayacı sınar. `airlock_conformance` ve
taşma testleri sınır davranışlarını; negatif tip testleri sahiplik/aşama/alan
ihlallerini kontrol eder.

`mem_live()` yalnız sayaca kaydedilen tampon kapasitesini ölçer. C çalışma
zamanı, X11 ve GPU kaynakları kapsam dışındadır. Başlangıç grafik selftest'inde
gözlenen `1530113` bayt, bazı sahipler açıkken alınan tarihsel referanstır.
Grafik selftest ayrıca platform açıkken renderer öncesi ve renderer kapandıktan
sonraki sayacı karşılaştırır; `memory_ok=1` izlenen tamponların bu sınırda
başlangıç değerine döndüğünü gösterir, tüm sistem tahsisleri için ispat değildir.
