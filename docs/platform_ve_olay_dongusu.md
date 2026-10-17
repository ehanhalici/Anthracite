# X11 platformu ve olay döngüsü

[platform.sats](../src/core_platform/platform.sats) `Plat` sahibini sunar;
[x11.sats](../src/core_platform/x11.sats) / [x11.cats](../src/core_platform/x11.cats)
Xlib/GLX köprüsüdür. Gerçek olay temsili C `anth_event` kaydı ve ATS `Ev`
varyantlarıdır; bütün yükleri taşıyan ayrı bir `Event` sum-type uygulaması yoktur.

## Yaşam döngüsü

`plat_open`, `plat_ok`, `platform_dimensions`, `plat_pending`, `plat_wait`,
`plat_next`, `plat_swap`, `plat_stop`, `plat_close` temel arayüzlerdir.
GLX bağlamı açıldıktan sonra `Rend` hazırlanır. Kapanışta render ve platform
kaynakları sırayla bırakılır. Ekran açılamaması yapılandırılmış hata üretir ve
platform kaynağı bırakıldıktan sonra `exit(1)` ile sonuçlanır (BUG-001 çözüldü).

[event_loop](../src/core_runtime/event_loop.dats) olayları bekler/yönlendirir;
[application](../src/core_runtime/application.dats) çalışma alanını yürütür.
[event_repaint](../src/core_runtime/event_repaint.dats) olayın yeniden çizim
isteyip istemediğini ayırır. Olay olmayan durumda bloke bekleme hedeflenir;
her ortamda tam yüzde sıfır CPU sayısal garantisi verilmez.

## Pano ve testler

[clipboard](../src/core_runtime/clipboard.dats) X11 seçim iletişimini;
[selftest](../src/core_runtime/selftest.dats) mevcut grafik test orkestrasyonunu taşır.
`event_repaint_contracts` on bir olay varyantını ve dört repaint birleştirmesini
sınar. Grafik selftest ayrıca pano, bekleme ve alt sistem sonuçlarını kontrol eder.

`runtime_selftest` font/belge/görsel/uygulama sonuçlarını pano, bekleme ve izlenen
canlı tampon bütçesi bayraklarıyla birleştirir; yalnız hepsi `1` ise başarı döner.
Başarısızlıkta `event=selftest status=failed` yazılır. `main` önce renderer ve
platformu kapatır, sonra başarısız selftest için `exit(1)` çağırır.

Test için geçerli X11/GLX ekranı gerekir. Grafik CTest sarmalayıcısı ekran
yokluğunu başarılı test saymaz; sonuç bayraklarını kontrol eder ve zaman aşımı uygular.
`selftest_no_display` ekran gerektirmeden hem normal başlatmanın hem `--selftest`
çağrısının tam olarak `1` döndürdüğünü denetler; sinyal veya zaman aşımı başarı
sayılmaz. `graphics_selftest_failure` boş çalışma dizininde göreli font yüklemesini
başarısız kılar; gerçek alt selftest ve toplam sonuç için `0` bayrağı/`exit(1)`
yolunu sınar. Bu testler üretim koduna hata enjeksiyonu anahtarı eklemez.
Eski selftest'in paylaşılan geçici yolları BUG-007'de izlenir.
