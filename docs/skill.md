# ATS2 geliştirme, formel mimari ve refactoring kuralları

Bu belge proje içi geliştirme rehberidir. Özel değişmezler
[ajan kurallarında](../.agents/rules) ve alt becerilerde
([principal-software-architect](../.agents/skills/principal-software-architect/SKILL.md),
[ats2-rigorous-formal-architect](../.agents/skills/ats2-rigorous-formal-architect/SKILL.md))
tutulur; gerçek uygulama sınırları ilgili alt sistem rehberinden ve `.sats`
sözleşmesinden okunur.

---

## 1. Yazılım Mimarisi Prensipleri (`principal-software-architect`)

### 1.1 Tek Sorumluluk (SRP), Atomiklik ve SLAP

- **Tek Görev Kuralı:** Bir fonksiyon yalnızca tek bir mantıksal işlemden
  sorumludur. Adı `and`/`or`/`then` içeren veya doğrulama, iş mantığı ve
  G/Ç/loglamayı tek gövdede birleştiren fonksiyonlar yasaktır.
- **Maksimum Satır Limiti (20 Satır):** Fonksiyon gövdeleri (imza, boş satır,
  yorum ve dış `let`/`in`/`end` hariç) en fazla 20 kod satırıdır. Sınır satır
  sıkıştırılarak sağlanmaz; ayrılabilir işler yardımcı fonksiyonlara çıkarılır.
- **Tek Soyutlama Seviyesi (SLAP):** Yüksek seviyeli orkestrasyon fonksiyonları
  doğrudan bit kaydırma, ofset aritmetiği, ham tampon indeksleme veya C FFI
  ayrıntılarıyla ilgilenemez; alt yordamlara delege eder.
- **Bayrak Parametresi Yasağı (Flag Arguments):** `boolean` bayrak alıp içeride
  `if flag` dallanması yapan fonksiyonlar yerine `Toggle` veya iki ayrı işlev
  (`caret_move_left` / `caret_move_right`) tanımlanır.

### 1.2 Tip Güvenliği, FSM, Saf Çekirdek ve Sözleşmeler

- **Sıfır Ham String / Magic Int Durumu:** Durumlar, roller, olaylar ve komutlar
  ham `string` veya çıplak `int` yerine `datatype`, `sortdef`, `Toggle` veya
  açık durum matrisleriyle modellenir. (`CHAR_*`, uzunluk/piksel, `NF_*`
  ofsetleri ve C sabitleri sahte `datatype` yapılmaz.)
- **Parse, Don't Validate & Sınır Hava Kilidi:** Dış dünyadan (C ABI, JSON, OS,
  kullanıcı girdisi) gelen veriler sistem sınırında (`airlock_*` ve ayrıştırıcı
  kapılarında) doğrulanıp tiplenmiş yapıya dönüştürülür; iç çekirdekte tekrar
  tekrar null/aralık kontrolüne gerek kalmaz.
- **Akış Kontrolü & Kapsamlı `case+` (No Wildcards):** Derin `if-else`
  piramitleri (derinlik > 2) yerine erken çıkış (guard clauses), geçiş
  tabloları ve `| _ =>` jokeri olmayan tam kapsamlı `case+` kullanılır.
- **Çekirdek ve Kabuk Ayrımı:** Hesaplama/dönüşüm mantığı yan etkisiz saf
  fonksiyonlarda toplanır; G/Ç ve yan etkiler dış çeperde izole edilir.
  Değişkenler varsayılan olarak değişmezdir (`val`).
- **Hata Yönetimi ve Sözleşmeler:** Sessiz hata yutma ve sahte varsayılan değer
  döndürme yasaktır. Kurtarılabilir hatalar `Option_vt` / `@(bool, T)` veya açık
  sonuç tipleriyle (`FontSpanRead`, `NativeAnalysisRead`) taşınır; kutulu `Option`
  kullanılmaz.
- **Veri Odaklı Tasarım & Mekanik Sempati:** SoA yerleşimi, ardışık bellek,
  sıfır-kopya dilimler (`!Buf`, `string`) ve $O(L+N)$ monotonik imleç geçişleri
  korunur.
- **Kapsamlı Yaşam Döngüsü, RAII ve Atomik Kalıcılık:** Doğrusal tipler (`Buf`,
  `Doc`, `Font`, `Image`, `Rend`, `Plat`, `App`) tam olarak bir kez serbest
  bırakılır. Kritik dosya yazımları geçici `.tmp` + `fsync` + atomik `rename`
  (`anth_atomic_write`) üzerinden yapılır.
- **Yapılandırılmış Gözlemlenebilirlik:** Günlük çıktıları anahtar-değer
  (`event=... status=...`) veya yapılandırılmış `[BİLEŞEN]` biçiminde üretilir.

---

## 2. ATS2 Formel Mimari ve Güvenlik Sınırı (`ats2-rigorous-formal-architect`)

### 2.1 Tabu ve İkame Matrisi

| Katman | Yasak (Tabu) | Zorunlu İkame |
| --- | --- | --- |
| **FFI & Tip Dönüşümü** | `$UNSAFE.cast`, denetlenmeyen `castfn`, `g1ofg0`/`g0ofg1` | `prfn`/`prfun` yapıcı lemmalar ve `airlock_*` kapıları |
| **Opak Sahipler** | 8. bir `assume` eklemek | Yalnızca 7 onaylı sahip: `Buf`, `Doc`, `Font`, `Image`, `Rend`, `Plat`, `App` |
| **Bellek Erişimi** | Ham `ptr` okuması/yazması, algoritmik `buf_ptr` | İndekslenmiş `ptr(l)` + doğrusal görünüm (`view`) veya `Buf` sözleşmesi |
| **Özyineleme** | Metriksiz `fun` | Her özyinelemede kesin sonlanma metriği (`.<n>.` / `.<recfuel>.`) |
| **Doğal Sayaç vs. Yakıt** | Küçük parti/arama limitlerinde (`64`, `32`, `16`) `recursion_fuel_available` kullanmak | Doğal sayaçlarda `if left = 0`; yalnız `MAX_REC_FUEL` ($2^{28}$) için `recursion_fuel_available` |
| **Örüntü Eşleme** | `case-`, `case`, `| _ =>` joker dalı | Tam kapsamlı `case+` (exhaustive pattern matching) |
| **Algoritmik C** | `.cats`/`.h` içinde döngü veya algoritma, üretimde C JPEG | Saf ATS2; C tarafında yalnız OS/X11/GL sınır adaptörleri |
| **Kurtarılabilir Hata** | Çizim/yerleşim/analiz reddedildiğinde `anth_die_*` ile core dump almak | `FontSpanRejected` / `NativeAnalysisRejected` için güvenli fallback |

### 2.2 Sınır Hava Kilidi ve Çökme Koruması

- ATS üretimi önce `patsopt -tc`, sonra C üretimi üzerinden geçer.
- Dış tamsayılar `airlock_nat`, `airlock_pos`, `airlock_below`, `airlock_word`,
  `airlock_span` ve `airlock_i32` kapılarından geçer.
- **Hava Kilidi Ön Koşul Koruması:** `airlock_nat`, `airlock_below`,
  `airlock_span` ve `recursion_fuel_available(0)` sözleşme ihlalinde `abort()`
  çağırarak süreci durdurur. Bu nedenle:
  1. Dinamik uzunluk farkları (`isub(b, a)`) `airlock_nat` içine doğrudan verilmez;
     `imax(0, ...)` veya açık `ile(a, b)` koruması ile sarılır.
  2. `airlock_below(i, cap)` çağrılmadan önce `0 <= i < cap` (ve `cap > 0`)
     denetlenir.
  3. `airlock_span(lo, hi)` çağrılmadan önce `lo <= hi` denetlenir.
  4. `recursion_fuel_available` yalnız `MAX_REC_FUEL` (`268435456`) ile
     başlatılan sentetik bütçelerde kullanılır (BUG-003). Olay kuyruğu parti
     sınırı (`EVENT_DRAIN_BATCH_LIMIT = 64`), ikili arama adım sınırı veya
     metin uzunluğu gibi doğal sayaçlar sıfıra indiğinde `abort()` atmadan
     normal döner.
- **Kurtarılabilir Metin / Yerleşim Reddi:** `visual_wrap.dats`, `visual_plan.dats`
  ve `font_text_boundaries.dats` gibi arayüz/yerleşim modülleri, geçersiz veya
  parçalı UTF-8 / CR-LF / paragraf ayırıcı girişlerinde süreci sonlandırmak
  yerine doğrusal kaynağı güvenle tüketip yedek ölçüme düşer.
- JPEG algoritması ATS2 içindedir; [C stb](../vendor/stb/README.md) yalnız test
  orakılıdır, üretim yedeği değildir.

---

## 3. Okunabilirlik, Kayıtlar ve Performans

- Anlamlı sayılar birimleri belirtilmiş sabitlere taşınır: `*_WORDS`,
  `*_BYTES`, `*_PIXELS`, `*_MS`.
- İlk tahsis kapasiteleri isimli politikalardır. Kaydı oluşturan alan ve kelime
  sayısından bayt boyutunu türetin; aynı boyutu farklı yerlerde tekrar
  tanımlamayın.
- Konu klasörlerinde `.sats` ve uygulamaları birlikte tutulur. Özel `.hats`
  grupları sahibinin çeviri birimine aittir; bağımsız bağlanan modüller değildir.
- Kaynak taşındığında ATS yüklemeleri, C başlıkları, CMake grupları, araçlar,
  negatif derleme testleri ve belge bağlantıları birlikte güncellenir.
- `!Buf` ödünç verir; `Buf` tüketen arayüz sahipliği aktarır. `buf_get32`/`buf_set32`
  kelime indeksi, `buf_len`/`buf_ensure` bayt indeksi alır. `buf_zero` uzunluğu
  sıfırlar; önce `buf_zero`, sonra `buf_set_len` çağrılır.
- Katlama görünürlüğü görsel izdüşümden önce eşzamanlı güncellenir; satır/AST
  eşleştirmelerinde $O(L+N)$ monotonik imleç veya ikili arama kullanılır.
- Katlama bölgesi sıralaması 32 bit sahip anahtarında kararlı dört geçişli radix
  sıralamadır ($O(R)$).
- **Derleme Bayrakları:** `-Wall -Wextra -Wshadow -pedantic` zorunludur;
  `-Werror` ve varsayılan `ASan` (GLX bağlam uyumsuzluğu nedeniyle) üretim
  derlemesinde kapalıdır, CPU testleri `ANTHRACITE_SANITIZERS=ON` ile ayrıca
  sınanır.

---

## 4. Test kapısı ve belge eşlemesi

- `check-build` bütün yürütücüleri derler, `check` ardından CTest'i çalıştırır.
- Grafik testlerde geçerli ekran gerekir. Sonlu durum matrislerini tamamen
  tarayın; parametreli/büyük uzaylarda sınır, özellik, uyumluluk ve negatif
  tip testlerini birleştirin.
- `selftest_fixture_open`, varsayılan olarak geçici fixture dizinini
  `ANTHRACITE_CONFIG_DIR` olarak ayarlayıp kullanıcının `~/.config/anthracite`
  yapılandırmasını korur.
- `mem_live` yalnız proje sayacına kaydedilmiş tahsisleri ölçer; X11/GPU/stb
  tahsislari dışındadır. `live=1530113` başlangıç ortamında gözlenen referanstır.
- Bulunan eski davranış hatalarını [hata listesine](olasi_hatalar.md) kanıt ve
  yeniden üretmeyle yazın. Belgelerde bulunmayan API'ler uygulanmış gibi
  gösterilmez.

---

## 5. Dürüst Sınırlar (Kanıtlanamayanlar)

- **C kütüphanesi sözleşmeleri:** `snprintf`/`fgets`'in kapasiteye uyması,
  `calloc`'un sıfırlaması, POSIX dosya/soket çağrılarının davranışı ATS2
  dışında kalır.
- **FFI imzaları:** `mac#` imzalarının C tarafıyla uyumu derleyici tarafından
  denetlenmez; imza eşlemesi ve tip testleriyle korunur.
