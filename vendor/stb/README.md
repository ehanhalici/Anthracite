# Gömülü JPEG test orakılı

`stb_image.h`, başlangıç deposundaki `src/data_image/img_jpg_prog.cats`
dosyasından gövdesi değiştirilmeden ayrılan stb_image v2.29 kopyasıdır.
Özgün telif ve MIT / public domain lisans metinleri başlığın sonunda korunur.

Üretim kodu (`src/data_image/image.dats`, `src/data_image/img_jpg.dats`),
`stb_image.h` başlığına bağımlı değildir; JPEG çözümlemesi tamamen yerel
ATS2 modüllerine taşınmıştır.

`stb_image.h`, yalnızca `tests/image/test_jpg_oracle.dats` testinde
saf ATS2 JPEG çözümleyicisinin piksellerini C başlığının çıktısıyla
karşılaştırmak ve bit-exact denkliği denetlemek için referans orakıl olarak
tutulmaktadır. Üretim ikili dosyasına bağlanmaz.

ATS2 portunun Huffman, IDCT, yeniden örnekleme ve renk dönüşümü algoritmaları
bu sürümü temel alır. Özgün telif ve lisans bildirimi yukarıdaki başlığın
sonundadır; ATS2'ye taşıma tüm algoritmik özelliklerin ispatlandığı anlamına gelmez.
