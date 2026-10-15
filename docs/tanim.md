# Anthracite: Mimari ve Sistem Tasarım Belirtimi (tanim.md)

---

## 1. Giriş ve Temel Felsefe

**Anthracite**, yüksek yoğunluklu enerji ve sertliği temsil eden en saf kömür türünden adını alan; sıfır harici widget kütüphanesi bağımlılığıyla çalışan, aşırı hafif, matematiksel doğruluğu formel olarak kanıtlanabilir, yerel (native) bir Markdown bilgi yönetim sistemidir.

* **Dil ve Kanıtlama Sistemi:** Kod tabanının tamamı **ATS2 (Applied Type System 2 - Postiats)** ile yazılacaktır. ATS2'nin bağımlı tipleri (dependent types) ve lineer tipleri (linear types / linear logic) kullanılarak bellek sızıntıları, geçersiz işaretçi erişimleri (null pointer dereference, use-after-free) ve yarışma durumları (data race) derleme aşamasında matematiksel kesinlikle imkânsız kılınacaktır.
* **Görselleştirme ve Pencere Motoru:** Proje seviyesinde GTK, Qt, FLTK veya benzeri hiçbir yüksek seviyeli GUI araç kiti kullanılmayacaktır. Pencere yönetimi, işletim sistemi olayları ve yüzey oluşturma yalnızca **X11 (Xlib/XCB temel protokol)** ile; çizim, render hattı (rendering pipeline) ve piksel operasyonları doğrudan **OpenGL (modern çekirdek profil / Core Profile)** ile icra edilecektir.
* **Inline C Politikası:** C dili sadece ATS2'nin X11 veya POSIX sistem çağrılarına sarmalayıcı (wrapper) sağladığı en yalın `extype` / `mac#` arayüzlerinde; zorunlu FFI köprülerinde asgari düzeyde tutulacaktır. Tüm veri yapıları, kontrol akışları, bellek denetimleri ve algoritma gövdeleri katı bir şekilde saf ATS2 sözdizimi ile inşa edilecektir.
* **Tek Görev Prensibi (SRP):** Her fonksiyon yalnız tek bir mantıksal işi üstlenecek; durumlar (state) ve bellek tahsisleri doğrusal tipler (linear proofs, `view@`) altında modüler dosyalara ayrıştırılacaktır.

---

## 2. Mimari Bileşenler ve Modül Hiyerarşisi

Sistem bağımsız, birbiriyle katı tip sınırları üzerinden haberleşen ve her biri ayrıntılı bir **Yetenek Kılavuzu (Skill Guide)** olarak belgelenmiş şu modüllerden teşekkül eder:

1. **`core_platform` & `core_runtime` ([Platform ve Olay Döngüsü Yeteneği](file:///home/emrehan/kod/kod/anthracite/docs/platform_ve_olay_dongusu.md)):**
   * X11 olay kuyruğu yönetimi (`XNextEvent`, `ClientMessage`, atomik pencere protokolleri).
   * OpenGL bağlamı oluşturma (GLX/EGL), dikey eşzamanlama (V-Sync) ve takas (swap) döngüsü.
   * Çift tamponlu (double-buffered), GPU tabanlı olay temelli döngü; boşta dururken (idle) %0 CPU tüketimi için `select`/`poll` ile bloke olan soket dinlemesi.

2. **`core_render` ([OpenGL Çizim Motoru Yeteneği](file:///home/emrehan/kod/kod/anthracite/docs/cizim_motoru.md)):**
   * OpenGL vertex buffer yönetimi (VBO/VAO/EBO).
   * Dinamik UI bileşenleri için tek-geçişli (single-pass) anlık/yarı-korumalı arayüz çizimi.
   * Yazı karakteri rasterizasyonu: Glif metriklerini saklayan önbelleklenmiş glif atlası (texture atlas).
   * Resim çizim hattı: Piksel dizilerini OpenGL dokularına dönüştüren doku bağlama yöneticisi.

3. **`data_ast` ([AST Sözdizim Ağacı](file:///home/emrehan/kod/kod/anthracite/docs/ast_sozdizim_agaci.md) ve [Katlama Özelliği](file:///home/emrehan/kod/kod/anthracite/docs/katlama_ozelligi.md)):**
   * Artımlı (incremental) çalışan Markdown sözdizim ayrıştırıcısı (`ast_reparse_v2`).
   * Düğüm ofset aralığını, derinliğini, katlanma durumunu ve yüksekliğini tutan tip-güvenli ağaç yapısı.
   * FRT (Fold Region Table) yığın motoru ile askeri düzey hiyerarşik kod/metin katlama ve durum izolasyonu.

4. **`ui_workspace` ([Kullanıcı Arayüzü, RAD Debugger Mimarisi ve Çalışma Alanı](file:///home/emrehan/kod/kod/anthracite/docs/ui_kullanici_arayuzu.md)):**
   * **RAD Debugger Bileşenleri (`ui_widgets.*`):** Hiyerarşik ağaç/tablo hücresi (`ui_cell`), debugger kesiti ve kesme noktası (`ui_code_slice`), gölgeli paneller (`ui_pane`), orantılı kaydırma çubukları (`ui_scroll_bar`), tek satırlı editör (`ui_line_edit`) ve modal yükleme kartı (`ui_loading_overlay`).
   * **Çalışma Alanı & Split View:** Üst Bar, yeniden boyutlandırılabilir Sidebar (tutamaçlı), sekmeler, sürükle-bırak dinamik dikey split-view.
   * **Durum Makineleri (FSM) & Komutlar:** `editor_fsm` modal kontrolü, `embed_fsm` asenkron görsel önbelleği, 55+ atomik komut ve yumuşak sarma (soft wrap) dikey görsel gezinmesi.

5. **`data_text` ([Yerel Metin ve Unicode 18 Motoru](file:///home/emrehan/kod/kod/anthracite/docs/metin_ve_unicode_motoru.md)):**
   * Katı UTF-8 kod çözümü (Maximal Subpart Replacement), Unicode 18 özellik veritabanı.
   * UAX #29 Grafem ve Kelime Sınırları, UAX #14 Satır Kesme, dört normalizasyon formu (NFC/NFD/NFKC/NFKD).
   * UAX #9 Çift Yönlü Metin (Bidi) çözümü.

6. **`data_font` ([OpenType ve Glif Motoru](file:///home/emrehan/kod/kod/anthracite/docs/yazi_tipi_glif_motoru.md)):**
   * Saf ATS2 SFNT / TTF / OTF tablo okuyucuları, Harf Biçimlendirme Hattı (Shaping Pipeline).
   * GSUB ligatür ikameleri, GPOS ikili harf aralığı (Pair Kerning) ve Arapça harf birleştirme FSM'si.

7. **`data_image` ([Görsel İşleme Motoru](file:///home/emrehan/kod/kod/anthracite/docs/gorsel_isleme_motoru.md)):**
   * Saf ATS2 ile yazılmış, doğrusal tip (`viewtype`) korumalı PNG, BMP ve JPEG çözücüler.
   * zlib/DEFLATE açıcı, Paeth filtresi, IDCT ve bilinear yeniden boyutlandırma.

8. **`mem` & `airlock` ([Bellek ve Güvenlik Mimarisi](file:///home/emrehan/kod/kod/anthracite/docs/bellek_ve_guvenlik_mimarisi.md)):**
   * Doğrusal bellek tamponları (`Buf`), `view@` ve tek-sahiplik kanıtları.
   * Airlock sınır kapıları, `MAX_REC_FUEL` yakıt sayaçları ve `live=1530113` bellek değişmezi.

9. **`os` ([Sanal Dosya Sistemi VFS ve Tanılama](file:///home/emrehan/kod/kod/anthracite/docs/isletim_sistemi_ve_dosya_sistemi.md)):**
   * RAM-FS bellek içi dosyalama (`/dev/shm/anthracite/`), atomik otomatik kaydetme, yapılandırılmış tanılama (`diag.*`).

10. **`search` ([Arama ve İndeksleme](file:///home/emrehan/kod/kod/anthracite/docs/arama_ve_indeksleme.md)):**
    * Çalışma alanı Ripgrep (`rg`) entegrasyonu, doküman içi hızlı eşleştirme (`ix_match`), katlama-duyarlı arama navigasyonu.

---

## 3. Kullanıcı Arayüzü ve Yerleşim (Layout) Özellikleri

### 3.1. Üst Bar (Top Bar)
* **Sabit Entegrasyon:** Pencerenin en üstünde sabit piksel yüksekliğine sahip tek bir çubuk yer alır.
* **Sol Kontrol Grubu:** 
  * En solda üç adet geometrik simge/buton bulunur:
    1. *Dosya Gezgini Aç/Kapa* (Sidebar Toggle).
    2. *Genel Arama* (Global Search).
    3. *Ayarlar* (Preferences).
* **Sekme Alanı (Tabs Container):**
  * Sol kontrol butonlarından sonra bırakılan mimari boşluğun ardından dinamik sekme çubuğu başlar.
  * Açılan her doküman, üzerinde kapatma butonu ve başlık bulunan bir sekme olarak burada listelenir.
  * **Sekme Sürükle-Bırak ve Bölünmüş Ekran (Split View):**
    * Sekmeler üst bar üzerinde fare ile tutulup yer değiştirebilir.
    * Bir sekme tutulup çalışma alanının sağına doğru sürüklendiğinde yerleşim motoru tetiklenir; ekran dikeyde iki eşit alana bölünerek (`Left / Right Split View`) aynı anda iki farklı sekmenin bağımsızca görüntülenmesini ve düzenlenmesini sağlar.

### 3.2. Sol Panel (Sidebar) ve Dosya Gezgini
* **Çalışma Modları:** Panel sadece dosya sistemi gezgini, arama sonuçları veya ayarlar modundan birini gösterir; üst bardaki butonlarla gizlenebilir/açılabilir.
* **Dosya Sistemi Ağacı:**
  * Kök dizinden itibaren klasör ve dosyaları hiyerarşik girintilerle listeler.
  * **Sürükle-Bırak (Drag & Drop):** Dosya veya klasörler, ağaç üzerinde sürüklenerek başka bir dizin düğümünün içerisine taşınabilir; taşıma işlemi atomik POSIX dosya sistemi çağrılarıyla paralel işletilir.
  * **Bağlam Menüsü (Sağ Tık):** Boşluğa veya bir öğeye tıklandığında imleç konumunda hafif, GPU üzerinde çizilen yerel bir menü açılır:
    * *Yeni Dosya Oluştur*
    * *Yeni Klasör Oluştur*
    * *Yeniden Adlandır*
    * *Sil* (Dosya sisteminden güvenli kaldırma)

### 3.3. Arama Paneli (Search Engine)
* Üst bardaki arama düğmesi tetiklendiğinde sol panel arama arayüzüne geçer.
* Proje dizini altındaki tüm Markdown dosyaları üzerinde dizinlenmiş veya gerçek zamanlı metin taraması yapar.
* Sonuçlar salt düz metin listesi şeklinde değil; **dosya bazında gruplanmış**, bulunan satırın bağlamını ve eşleşen ifadenin ofsetini vurgulayan alt dökümler halinde basamaklı olarak gösterilir.

---

## 4. Markdown Düzenleme, AST ve Obsidian Uyumluluğu

### 4.1. Ortalı İçerik Alanı (Centered Canvas)
* Sol panelin dışındaki kalan tüm serbest alan düzenleme ve okuma alanıdır.
* Okunabilirlik ergonomisi (tipografik standartlar) gereği metin bloğu pencere genişliğine yayılmaz; azami genişliği sınırlandırılmış (ör. 720px - 850px) bir sütun olarak pencerenin yatay ekseninde **matematiksel olarak tam ortalanır**.

### 4.2. Tree-Sitter Benzeri Ayrıştırıcı ve AST Yapısı
* **Temsil Biçimi:** Doküman, bellekte düz bir metin olarak değil; satır aralıkları, blok sınırları ve stilleri önbelleğe alan doğrusal bağlı bir AST (Soyut Sözdizim Ağacı) olarak tutulur.
* **Artımlı Güncelleme (Incremental Parsing):** Kullanıcı bir harf girdiğinde veya sildiğinde belgenin tamamı yeniden ayrıştırılmaz; yalnızca değişikliğin etkilediği AST düğümü ve ebeveynleri yeniden hesaplanır.
* **Obsidian Sözdizim Kapsamı (Tam Uyumluluk):**
  * Temel CommonMark / GFM kuralları: Başlıklar (`#`..`######`), listeler, blok alıntılar (`>`), tablolar, kod blokları (fenced codeblocks), yatay çizgiler.
  * **İç Bağlantılar (Wikilinks):** `[[Sayfa Adı]]`, `[[Sayfa Adı|Görünen İsim]]`, `[[Sayfa Adı#Başlık]]`.
  * **Gömme / Dahil Etme (Transclusion):** `![[Sayfa Adı]]`, `![[Resim.png]]`.
  * **Etiketler (Tags):** `#etiket/alt-etiket`.
  * **Görev Listeleri (Task Lists):** `- [ ]`, `- [x]`, `- [/]`.
  * **Dipnotlar (Footnotes):** `[^1]` ve `[^1]: Tanım`.
  * **Vurgu (Highlights):** `==vurgulanan metin==`.
  * **Matematiksel İfadeler:** `$inline$` ve `$$display$$` LaTeX blokları (glif bazında render).
  * **Üst Veri (Frontmatter):** Dosya başındaki YAML/YAML-benzeri blokların tespiti.

### 4.3. AST Tabanlı Etkileşimler
* **Kod Katlama (Folding):** AST üzerindeki hiyerarşi sayesinde, herhangi bir başlık (`#`) veya liste bloğunun solundaki ok simgesi tetiklendiğinde, altındaki tüm düğümlerin çizim bayrağı `collapsed = true` durumuna geçirilir. Layout motoru bu düğümlerin yüksekliğini anında `0` kabul ederek sanal kaydırma (virtual scroll) sınırlarını günceller.
* **Sözdizim Renklendirme:** Her düğüm kendi token türüne göre önceden tanımlanmış koyu tema renk paleti (`Anthracite Dark Scheme`) ile eşleştirilir; gölgelendiriciye (fragment shader) renk ve stil indeksleri aktarılır.
* **Link Takibi (Navigation):** `[[WikiLink]]` düğümlerine fare ile `Ctrl + Sol Tık` yapıldığında AST üzerinden hedef dosyanın adı çözümlenir, dosya gezgini motoru tetiklenir ve hedef doküman yeni sekmede ya da mevcut sekmede açılır.
* **Rander Modu:** Obsidian da oldugu gibi metnin raw halini de gosterecek Okunabilir halini de gosterecek. bu sag ustteki tek bir dugme ile yapilacak. ATS yapisi sayesinde okuma modunda obsidian gibi formatlama yapilacak.

---

## 5. Grafik Hattı, Görsel İşleme ve Düzenleme İşlemleri

### 5.1. Yerel Görsel Motoru (Pure ATS2 stb_image Portu)
* Harici paylaşılan kütüphaneler (`libpng`, `libjpeg`) dinamik olarak bağlanmaz.
* Standart formatların (özellikle PNG ve JPEG) kod çözme mantığı, `stb_image` algoritması baz alınarak ATS2'ye aktarılmış yerel modül üzerinden çalışır.
* Görsel baytları çözümlenip açıldığında doğrudan GPU'ya aktarılır (`glTexImage2D`), sisteme ait bir doku tanıtıcısı (texture ID) üretilir ve AST'deki `![[resim]]` veya `![](url)` düğümünün boyut rezervasyonuna (`width`, `height`) bağlanır. Metin akışı bu görselin kapladığı piksel yüksekliği kadar aşağı ötelenerek görsel metin arasına pürüzsüzce yerleştirilir.

### 5.2. Metin Düzenleme ve Bağlam Kısayolları
* **Hafıza Modeli:** Yazı düzenleme performansını en üst düzeye çıkarmak adına metin gövdesi bellek üzerinde **Gap Buffer** veya **Rope** yapısında tutulur; bu yapı AST'nin yaprak düğümleriyle birebir doğrulanır.
* **Sağ Tık Menüsü:** Metin alanında veya resimlerin üzerinde sağ fare tuşuna basıldığında ekranda bağlamsal menü açılır:
  * Metin üzerinde: *Kes (Cut)*, *Kopyala (Copy)*, *Yapıştır (Paste)*, *Biçimlendirmeyi Temizle*.
  * Görsel üzerinde: *Görseli Kopyala*, *Dosya Konumunu Aç*, *Dokümandan Kaldır*.
* **İşletim Sistemi Pano Entegrasyonu:** X11 seçki mekanizmaları (`CLIPBOARD` ve `PRIMARY` atomları) ATS2 seviyesinde asenkron olaylarla yönetilerek masaüstü ortamıyla tam uyumlu kopyalama/yapıştırma protokolü sağlanır.

---

## 6. Güvenlik, Performans ve Derleme Hedefleri

| Metrik / Bileşen | Tasarım Kriteri |
| :--- | :--- |
| **Bağımlılıklar** | Salt POSIX libc, X11 (`libX11`), OpenGL (`libGL`). Harici UI/Ayrıştırıcı kütüphanesi yasaktır. |
| **Bellek Güvenliği** | ATS2 lineer tipleri (`@view`, `viewtype`) sayesinde çalışma zamanı çöp toplayıcısına (Garbage Collector) ihtiyaç duyulmaz. Manuel tahsis edilen her bayt, derleme anında serbest bırakılma ispatına tabidir (`mfree`). |
| **İşlemci Kullanımı** | Olay olmadığında `XPending` ve `poll` bloklamasıyla mutlak surette **%0 CPU**. |
| **Bellek Ayak İzi** | Boşta çalışma anında azami **5 MB - 12 MB RAM**. |
| **Açılış Süresi** | Soğuk başlatmada (cold start) **< 15 milisaniye**. |
