# Gömülü JPEG yedek çözümleyicisi

`stb_image.h`, başlangıç deposundaki `src/data_image/img_jpg_prog.cats`
dosyasından gövdesi değiştirilmeden ayrılan stb_image v2.29 kopyasıdır.
Özgün telif ve MIT / public domain lisans metinleri başlığın sonunda korunur.

Proje sarmalayıcısı `src/data_image/img_jpg_prog.cats`, yalnız JPEG desteğini
etkinleştirir. ATS JPEG çözümlemesi başarısız olduğunda bu yedek çağrılır;
dönen RGBA pikselleri sahipliği ATS tarafından yönetilen `Buf` içine kopyalanır
ve C tahsisi `stbi_image_free` ile bırakılır.

Bu üçüncü taraf C kodu ATS'nin statik ispat kapsamına ve `mem_live()` sayacına
dahil değildir. ATS2'ye yeniden yazılması bu refactoring'in kapsamı dışındadır;
bilinen inceleme başlıkları `docs/olasi_hatalar.md` dosyasındadır.
