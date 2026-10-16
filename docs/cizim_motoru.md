# OpenGL çizim motoru

[render.sats](../src/core_render/render.sats) `Rend` sahibini ve çizim API'sini,
[gl.sats](../src/core_render/gl.sats) / [gl.cats](../src/core_render/gl.cats)
OpenGL sınırını taşır. Bağlam platform katmanında oluşturulur; bu rehber
uygulanmamış bir EGL veya scissor-yığını arayüzü tarif etmez.

## Gerçek arayüz ve kayıt düzeni

`rend_open`/`rend_close`, `rend_begin`, `rend_flush`, `rend_rect`, `rend_quad`,
`rend_quad_pixels`, `rend_scissor`, `rend_scissor_off`, `rend_capture` ve
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
Scissor koordinatları ekran/panel durumuna göre ayarlanır; push/pop yığını yoktur.
GL kaynakları sahibinin kapanışında bırakılır; `mem_live` GPU belleğini ölçmez.

Grafik selftest X11/GLX altında gerçek başlangıç/çizim/kapanış yolunu çalıştırır.
CPU testleri vertex alanlarının isimlendirilmesini tek başına ekran doğruluğu
kanıtı yapmaz. V-Sync, sürücü ve pencere sistemi davranışları ölçüm bağlamında değerlendirilir.
