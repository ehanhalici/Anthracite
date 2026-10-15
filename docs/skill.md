# Askeri Düzey Postiats 0.4.2 Formel Yazılım Mimarisi ve Durum Makinesi Yönergesi
### Sistem Yönergesi: `principal-systems-architect`

Bu yönerge, Anthracite kod tabanında matematiksel ispat bütünlüğünü, sıfır kaçış garantisini (soundness), mutlak tip güvenliğini, deterministik durum makinelerini (FSM) ve sıfır bellek sızıntısı ilkesini zorunlu kılar. Bu standartlara uymayan hiçbir kod parçası depoya kabul edilemez.

---

## 1. Mimarlık Doktrini ve Sıfır Tolerans İlkesi (The Axiom of Soundness)

Bir sistemin kararlılığı, çalışma zamanı istisnalarına, denetimsiz tür zorlamalarına veya "inşallah çalışır" varsayımlarına terk edilemez.

* **Temel Doktrin:** *"İmkânsız durumlar, tip sistemi aracılığıyla derleme zamanında temsil edilemez kılınmalıdır."* (*Make illegal states unrepresentable*).
* **Statik Doğrulama Kapısı (Two-Stage Verification):** Kod C99'a dönüştürülmeden önce her zaman `patsopt -tc` (Type-Check Only) kapısından geçmeli; bağımlı kısıtlar ($[n:\text{nat}]$), doğrusal yetenek kanıtları ($v @ l$) ve sonlanma metrikleri ($<fuel>$) matematiksel olarak ispatlanmalıdır.
* **Bellek Değişmezi (Zero-Leakage Invariant):** Selftest çıktısında bellek kullanım metriği tek bir bayt sapmadan korunmalıdır:
  $$\text{live} = 1530113 \quad (\text{Askeri Düzey Sabit})$$
* **Boşta Sıfır CPU İlkesi (%0 CPU Invariant):** Kullanıcı etkileşimi olmadığı sürece CPU döngüsü tüketilmez; olay kuyruğu işletim sistemi soketi üzerinde bloke (`select` / `poll`) bekler.

---

## 2. ATS2 Unsafe ve Kusurlu Kalıpların Mutlak Yasaklanması

Aşağıdaki tabloda belirtilen "Tabu" yöntemlerin kod tabanında kullanımı mutlak olarak yasaklanmıştır. Herhangi bir istisnaya izin verilmez.

| Katman | ❌ Asla Kullanılmayacak Yöntem (Tabu) | ✅ Yerine Zorunlu Olan Yöntem (İkame) | Gerekçe ve Mimari Yaptırım |
| :--- | :--- | :--- | :--- |
| **FFI & Tip Zorlama** | `$UNSAFE.cast`, `$UNSAFE` modülü | `prfn`/`prfun` yapıcı lemmalar ve `airlock_*` sınır kapıları | Tip sistemini baypas etmek ispat zincirini kırar; sessiz bellek bozulmalarına yol açar. |
| **İspatsız Dönüşüm** | Denetlenmeyen `castfn` | Bağımlı tip imzalı fonksiyonlar veya yapıcı lemma ispatları | `castfn` derleyicinin tip kontrolünü aldatır; formel geçerliliği yok eder. |
| **Statik Yükseltme** | `g1ofg0` | `airlock_nat`, `airlock_pos`, `airlock_below`, `airlock_word`, `airlock_span` | Postiats 0.4.2'de `g1ofg0` kısıtları derleyici tarafından garanti edilmez; C tarafında denetlenen hava kilidi zorunludur. |
| **Opak Tipler** | 8. bir `assume` yazmak | Yalnızca 7 onaylı opak tip (`Buf`, `Doc`, `Font`, `Image`, `Rend`, `Plat`, `App`) | Kod tabanında bu 7 tip haricinde `absviewtype = ptr` ve `assume` eklenmesi kesinlikle yasaktır. |
| **Bellek Erişimi** | Ham C işaretçisi (`ptr`) üzerinden doğrudan okuma/yazma | İndekslenmiş işaretçi `ptr(l)` ve doğrusal görünüm kanıtı ($v @ l$) ya da `Buf` hava kilidi | Lineer mantık gereği her bellek hücresi tekil bir erişim izni (`view`) gerektirir. |
| **Özyineleme & Döngü** | Metriksiz `fun`, denetimsiz `while(true)` | Kesin sonlanma metriği (`.<n>.` veya `.<recfuel>.`) ve `MAX_REC_FUEL` | Durma Problemi (Halting Problem) ve yığın taşması (stack overflow) matematiksel olarak engellenir. |
| **Dallanma & Akış** | `case-`, `case`, joker karakterli (`_`) genel `if/else` | Statik kısıtlı `case+` (Exhaustive Pattern Matching) | Tüm varyantların açıkça tüketilmesi zorunludur; tanımsız çalışma zamanı durumları derlemede kilitlenir. |
| **Durum Temsili** | Ham `string`, magic integer, serbest tamsayı bayrakları | `datatype`, `sortdef`, `Toggle` veya formel durum matrisi | "Stringly-typed" anti-pattern yasağı; durumlar derleme anında ayrıklaştırılır. |
| **Algoritmik Kod** | Satır içi C blokları (`%{# ... %}`) veya algoritmada `$extfcall` | Saf ATS2 fonksiyonları (`fun`, `fn`) ve `.sats` üzerinden soyut arayüzler | Algoritmik kod derleyicinin tip denetimine ve ispat motoruna %100 tabi olmalıdır. |
| **Hata Yönetimi** | Sessiz başarısızlık, sahte varsayılan değer dönme, `bool abort` | Açık sonlandırma yordamları (`anth_die_*`) veya tip güvenli `option_vt` | Hata durumları deterministik olmalı, tanımsız veri akışı derhal durdurulmalıdır. |

---

## 3. Askeri Düzey Sonlu Durum Makinesi (FSM) Tasarım Kalıpları

Sistemdeki tüm karmaşık etkileşimler, kullanıcı eylemleri, ayrıştırma adımları ve kaynak yaşam döngüleri **Sonlu Durum Makineleri (FSM)** ile modellenmelidir. ATS2 Postiats 0.4.2 içinde uygulanacak 4 temel mimari FSM kalıbı aşağıda tanımlanmıştır:

---

### Kalıp 1: Cebirsel Veri Tipleri ile Tüketici Durum Geçiş Matrisi (Exhaustive Sum-Type FSM)

Kullanıcı arayüzü, editör etkileşimi ve çoklu mod yönetimi için kullanılır (Örnek: `src/ui_workspace/editor_fsm.*`).

#### Prensipler:
1. Durumlar (`State`) ve Eylemler (`Action`) cebirsel veri tipleri (`datatype`) olarak deklare edilir.
2. Her durumun geçiş mantığı, **en fazla 10 satırlık** ayrık bir `step_<durum>` yardımcı fonksiyonuna devredilir (SRP kuralı).
3. Ana geçiş fonksiyonu `case+` ile tüm durumları tüketir. Joker (`_`) kullanılmaz.
4. Modal durumlar (`is_modal`), arka plandaki olayların ön plana sızmasını kesin olarak engeller.

#### `editor_fsm.sats` (Sözleşme Arayüzü)
```ats
staload "ui_workspace/ui_common.sats"

datatype EditorState =
  | StateIdle
  | StateTyping
  | StateSelecting of (int, int)
  | StatePrompt of PromptKind
  | StateMenu of MenuKind
  | StateSplitDrag of int

datatype EditorAction =
  | ActNone
  | ActTypeKey
  | ActFocusPrompt of PromptKind
  | ActDismissPrompt
  | ActOpenMenu of MenuKind
  | ActDismissMenu
  | ActStartSelect of (int, int)
  | ActUpdateSelect of int
  | ActStartSplitDrag of int
  | ActEndSplitDrag
  | ActEscape

fun editor_fsm_name(st: EditorState): string
fun editor_fsm_step(st: EditorState, act: EditorAction): EditorState
fun editor_fsm_is_editing(st: EditorState): bool
fun editor_fsm_is_modal(st: EditorState): bool
fun editor_fsm_selftest(): int
```

#### `editor_fsm.dats` (Atomik Gerçekleme - SRP $\le 10$ Satır/Fonksiyon)
```ats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "ui_workspace/ui_common.sats"
staload "ui_workspace/editor_fsm.sats"

implement editor_fsm_is_modal(st) = case+ st of
  | StatePrompt(_) => true
  | StateMenu(_) => true
  | _ => false

fun step_idle(act: EditorAction): EditorState = case+ act of
  | ActTypeKey() => StateTyping()
  | ActFocusPrompt(p) => StatePrompt(p)
  | ActOpenMenu(m) => StateMenu(m)
  | ActStartSelect(a, f) => StateSelecting(a, f)
  | ActStartSplitDrag(x) => StateSplitDrag(x)
  | _ => StateIdle()

fun step_typing(act: EditorAction): EditorState = case+ act of
  | ActTypeKey() => StateTyping()
  | ActStartSelect(a, f) => StateSelecting(a, f)
  | ActFocusPrompt(p) => StatePrompt(p)
  | ActOpenMenu(m) => StateMenu(m)
  | ActEscape() => StateIdle()
  | _ => StateTyping()

fun step_selecting(a: int, f: int, act: EditorAction): EditorState = case+ act of
  | ActUpdateSelect(f2) => StateSelecting(a, f2)
  | ActTypeKey() => StateTyping()
  | ActEscape() => StateIdle()
  | _ => StateSelecting(a, f)

fun step_prompt(p: PromptKind, act: EditorAction): EditorState = case+ act of
  | ActDismissPrompt() => StateIdle()
  | ActEscape() => StateIdle()
  | _ => StatePrompt(p)

fun step_menu(m: MenuKind, act: EditorAction): EditorState = case+ act of
  | ActDismissMenu() => StateIdle()
  | ActEscape() => StateIdle()
  | _ => StateMenu(m)

fun step_drag(x: int, act: EditorAction): EditorState = case+ act of
  | ActEndSplitDrag() => StateIdle()
  | ActEscape() => StateIdle()
  | _ => StateSplitDrag(x)

implement editor_fsm_step(st, act) = case+ st of
  | StateIdle() => step_idle(act)
  | StateTyping() => step_typing(act)
  | StateSelecting(a, f) => step_selecting(a, f, act)
  | StatePrompt(p) => step_prompt(p, act)
  | StateMenu(m) => step_menu(m, act)
  | StateSplitDrag(x) => step_drag(x, act)
```

---

### Kalıp 2: Doğrusal Yetenek Kanıtları ile Tip-Durum Makinesi (Linear Type-State FSM)

Geri dönülemez donanım, dosya tanıtıcısı, ağ soketi veya grafik bağlamı durumları için kullanılır.

#### Prensipler:
1. Durumlar tip seviyesinde statik tamsayılar (`stadef`) ve soyut doğrusal görünümlerle (`absview`) modellenir.
2. Fonksiyon çağrısı **eski durum kanıtını tüketir (`consume`) ve yeni durum kanıtını üretir**.
3. Sıralı işlem kuralı ihlal edilirse (örneğin başlatılmamış soketten veri okuma veya kapatılmış dosyaya yazma), program **derleme aşamasında tip hatası verir**. Çalışma zamanı hatası oluşması imkânsızdır.

```ats
// 1. Statik Durum Seviyeleri
stadef ST_UNINIT = 0
stadef ST_READY  = 1
stadef ST_ACTIVE = 2
stadef ST_CLOSED = 3

// 2. Doğrusal Yetenek Kanıtı (Linear Capability Proof)
absview DEVICE_STATE(int)

// 3. Durum Geçiş İmzaları: Eski durum tüketilir, yenisi döner
extern fun device_open (): (DEVICE_STATE(ST_READY) | int)
extern fun device_start (pf: DEVICE_STATE(ST_READY)): (DEVICE_STATE(ST_ACTIVE) | void)
extern fun device_write (pf: !DEVICE_STATE(ST_ACTIVE) | data: int): void
extern fun device_close (pf: DEVICE_STATE(ST_ACTIVE)): (DEVICE_STATE(ST_CLOSED) | void)

// KABUL EDİLEMEZ: device_write çağrısına DEVICE_STATE(ST_READY) verilemez!
// Derleyici: "type mismatch: expected DEVICE_STATE(2), got DEVICE_STATE(1)"
```

---

### Kalıp 3: Asenkron Kaynak ve Zaman Damgalı Önbellek FSM'si (Embed FSM)

Disk görselleri, dinamik ekler ve harici dokümanların arka planda yüklenmesi için kullanılır (Örnek: `src/ui_workspace/embed_fsm.*`).

#### Prensipler:
1. Kaynak durumu ayrık fazlardan oluşur: `EmbedUnloaded`, `EmbedResolving`, `EmbedCached(height)`, `EmbedFailed`.
2. Kaynağın dosya değiştirilme zamanı (`st_mtime`) izlenir. Disk üzerindeki dosya güncellendiğinde durum deterministik olarak `EmbedUnloaded` durumuna düşürülür (invalidation).
3. Başarısızlık durumunda sahte veri dönülmez; arayüze `EmbedFailed` iletilir ve kırmızı hata çerçevesi basılır.

```ats
datatype EmbedState =
  | EmbedUnloaded
  | EmbedResolving
  | EmbedCached of int
  | EmbedFailed

fun embed_state_of(code: int, h: int): EmbedState =
  if ieq(code, 2) then EmbedCached(h)
  else if ieq(code, 1) then EmbedResolving()
  else if ieq(code, 3) then EmbedFailed()
  else EmbedUnloaded()
```

---

### Kalıp 4: İki Durumlu Görsel Bayraklar (`datatype Toggle = Off | On`)

Fonksiyonlara `bool` veya çıplak `0 / 1` bayrak parametresi geçmek, fonksiyonun iki ayrı iş yaptığı anlamına gelir ve çağrı yerinde okunabilirliği sıfırlar (`flag arguments anti-pattern`).

#### Prensipler:
1. `src/flag.sats` içindeki `datatype Toggle = Off | On` kullanılır.
2. `is_on(t)` ve `is_off(t)` yüklemleri ile sorgulanır.
3. Çift durumlu görsel özellikler (ör. `is_hover: Toggle`, `is_active: Toggle`, `has_bp: Toggle`) tip güvenliğiyle korunur.

```ats
// KABUL EDİLEMEZ:
fun draw_cell(x: int, y: int, flag1: bool, flag2: int): void

// STANDARTLARA UYGUN:
fun draw_cell(x: int, y: int, is_selected: Toggle, is_hover: Toggle): void
```

---

## 4. Postiats 0.4.2 Sınır Hava Kilidi (Boundary Airlock) Protokolü

C ABI, işletim sistemi ve dış dünyadan gelen dinamik değerler iç çekirdeğe doğrudan sızamaz. Giriş ve çıkışlar katı bir hava kilidinden (`src/airlock.sats`) geçmelidir:

* **Sınır Fonksiyonları:** Tip yükseltme işlemi `g1ofg0` yerine yalnızca C tarafında sınır denetimi yapan şu fonksiyonlarla yürütülür:
  * `airlock_nat`: Dinamik tamsayıyı $[n:\text{nat}] \text{ int}(n)$ indeksine yükseltir (negatif değerler 0'a kilitlenir).
  * `airlock_pos`: Dinamik tamsayıyı $[n:\text{pos}] \text{ int}(n)$ indeksine yükseltir (sıfır ve negatifler 1'e kilitlenir).
  * `airlock_below`: Dinamik tamsayıyı $[k:\text{nat} \mid k < n] \text{ int}(k)$ sınırına kilitler.
  * `airlock_word`: Dört baytlık kelime hizalamasını ($4k + 4 \le n$) garanti eder.
  * `airlock_span`: Döngü adımlarında $hi - lo \ge 0$ aralığını doğrular.
* **Yakıt Tavanı (Fuel Exhaustion):**
  $$\text{MAX\_REC\_FUEL} = 268435456 \quad (2^{28})$$
  Tüm özyinelemeli fonksiyonlar her adımda 1 birim yakıt tüketir (`recfuel - 1`). Yakıt bittiğinde sahte değer dönülmez; süreç `anth_die_int` / `anth_die_void` ile anında durdurulur.

---

## 5. Yazılım Tasarım İlkeleri: SRP ve SLAP Kuralları

1. **Tek Sorumluluk Prensibi (SRP - Maksimum 20 Satır):**
   * Bir fonksiyon yalnızca tek bir mantıksal işlemden sorumlu olabilir.
   * Fonksiyon gövdeleri istisnasız **en fazla 20 satır** olabilir. 20 satırı aşan her blok mantıksal alt fonksiyonlara parçalanmalıdır.
2. **Tek Soyutlama Seviyesi Prensibi (SLAP):**
   * Yüksek seviyeli bir orkestrasyon fonksiyonu (ör. `tabs_toggle_deep`), asla düşük seviyeli detaylarla (ofset bit kaydırma, ham bayt tarama, bellek kopyalama) doğrudan ilgilenemez. Ham işlemler private alt fonksiyonlara delege edilmelidir.
3. **Tampon Başlatma Sırası Değişmezi:**
   `buf_zero` fonksiyonu `len := 0` yaptığı için, `buf_zero` çağrısı mutlaka `buf_set_len` fonksiyonundan **önce** yapılmalıdır:
   ```ats
   val () = buf_zero(hidden)              // Önce içeriği sıfırla (len := 0 olur)
   val () = buf_set_len(hidden, n_bytes)  // Sonra geçerli uzunluğu belirle
   ```

---

## 6. Kod Dönüşüm Referansı (Bad vs. Good)

### ❌ KABUL EDİLEMEZ KOD (İspatsız, Ham İşaretçili, Metriksiz Özyineleme):
```ats
// KABUL EDİLEMEZ: castfn hilesi, ham bellek erişimi, yakıt kontrolü yok
extern castfn unsafe_to_nat (x: int): [n:nat] int(n)

fun parse_tokens (p: ptr, len: int): int =
  if len <= 0 then 0
  else let
    val n = unsafe_to_nat (len)
    val b = $UNSAFE.cast{int}(p)
  in
    b + parse_tokens (p, len - 1) // Metriksiz recursion -> Yığın patlaması riski!
  end
```

### ✅ MİMARİ STANDARTLARA UYGUN KOD (Tam Zırhlı, Airlock ve FSM Korumalı):
```ats
staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"

extern fun parse_tokens_exh (b: !Buf, i: int, n: int): int = "mac#anth_die_int"

fun parse_tokens_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), b: !Buf, i: int, n: int, acc: int
): int =
  if recfuel > 0 then (
    if ilt(i, n) then let
      val byte_val = buf_get_byte(b, i)
    in
      parse_tokens_m(recfuel - 1, b, iadd(i, 1), n, iadd(acc, byte_val))
    end else acc
  ) else parse_tokens_exh(b, i, n)

fun parse_tokens_safe (b: !Buf): int = let
  val raw_len = buf_len(b)
  val safe_len = airlock_nat(raw_len)
in
  parse_tokens_m(airlock_nat(MAX_REC_FUEL), b, 0, safe_len, 0)
end
```

---

## 7. Derleme Kapısı ve Doğrulama Protokolü

Her geliştirici ve yapay zekâ ajanı, yaptığı her değişiklik sonrasında şu adımları sırasıyla çalıştırmak ve doğrulamak zorundadır:

```bash
# 1. Paralel Derleme (CMake + patsopt + Clang)
nix-shell --run "cmake --build build --parallel"

# 2. Askeri Düzey Bellek Değişmezi Testi (live=1530113 kesinliği)
nix-shell --run "./build/anthracite --selftest"

# 3. Tüm CTest Birim ve Uyumluluk Testleri (77 test %100 Başarı)
nix-shell --run "ctest --test-dir build --output-on-failure"
```

Bu kontrollerden geçmeyen veya `live=1530113` değişmezini 1 bayt dahi saptıran hiçbir kod tabana entegre edilemez.