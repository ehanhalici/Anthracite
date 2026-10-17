# Anthracite sistem tanımı

Anthracite ATS2 ile yazılmış yerel Markdown editörüdür. Pencere ve giriş
olayları X11/GLX, çizim OpenGL, dosya hizmetleri POSIX üzerinden yürür.
Tarayıcı veya GTK/Qt gibi widget çatısı kullanılmaz. Bu, işletim sistemi
kütüphanelerinden ya da gömülü C kodundan bağımsızlık anlamına gelmez.

## Uygulanmış yapı

| Katman | Sorumluluk |
|---|---|
| Bellek / airlock | Doğrusal tampon sahipliği ve denetlenen sınır dönüşümleri |
| Metin | UTF8, Unicode özellikleri, sınır algoritmaları, normalizasyon, bidi, script |
| Font | SFNT/OpenType doğrulama, glif ikame/konumlandırma, rasterizasyon ve atlas |
| Belge / AST | Gap buffer, satır/düğüm tabloları, düzenleme/geçmiş, Markdown ayrıştırma |
| Katlama / yerleşim | Bölge aralıkları, katlama tercihleri, görünürlük ve görsel satırlar |
| UI | Sekmeler, paneller, komutlar, menüler, dosya ağacı, arama ve çizim |
| Görsel | PNG/BMP/JPEG çözme, RGBA ölçekleme, GPU aktarımı |
| Runtime / OS / config | Olay döngüsü, pano, dosya hizmetleri ve oturum saklama |

Kaynak ve test alt grupları [rehber dizininde](README.md) bağlantılıdır.
`native_text_engine` CPU hattı ile `anthracite_host` nesneleri uygulama ve
entegrasyon testleri arasında paylaşılır. Büyük sahiplerin özel uygulama
grupları aynı ATS çeviri biriminde kalır.

## Tasarım hedefleri ve sınırlar

Hedefler düşük boşta işlemci kullanımı, öngörülebilir bellek, hızlı düzenleme ve
açık sahipliktir. Başlatma süresi, bellek miktarı ve kare hızı ölçüm koşulu olmadan
garanti edilmez. CommonMark/GFM/Obsidian sözdizimi için mevcut ayrıştırıcı ve
fixture kapsamı esas alınır; tam uyumluluk bağımsız corpus olmadan iddia edilmez.

Lineer tipler temsil edilen kaynak izinlerini denetler; bütün programın sıfır
çökme/sıfır UB kanıtı değildir. C ve harici kaynak sınırları ayrıca test edilir.
JPEG çözümleyicisi tamamen yerel ATS2 motoruna taşınmış (BUG-004 çözüldü), C `stb_image` yalnızca test orakılı olarak tutulmaktadır.

Geliştirme ilkeleri [skill.md](skill.md), sonraki işler [hata listesi](olasi_hatalar.md),
ölçüm ve tamamlanma durumu [çalışma kaydı](refactoring_durumu.md) içindedir.
