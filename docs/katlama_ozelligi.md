# Askeri Düzey Metin ve Kod Katlama (Folding) Yeteneği

## 1. Yetenek Özeti ve Sorumluluk Sınırları

Bu yetenek, Anthracite editöründe Markdown dokümanlarının ve kod bloklarının katlanmasını (code/text folding) matematiksel kesinlikle yönetir. AST düğüm derinliklerine dayalı kırılgan sezgiseller yerine; fiziksel satır girintileri, başlık hiyerarşisi ve kapalı blok sınırlarını birleştiren **Fold Region Table (FRT)** mimarisini kullanır.

### Temel Sorumluluklar
* **FRT Sınır Tespiti:** Başlık seviyeleri ($H_1..H_6$), görsel sütun girintisi ve kapalı çok satırlı bloklar için katlanma aralıklarının `[owner_line, fold_end_line)` tek geçişte belirlenmesi.
* **Yaprak Filtresi (Leaf Elimination):** Düz paragraflar ve çocuksuz yaprak liste maddeleri için katlama oklarının (`FL_FOLDABLE`) kesinlikle engellenmesi (yalnızca gerçek alt satırları olan yapılar katlanabilir).
* **Durum ve Görünürlük İzolasyonu (State Preservation):** Kullanıcının açık katlama tercihinin (`s.folds`) görünürlük bitset'inden (`s.hidden`) bağımsız tutulması; üst başlık açıldığında alt başlık ve listelerin katlı durumunun %100 korunması.
* **Görsel Yerleşim Entegrasyonu:** Gizlenen satırların yüksekliklerinin `layout_engine` içinde anında sıfırlanması (`step=0`) ve açıldığında orijinal piksellerine eksiksiz dönmesi.
* **Çift Modlu Etkileşim:** Normal sol tık ile yerel geçiş (`doc_toggle`), Alt+Sol tık ile hiyerarşik derin geçiş (`doc_toggle_deep`).

---

## 2. Neden Eski Mimari Başarısız Oldu? (Kök Neden ve Hata Analizi)

İlk katlama uygulamasında gözlemlenen hatalar, AST düğüm ağacına dayalı sezgisel modelin yapısal zaaflarından kaynaklanmıştır. Selftest'ler yeşil geçmiş olsa da, sadece soyut bayrak kontrolleri yapıldığı için gerçek gizlenen satırlar ve listeler doğrulanamamıştı.

### Doğrulanmış Kök Neden Tablosu

| # | Belirti | Kanıtlı Kök Neden |
|---|---|---|
| **1** | **Üst başlığı açınca alt durum kayboluyor** | Durum, düğümün başlangıç ofsetiyle anahtarlanıyordu; ancak bir satırda birden fazla düğüm (`KUl`, `KLi`, `KMark`, `KPara`) aynı veya bitişik ofseti paylaşıyordu. Ebeveyn açıldığında durum eşleşmesi bozuluyordu. |
| **2** | **Yaprak satırda hâlâ ok çıkıyor** | `node_indent = ağaç_derinliği * 4 + boşluk_sütunu` formülü kullanılıyordu. Paragraf (derinlik 0) ile liste maddesi (`KUl → KLi`, derinlik $\ge 1$) aynı sütunda olsa bile liste "daha derin" sayılıyor ve altındaki düz satır yanlışlıkla katlanabilir işaretleniyordu. |
| **3** | **Girintili alt satırı olan maddede ok yok / katlanmıyor** | Derinlik metriği ters etki yapıyordu: `- a` altındaki `  devam` satırı (derinlik 0 + 2 sütun = 2), ebeveyninden (4) küçük kalıyordu. Ayrıca `compute_node_is_foldable` fonksiyonu `KUl/KOl` düğümlerini atlıyor fakat `indent_fold_end` onları durdurucu sayıyordu; sonuçta aralık boş kalıyor ve hiçbir şey gizlenmiyordu. |
| **4** | **Katla-aç sonrası alt metin yok oluyor** | Gizleme hesabı iki ayrı katmanda yürütülüyordu (`place_one` düğüm gizleme + `line_hidden_by_folds` satır gizleme). İkisi farklı `fold_end` hesaplarına dayandığı için tutarsızlık oluşuyor ve satırlar kalıcı olarak sıfır yüksekliğe kilitleniyordu. |
| **–** | **Performans Yavaşlığı** | Her yerleşimde düğüm başına $O(N)$ tarama yapıldığı için algoritma $O(N^2)$ karmaşıklığa ulaşıyordu. |

> [!IMPORTANT]
> **Mimari İlke:** Bu sorunlar yama ile çözülemez. Katlama işlemi AST düğüm ağacı sezgileriyle değil; **satır, girinti ve başlık seviyeleri** üzerinden matematiksel bir modelle tek geçişte hesaplanmalıdır. AST yalnızca satırın kapalı bir kod bloğu, alıntı veya frontmatter içinde olup olmadığını belirten bağlamı sağlar.

---

## 3. Matematiksel Model ve FRT (Fold Region Table) Mimarisi

```mermaid
graph TD
    DOC[Doküman Metni + AST Bağlamı] --> SCAN[1. scan_lines_m: Tek Geçişli Yığın Taraması O(N)]
    SCAN --> FRT[2. Fold Region Table: owner_l, end_l, off, kind]
    FRT --> FILTER{3. Yaprak Filtresi: end_l > owner_l + 1 ?}
    FILTER -->|Hayır| LEAF[FL_FOLDABLE = 0: Kesinlikle Ok Çizilmez]
    FILTER -->|Evet| STAMP[FL_FOLDABLE = 1: Yalnızca Sahip Satırın İlk Düğümüne İşle]
    
    USER[Kullanıcı Tıklaması] --> DISPATCH{Tıklama Türü}
    DISPATCH -->|Normal Sol Tık| TOGGLE[doc_toggle: s.folds Ofset Ekle/Çıkar]
    DISPATCH -->|Alt + Sol Tık| TOGGLE_DEEP[doc_toggle_deep: Simetrik Alt Ağaç Geçişi]
    
    TOGGLE --> RECOMPUTE[doc_compute_foldability]
    TOGGLE_DEEP --> RECOMPUTE
    
    RECOMPUTE --> SWEEP[4. sweep_regions_m: Monotonik cover_end Süpürmesi O(R)]
    SWEEP --> HIDDEN[5. s.hidden Bitset Tamponu]
    HIDDEN --> LAYOUT[6. layout_engine: Gizli Satır step=0]
```

### A. Sınır Belirleme Kuralları (Boundary Rules)
Her boş olmayan satır için tür $K \in \{\text{Heading}(r), \text{Delimited}, \text{Plain}\}$ ve görsel girinti $I_{\text{base}}$ hesaplanır:

1. **Başlıklar ($H_n$):** Başlığın etki alanı, kendisinden sonra gelen ve seviyesi $k \le n$ olan ilk başlığa veya dosya sonuna (EOF) kadardır:
   $$\text{end\_line}(H_n) = \min \{ k \mid k > n \land \text{rank}(k) \le \text{rank}(n) \} \quad \text{veya EOF}$$
   Başlık kapanışı, içindeki tüm alt girinti bölgelerini de kapsar ve kapatır.
2. **Görsel Girinti ($I_{\text{base}}$):** Satır başındaki boşluklar sütun olarak sayılır (boşluk = 1 sütun, Tab = 4 sütun). Altındaki satırların girintisi $I > I_{\text{base}}$ olduğu sürece bölge devam eder:
   $$\text{end\_line}(Line) = \min \{ k \mid k > Line \land \text{not\_blank}(k) \land I(k) \le I_{\text{base}} \} \quad \text{veya EOF}$$
   * Aradaki boş satırlar bölgeyi bozmaz; bölgenin gerçek kapanışı son boş olmayan çocuk satırdır.
3. **Yaprak Elemesi (Leaf Elimination):** Kapanış satırı `end_line <= owner_line + 1` ise bölge **üretilmez**. Ayrı bir "katlanabilir mi" sezgisi aranmaz; bölgenin varlığı katlanabilir olduğunu gösterir. Çocuksuz yapraklara ok çizilmez.
4. **Sınırlı Bloklar (Delimited Blocks):** Çok satırlı kod blokları (`````), alıntılar (`>`) ve frontmatter (`---`) için ilk açılış satırı bölge sahibidir; gövde ve kapanış satırları gizlenir. İçlerindeki `#` karakterleri başlık taramasına girmez.
5. **Tek Sahip Önceliği:** Bir satır aynı anda birden fazla kategoriye uyuyorsa kesin öncelik sırası: **Başlık > Sınırlı Blok > Girinti**.

### B. Durum ve Görünürlük İzolasyonu (State Preservation)
* Kullanıcının katladığı satırların dosya ofsetleri `s.folds` tamponunda tutulur.
* `s.hidden` görünürlük tamponu, her düzenleme ve yerleşimde `sweep_regions_m` ile baştan oluşturulur:
  ```ats
  if ilt(owner, cover_end) then () (* Zaten gizli bir üst bölge içinde *)
  else if fold_has(d, off) then
    mark_hidden_lines_m(hidden, owner + 1, fend);
    cover_end := max(cover_end, fend)
  ```
* **Matematiksel Eşitlik:**
  $$\text{is\_visible}(Line) = \forall A \in \text{Ancestors}(Line), \neg \text{folded}(A)$$
  $$\text{render\_body}(Line) = \text{is\_visible}(Line) \land \neg \text{folded}(Line)$$
* Üst başlık açıldığında `s.folds` içindeki alt başlık kayıtları değişmediği için, alt başlık kapalı kalmaya devam eder (`coll=1`), altındaki satırlar görünmez kalır (`step=0`).

### C. Etkileşim Türleri (User Actions)
* **Normal Sol Tık (`doc_toggle`):** Tıklanan **satırın** bölgesi tersine çevrilir. Ebeveyne tırmanma kaldırılmıştır; yaprak satıra tıklanınca üst maddeyi katlama yan etkisi tamamen sonlandırılmıştır.
* **Alt + Sol Tık (`doc_toggle_deep`):** Hedef bölge ile birlikte `owner ∈ (owner_line, end_line)` aralığındaki tüm alt bölgeler hedefin yeni durumuyla simetrik olarak katlanır veya açılır.

### D. Kararlı Kimlik (Stable Identity across Edits)
* **Hızlı Düzenlemeler:** `folds_apply_edit(d, at, del_bytes, ins_bytes)` çağrısı ile `s.folds` tamponundaki ofsetler delta kaydırması ile güncellenir.
* **Geçici Bozulma:** Sahip satır düzenleme sırasında geçici olarak bölge olmaktan çıkarsa (örneğin altındaki girintili satır silinirse), kayıt hemen silinmez. Tekrar girinti eklendiğinde durum kendiliğinden geri gelir.

---

## 4. Modül Dosya Yapısı

* `src/data_ast/fold_region.sats`: FRT veri yapısı, bölge sorguları, yığın fonksiyonları ve gizlilik süpürme arayüzü.
* `src/data_ast/fold_region.dats`: Stack tabanlı tek geçişli sınır motoru, görsel girinti hesaplayıcı, sınırlı blok çıkarıcı ve monotonik gizlilik süpürücü.
* `src/data_ast/doc.sats`: `Doc` arayüzü üzerindeki katlama API'leri (`doc_toggle`, `doc_toggle_deep`, `doc_is_line_hidden`, `fold_has`, `folds_apply_edit`).
* `src/data_ast/doc.dats`: `s.regions` ve `s.hidden` tamponlarının yönetimi, AST bayrak damgalama (`FL_FOLDABLE`, `NF_COLLAPSED`).
* `src/data_ast/layout_engine.dats`: `doc_layout_line_hidden` üzerinden satır adımı (`step`) ve görünürlük hesaplama.
* `src/ui_workspace/ui.dats` & `ui_tab.dats`: Gutter tıklama koordinatlarının satıra ve bölgeye eşlenmesi, `tabs_toggle_deep` entegrasyonu.
* `src/core_platform/x11.sats` & `x11.cats`: Alt tuşu değiştirici maskesi (`Mod1Mask`).

---

## 5. Temel Veri Yapıları ve API İmzaları

### A. FRT Bölge Tipi Sabitleri (`fold_region.sats`)
```ats
#define FR_PLAIN 0      (* Girintili metin veya liste bloğu *)
#define FR_HEADING 1    (* H1..H6 Markdown başlığı *)
#define FR_DELIMITED 2  (* Çok satırlı kod, alıntı veya frontmatter *)
```

### B. Bölge Bellek Düzeni (16-Bayt Hizalı Kayıt)
Her katlanabilir bölge `regions` tamponunda 16 baytlık bir blok olarak saklanır:
* `+0` (4 bayt): `owner_line` (Bölgenin sahibi olan satır indeksi)
* `+4` (4 bayt): `fold_end` (Bölgenin kapandığı satır indeksi, exclusive)
* `+8` (4 bayt): `offset` (Sahip satırın dosyadaki mutlak karakter bayt ofseti)
* `+12` (4 bayt): `kind` (`FR_PLAIN`, `FR_HEADING`, `FR_DELIMITED`)

### C. Temel Fonksiyon İmzaları

```ats
(* Sınır Tablosu Üretimi *)
fun fold_region_build(d: !Doc, regions: &Buf >> _): int
fun fold_region_count(regions: !Buf): int
fun fold_region_owner(regions: !Buf, idx: int): int
fun fold_region_end(regions: !Buf, idx: int): int
fun fold_region_offset(regions: !Buf, idx: int): int

(* Gizlilik Süpürmesi *)
fun fold_regions_compute_hidden(d: !Doc, regions: !Buf, hidden: &Buf >> _): void
fun fold_region_line_hidden(hidden: !Buf, line: int): int

(* Doküman Seviyesi Katlama Eylemleri *)
fun doc_toggle(d: !Doc, i0: int): void
fun doc_toggle_deep(d: !Doc, i0: int): void
fun fold_has(d: !Doc, off: int): bool
fun fold_add(d: !Doc, off: int): void
fun fold_del(d: !Doc, off: int): void
fun folds_apply_edit(d: !Doc, at: int, del_b: int, ins_b: int): void
```

---

## 6. Algoritmik Süreçler ve Postiats 0.4.2 Uygulaması

### A. Tek Geçişli Yığın Taraması (`scan_lines_m`)
Tüm satırlar baştan sona tek geçişte ($O(N)$) taranır. Açık başlıklar ve girintili bloklar yığın üzerinde tutulur. Yeni bir satır geldiğinde:
1. Satır başlık ise, kendisinden küçük veya eşit seviyedeki tüm açık başlıklar ve alt girinti blokları kapatılır.
2. Satır girintili ise, yığındaki mevcut girintiden küçük eşit olduğu anda önceki girinti blokları kapatılır.
3. Kapanan her bloğun aralığı kontrol edilir; `end_line > owner_line + 1` olanlar `regions` tablosuna 16 baytlık kayıt olarak eklenir.

### B. Monotonik Gizlilik Süpürmesi (`sweep_regions_m`)
Bölgeler `owner_line` sırasına göre sıralı olduğundan, gizlilik hesabı $O(R)$ (bölge sayısı) sürede tek geçişte yapılır:
1. `cover_end` sayacı tutulur (başlangıçta 0).
2. Sıradaki bölgenin `owner_line < cover_end` ise, bu bölge zaten katlanmış bir üst bölgenin içinde kaldığından işlem yapılmaz (durumu korunur).
3. Bölge `s.folds` içinde kayıtlıysa (kullanıcı tarafından katlanmışsa), `(owner_line + 1 .. end_line)` aralığındaki tüm satırlar `hidden` bitset'inde işaretlenir ve `cover_end := max(cover_end, end_line)` yapılır.

### C. Görsel Yerleşim (`layout_engine.dats`)
Yerleşim motoru her satırın yüksekliğini hesaplarken `doc_layout_line_hidden` fonksiyonunu sorgular:
* Satır gizli ise: `step := 0` atanır, hiçbir glif çizilmez, imleç seçimi atlanır.
* Satır görünür ise: Gliflerin tam yüksekliği (`step := font_size + line_gap`) hesaplanır ve dikey koordinata eklenir.

---

## 7. Güvenlik Değişmezleri ve Bellek Yönetimi

* **Tampon Başlatma Sırası:** `buf_zero` fonksiyonu `len := 0` yaptığı için, `buf_zero` çağrısı mutlaka `buf_set_len` fonksiyonundan **önce** yapılmalıdır:
  ```ats
  val () = buf_zero(hidden)
  val () = buf_set_len(hidden, n_bytes)
  ```
* **Bellek Değişmezi:** `./build/anthracite --selftest` çalıştırıldığında `live=1530113` bayt değişmezi tam olarak sağlanır. Dokümana ait `s.regions` ve `s.hidden` tamponları `doc_free` çağrısında eksiksiz serbest bırakılır.
* **Yakıt Sayaçları:** Tüm özyinelemeli yığın ve süpürme fonksiyonları `airlock_nat(MAX_REC_FUEL)` ve `recfuel - 1` ile sınırlandırılmıştır; asla sonsuz döngüye girmez.
* **Tek Sorumluluk Prensibi (SRP):** `fold_region.dats` içindeki tüm fonksiyonlar $\le 20$ satır kuralına uygun yazılmıştır.

---

## 8. Doğrulama ve Test Altyapısı

Katlama mimarisinin doğruluğu 4 katmanlı test altyapısıyla garanti altına alınmıştır:

### A. Ayrıştırma Analiz Aracı (`--fold-dump`)
Herhangi bir Markdown dokümanındaki katlama bölgelerini ve gizlenen satırları terminale döker:
```bash
./build/anthracite --fold-dump dosya.md
```
Çıktı, her satırın sahip olup olmadığını, başlangıç/bitiş satırlarını ve katlandığında hangi satırların gizlendiğini doğrular.

### B. Golden Test Fikstür Seti (`tests/folds/`)
Aşağıdaki 12 senaryo `tests/folds/*.md` dosyaları ve bunlara ait `.golden` referans çıktılarıyla CTest paketinde doğrulanır:
1. `paragraf_liste.md`: Paragraf sonrası liste maddeleri.
2. `girintili_devam.md`: Liste maddesi altında girintili devam metni.
3. `ic_ice_liste.md`: 3 seviyeli hiyerarşik liste katlama.
4. `durum_koruma.md`: Orta seviyeyi katla, üst başlığı katla ve tekrar aç (alt durumun korunduğunu doğrula).
5. `baslik_hiyerarsi.md`: H1 > H2 > H3 başlıkları ve kardeş H2 ayrımı.
6. `kod_blok_icinde_diyez.md`: Kod bloğu içindeki `#` işaretlerinin başlık sayılmaması.
7. `callout_alinti.md`: Alıntı ve callout bloklarının katlanması (ilk satır görünür).
8. `liste_ici_bos_satir.md`: Liste maddeleri arasındaki boş satırların bölgeyi kesmemesi.
9. `tab_girinti.md`: Tab (4 sütun) ve boşluk girintilerinin tutarlı işlenmesi.
10. `alt_tik_derin_katlama.md`: Alt+Tık ile simetrik alt ağaç katlama/açma.
11. `ofset_kaymasi.md`: Dokümanın başına satır eklendiğinde katlama durumunun kayması.
12. `yaprak_madde.md`: Çocuksuz liste maddesinde katlama okunun çıkmadığının doğrulanması.

### C. Doğrulama Komutları
```bash
# 1. Derleme
nix-shell --run "cmake --build build --parallel"

# 2. Askeri Düzey Bellek Değişmezi Testi (live=1530113)
nix-shell --run "./build/anthracite --selftest"

# 3. Tüm CTest Birim ve Uyumluluk Testleri (77 test %100 Başarı)
nix-shell --run "ctest --test-dir build --output-on-failure"
```
