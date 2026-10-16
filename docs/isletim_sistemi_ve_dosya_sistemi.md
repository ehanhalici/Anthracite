# Dosya sistemi, yapılandırma ve tanılama

[fs.sats](../src/os/fs.sats) / [fs.cats](../src/os/fs.cats) POSIX köprüsüdür.
[fs_buf.dats](../src/os/fs_buf.dats) `Buf` kullanan yardımcıları uygular.
Ayrı `vfs.sats`/`vfs.dats` modülleri yoktur.

## Gerçek arayüz

`fs_open_read`, `fs_read`, `fs_close`, `fs_size`, `fs_mtime`, `fs_exists`,
`fs_isdir`, `fs_mkdir`, `fs_rename`, `fs_unlink`, `fs_rmdir` temel işlemlerdir.
`fs_write_buf(path, buffer, bytes)` yol alır ve `fs_atomic_write` üzerinden yazar;
ilk parametresi dosya tanıtıcısı değildir.

VFS yolu `fs_vfs_path` / `fs_vfs_buf` üzerinden üretilir. Belge tarafındaki
`doc_save_vfs` ve `doc_save_physical` yollarıyla birlikte değerlendirilir.
Geçici dosya, yazma/senkronizasyon ve yeniden adlandırma işlemlerinin hata
durumları kaynakta denetlenmelidir; yalnız `rename` kullanılması her donanım ve
güç kaybı senaryosu için veri kaybını matematiksel olarak sıfırlamaz.

## Ayarlar ve oturum

[conf.sats](../src/config/conf.sats) / [conf.dats](../src/config/conf.dats)
vault seçimi, oturum ve açık sekme/panel durumunu saklar. JSON ve oturum
yardımcıları özel uygulama gruplarına ayrılmıştır. `ANTHRACITE_CONFIG_DIR`
test ve ayrı kurulumlar için mevcut yapılandırma yolu geçersiz kılma anahtarıdır.

## Tanılama ve doğrulama

[diag.sats](../src/os/diag.sats), `.dats` ve `.cats` günlük seviyelerini ve
tanılama tamponunu taşır. Fonksiyon imzaları doğrudan bu sözleşmeden okunur;
eski belgelerdeki iki parametreli örnekler bütün log API'sini temsil etmez.

`workspace_config_contracts` benzersiz yapılandırma dizininde aktif vault ve
oturumun font, bölme, panel, açık klasör durumlarını round-trip ile doğrular.
Grafik selftest ayrıca belge/VFS ve dosya taşıma kontrollerini içerir.
Yeni testler benzersiz geçici kök kullanmalıdır; eski sabit fixture yolları
BUG-007 kapsamında giderilmiştir: grafik selftest `mkdtemp` ile özel bir
`/tmp/anthracite-selftest-*` kökü açar; alt testler yolları bu kökten üretir.
Fixture'lar inceleme için korunur. Sistem tahsisleri `mem_live` kapsamı dışındadır.
