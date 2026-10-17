# OpenGL çizim motoru

[render.sats](../src/core_render/render.sats) `Rend` sahibini ve çizim API'sini,
[gl.sats](../src/core_render/gl.sats) / [gl.cats](../src/core_render/gl.cats)
OpenGL sınırını taşır. Bağlam platform katmanında oluşturulur; EGL yolu yoktur.

## Gerçek arayüz ve kayıt düzeni

`rend_open`/`rend_close`, `rend_begin`, `rend_flush`, `rend_rect`, `rend_quad`,
`rend_quad_pixels`, `rend_clip_push`, `rend_clip_pop`, `rend_scissor`, `rend_scissor_off`, `rend_capture` ve
`rend_blur_rect` mevcut işlemlerdir. Doku yükleme/güncelleme/bırakma aynı
arayüzdeki `rend_tex_*` fonksiyonlarıyla yapılır.

[render_layout.hats](../src/core_render/render_layout.hats) vertex düzeninin
tek referansıdır: pozisyon için iki, renk için dört, doku koordinatı için iki
float. Böylece vertex sekiz float / 32 bayttır; attribute ofsetleri pozisyon,
renk ve doku alan sayılarından hesaplanır. Eski belgelerdeki X/Y/U/V/R/G/B/A
sıralaması gerçek attribute düzeniyle uyuşmuyordu.

## Yaşam döngüsü

Quad verileri batch tamponunda birikir; doku/çizim durumu değişimi veya doluluk
flush gerektirebilir. Bir belgenin tek draw call ile çizildiği garanti edilmez.
Rend sahipli clip yığını `rend_clip_push` ile istenen dikdörtgeni ebeveynle
kesiştirir; boş kesişim boş kalır. Push/pop önce batch'i flush eder; pop önceki
clip'i geri yükler, köke dönünce scissor kapanır. `rend_begin` derinliği sıfırlar.
UI yalnız bu yığın arayüzünü kullanır; eski ham `rend_scissor/off` çağrıları
uyumluluk için kalır, iç içe UI alanları için kullanılmamalıdır. Düğüm/sekme
kendi clip'ini büyüterek üst panel alanını boyayamaz (BUG-019 çözüldü).
GL kaynakları sahibinin kapanışında bırakılır; `mem_live` GPU belleğini ölçmez.

Grafik selftest X11/GLX altında gerçek başlangıç/çizim/kapanış yolunu çalıştırır.
CPU testleri vertex alanlarının isimlendirilmesini tek başına ekran doğruluğu
kanıtı yapmaz. V-Sync, sürücü ve pencere sistemi davranışları ölçüm bağlamında değerlendirilir.
`native_graphics_contracts` ebeveyni büyütmeye çalışan çocuk, boş kesişim ve
pop sonrası geri yükleme durumlarını gerçek GPU piksel okumalarıyla denetler.
