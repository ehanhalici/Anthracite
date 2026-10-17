# JPEG regresyon paketi

`test_jpg_oracle.dats` üretim `decode_jpg` sonucunu, yalnız teste bağlanan
`jpg_oracle_c.cats` içindeki stb_image v2.29 referansıyla karşılaştırır.
Her geçerli fixture için boyutlar, tüm RGBA baytları, `buf_len`, kapasite ve
aynı yaşam döngüsü noktalarında `mem_live` denetlenir. Hata yolunda da tamponlar
bırakılır. Ret testleri sıfır boyut/uzunluk ve aynı canlı bayt sayısını ister.

## Kapsam

- Boyutlar: 1×1, 17×19, 32×16 ve 31×27; kısmi ve hizalı MCU kenarları.
- 4:4:4, 4:2:2, 4:2:0, 4:4:0, 4:1:1 ve dikey dört kat örnekleme.
- Baseline/progressive gri ve RGB; gerçek CMYK ve baseline/progressive YCCK.
- Sequential ayrı bileşen taramaları, H/V=2 olan tek bileşenli taramalar.
- Restart aralıkları 1/2/3/5 MCU; tam dolan ve kısmi son aralıklar,
  progressive/tek bileşenli/çoklu tarama ile birleşimleri.
- 16-bit nicemleme tablosu kullanan 8-bit SOF1 (`cjpeg -quality 1`).
- Kesik SOF/SOS, boş entropy, eksik EOI/restart, geçersiz örnekleme katsayısı,
  tablo seçicisi ve progressive tarama parametreleri.

Asıl `make_jpg()` ve `tests/fixtures/progressive.jpg` karşılaştırmaları korunur.
Fixture başarısı, tüm JPEG uzayının ispatı veya kaynak sayaçları dışındaki
tahsisler için sızıntısızlık iddiası değildir.

## Çalıştırma ve yeniden üretme

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target image_oracle_contracts --parallel
ctest --test-dir build -L jpeg --output-on-failure
```

CTest depodaki ikili fixture dosyalarını kullanır; Python, cjpeg veya ImageMagick
normal test çalıştırmasının bağımlılığı değildir. Sentetik RGB deseninden yeniden
üretmek için Python 3, libjpeg-turbo `cjpeg` ve ImageMagick 7 `magick` gerekir:

```sh
python3 tests/image/generate_jpeg_fixtures.py
# PATH dışında kurulumlarda --cjpeg /path/to/cjpeg --magick /path/to/magick
```

Üretim ortamı: libjpeg-turbo 3.1.4 ve ImageMagick 7.1.2-31.
ImageMagick CMYK isteğinde YCCK ürettiği için doğrudan CMYK fixture'ları
üreteçteki bağımsız DC-only JPEG kodlayıcısıyla hazırlanır. Her 8×8 blokta
kanal başına sabit örnek, birim nicemleyici ve AC için EOB kullanılır.
Bütün yeni fixture'lar sentetik veridir. Kodlayıcı sürümü değişirse JPEG
baytları değişebilir; karşılaştırma her zaman aynı girdinin iki çözücüdeki
çıktısı üzerindendir. Kodlayıcılar veya C stb üretim uygulamasına bağlanmaz.
