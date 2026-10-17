# Görsel çözümleme ve ölçekleme

[image.sats](../src/data_image/image.sats) soyut doğrusal `Image` arayüzüdür.
Gerçek API `img_open`, `img_free`, `img_load`, `img_load_at`, `image_width`,
`image_height`, `img_resize` ve `img_upload` işlemlerinden oluşur. Görüntü
temsili herkese açık bir record değildir; `image_load_mem` gibi bir API yoktur.

## Akış

[image.dats](../src/data_image/image.dats) dosyayı okur, imzadan biçimi seçer,
çözümlenen RGBA tamponunu sahiplenir ve gerektiğinde ölçekler.
PNG, BMP ve JPEG uygulamaları kendi `.dats` dosyaları ve özel uygulama
gruplarındadır. `img_common` piksel ekleme yardımcısını taşır.

Başlıca politika sabitleri RGBA kanal sayısı, azami dosya baytı ve azami
görüntü boyutudur. İlk kapasite ile çözümlenen görüntünün gerçek boyutu farklıdır.
Dosya imzaları ve biçim durumları isimli sabitlerle temsil edilir.

## JPEG motoru ve güvenlik sınırı

JPEG çözümlemesi tamamen yerel ATS2 modüllerine ([private/img_jpg](../src/data_image/private/img_jpg))
taşınmıştır. Baseline, 8-bit extended sequential ve progressive JPEG akışları
(DQT, DHT, SOF0/SOF1/SOF2, DRI, SOS,
restart aralıkları, tek/çok kanallı MCU taramaları, 8x8 IDCT ve renk uzayı dönüşümü)
C fallback kullanılmadan doğrudan ATS2 içinde çözülür.

Üçüncü taraf `stb_image` başlığı ([vendor/stb](../vendor/stb/README.md)) yalnızca
test paketinde (`image_oracle_contracts`) referans karşılaştırma orakılı olarak
kullanılır; üretim JPEG yolu bu C çözücüsünü içermez. Uygulamanın C çalışma
zamanı, denetlenen FFI ve işletim sistemi/GPU bağımlılıkları devam eder.
BUG-004'teki C yedeği kaldırılmıştır. Çözülen tamponlar ATS lineer `Buf` ve
`Image` sahipliğindedir. `mem_live` aynı yaşam döngüsü noktalarında izlenen
tampon tahsislerini karşılaştırır; tek başına tüm uygulama için sızıntısızlık
veya keyfî JPEG girdilerinde algoritmik doğruluk kanıtı değildir.

Tek bileşenli sequential taramada MCU bir 8x8 bloktur; interleaved taramada
bileşenin H/V örnekleme katsayıları kullanılır. Sequential akışta bütün
bileşen taramaları tamamlanır. Restart işaretçisi yalnız devam eden taramadaki
MCU'lar arasında aranır; son MCU'dan sonra zorunlu değildir.

Renk seçimi bileşen kimliklerini, JFIF ve Adobe APP14 bilgisini izler.
Gri, doğrudan RGB, YCbCr, CMYK ve YCCK yolları ayrıdır; CMYK/YCCK dönüşümünde
dördüncü bileşen de yeniden örneklenir. Genel dikey örnekleme en yakın satırı,
iki kat büyütme ise stb ile aynı filtreyi kullanır. Başarılı `decode_jpg`
sonucunun uzunluğu `width * height * 4` bayttır; başarısızlıkta boyutlar ve
tampon uzunluğu sıfırdır. Destek sınırı 8-bit örnekler ve boyut başına 8192
pikseldir; bu sınır bütün JPEG çeşitlerinin desteklendiği anlamına gelmez.

## Doğrulama

`workspace_image_contracts` ekran açmadan PNG/BMP/JPEG piksel ve boyutlarını,
boş girdi reddini, ölçeklemeyi ve geçersiz boyutta durumun korunmasını sınar.
Fixture dosyası benzersiz test dizinindedir; tahsis öncesi/sonrası sayaç denetlenir.

`image_oracle_contracts` ve `jpeg_*` testleri C stb çıktısıyla bütün RGBA
baytlarını, boyutları, tampon uzunluğunu ve tahsis öncesi/sonrası sayacı denetler.
Sabit on milyon baytlık karşılaştırma kesmesi yoktur; test tam çıktı uzunluğunu
tarar. Bozuk girdiler ayrı ret testleridir. Veri kümesinin kapsamı ve yeniden
üretimi [JPEG test rehberinde](../tests/image/README.md) açıklanır.

Mevcut `img_selftest` ayrıca grafik selftest içinden çalışır. Piksel ölçekleme ve upload
ayrı davranışlardır. Test fixture byte tablolarındaki sayılar dosya verisidir;
iş mantığındaki açıklamasız kapasite/alan sabitleriyle karıştırılmaz.
