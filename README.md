# Anthracite

Anthracite, Linux için yazılmış yerel bir **Markdown not alma editörüdür**.
Tarayıcı motoru, Electron ya da GTK/Qt gibi bir arayüz çatısı kullanmaz; pencereyi
X11/GLX ile açar, her şeyi OpenGL ile kendisi çizer. Hedefi hızlı açılan, boşta
neredeyse hiç işlemci harcamayan ve büyük notlarla dolu klasörlerde de akıcı kalan
sade bir editör olmaktır.

## Amaç

- Markdown dosyalarını yazmak, düzenlemek ve bir klasörü (vault) not defteri gibi
  gezmek.
- Sekmeler, bölünmüş görünüm, dosya ağacı, belge içi katlama ve vault genelinde
  arama.
- Görsel (PNG/BMP/JPEG) gömme, çok dilli metin (Unicode, çift yönlü metin, Arapça
  bağlamsal şekillendirme) ve gerçek font şekillendirme desteği.
- Bunların hepsini mümkün olan en az dış bağımlılıkla sağlamak.

## Sistem tasarımı

Anthracite [ATS2/Postiats](http://www.ats-lang.org/) ile yazılmıştır. ATS2'nin
bağımlı ve doğrusal (linear) tipleri sayesinde bellek sahipliği, tampon sınırları ve
durum geçişleri gibi kurallar mümkün olduğunca çalışma zamanında değil, **derleme
sırasında** denetlenir. Çöp toplayıcı yoktur; bellek sahipliği tiplerle açıkça
taşınır.

Bağımlılık anlayışı: ihtiyaç duyulan şey, işletim sisteminin sunmak zorunda olduğu
şey değilse projenin içinde yazılır.

| Alan | Dışarıdan alınan | Projenin kendisinin yazdığı |
|---|---|---|
| Pencere / girdi | X11 (`libX11`, `libXext`) | Olay döngüsü, pano, odak ve bölme yönetimi |
| Çizim | OpenGL (`libGL`) | Arayüz bileşenleri, metin ve görsel çizimi |
| Metin | – | UTF-8, Unicode özellikleri, normalizasyon, satır/kelime sınırları, bidi |
| Font | – | TTF/OTF (SFNT) ayrıştırma, GSUB/GPOS şekillendirme, rasterleştirme, glif atlası |
| Görsel | – | PNG, BMP ve JPEG çözücüleri |
| Markdown | – | Ayrıştırıcı, sözdizimi ağacı (AST), düzenleme/geri alma, katlama, yerleşim |
| Arama | – | Vault geneli, kareler arasında ilerleyen literal arama |

Yani FreeType, HarfBuzz, ICU, bir görsel kütüphanesi ya da bir GUI toolkit'i yoktur.
Gerçekte bağlanılanlar yalnızca `libm`, X11 ve OpenGL'dir. C ile yazılmış küçük
kısımlar (sistem çağrıları, X11/GL köprüsü) denetlenen bir FFI sınırının arkasında
tutulur. `vendor/` altındaki `stb` yalnızca testlerde karşılaştırma ölçütü olarak
kullanılır, uygulamaya girmez.

Fontlar derleme sırasında çalıştırılabilir dosyanın içine gömülür; çalışırken ayrı
bir `fonts/` dizini gerekmez. Font bulunmazsa sistem varsayılanı (fontconfig)
kullanılır.

Kaynak ağacı konuya göre bölünmüştür (`src/data_text`, `data_font`, `data_ast`,
`data_image`, `core_render`, `core_runtime`, `ui_workspace`, `search`, `os`,
`config`). Ayrıntılar için [docs/README.md](docs/README.md) dizinine bakın.

## Derleme

Gereksinimler [`shell.nix`](shell.nix) içinde tanımlıdır (ATS2, Clang, lld, CMake,
X11, OpenGL):

```sh
nix-shell
./compile.sh -r    # Release derle ve çalıştır
./compile.sh -d    # Debug derle ve çalıştır
```

`compile.sh` kalan argümanları doğrudan editöre geçirir. Testler için:

```sh
cmake --build build --target check-build --parallel "$(( $(nproc) / 2 ))"
ctest --test-dir build --output-on-failure -LE graphics
```

(`graphics` etiketli testler çalışan bir X11/GLX ekranı ister, örn. Xvfb.)

## Daha fazlası

[Sistem tanımı](docs/tanim.md) · [Mimari dizini](docs/README.md) ·
[Geliştirme kuralları](docs/skill.md) · [Bilinen sorunlar](docs/olasi_hatalar.md)
