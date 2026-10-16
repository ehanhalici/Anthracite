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

## JPEG istisnası ve güvenlik sınırı

ATS JPEG çözümlemesi başarısızsa [C sarmalayıcısı](../src/data_image/img_jpg_prog.cats)
[gömülü stb_image kopyasını](../vendor/stb/README.md) çağırır. Yalnız JPEG etkin
olacak şekilde derlenir; C çıktısı `Buf` içine kopyalanır ve C tahsisi bırakılır.
Bu yüzden bütün görüntü işlemlerinin saf ATS2 olduğu iddiası doğru değildir.

Bozuk/kesilmiş girdiler, genişlik/yükseklik çarpımı ve başarısızlık yolları
ayrıca değerlendirilir (BUG-004). Lineer `Image` sahibi, C çözümleyicisinin
iç güvenliğinin statik ispatı değildir.

## Doğrulama

`workspace_image_contracts` ekran açmadan PNG/BMP/JPEG piksel ve boyutlarını,
boş girdi reddini, ölçeklemeyi ve geçersiz boyutta durumun korunmasını sınar.
Fixture dosyası benzersiz test dizinindedir; tahsis öncesi/sonrası sayaç denetlenir.
Mevcut `img_selftest` ayrıca grafik selftest içinden çalışır. Piksel ölçekleme ve upload
ayrı davranışlardır. Test fixture byte tablolarındaki sayılar dosya verisidir;
iş mantığındaki açıklamasız kapasite/alan sabitleriyle karıştırılmaz.
