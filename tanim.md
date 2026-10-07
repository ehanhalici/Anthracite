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

Sistem bağımsız, birbiriyle katı tip sınırları üzerinden haberleşen şu modüllerden teşekkül eder:

1. **`core_platform`:** 
   * X11 olay kuyruğu yönetimi (`XNextEvent`, `ClientMessage`, atomik pencere protokolleri).
   * OpenGL bağlamı oluşturma (GLX/EGL), dikey eşzamanlama (V-Sync) ve takas (swap) döngüsü.
   * Çift tamponlu (double-buffered), GPU tabanlı olay temelli döngü (event loop); boşta dururken (idle) %0 CPU tüketimi için `select`/`poll` ile bloke olan soket dinlemesi.

2. **`core_render`:**
   * OpenGL vertex buffer yönetimi (VBO/VAO/EBO).
   * Dinamik UI bileşenleri için tek-geçişli (single-pass) anlık/yarı-korumalı (semi-retained) arayüz çizimi.
   * Yazı karakteri rasterizasyonu: Harf aralıkları (kerning) ve glif metriklerini saklayan önbelleklenmiş bir glif atlası (texture atlas).
   * Resim çizim hattı: Bellekte saklanan piksel dizilerini OpenGL dokularına (texture) dönüştüren dinamik texture bağlama (binding) yöneticisi.

3. **`data_image` (Yerel stb_image türevi):**
   * Harici C kütüphanesi olmadan; saf ATS2 ile yazılmış, doğrusal tip (`viewtype`) korumalı PNG/JPEG/BMP bayt dizisi ayrıştırıcısı.
   * Giriş bayt akışının doğruluğunu tip seviyesinde güvenceye alan, taşma (buffer overflow) olasılığı olmayan saf fonksiyonel görüntü çözümleyici.

4. **`data_ast` (Sözdizim Ağacı):**
   * Tree-sitter mimarisinden esinlenilmiş, artımlı (incremental) çalışan Obsidian Markdown sözdizim ayrıştırıcısı.
   * Her düğümün (node) metin ofset aralığını, derinliğini, katlanma durumunu ve görsel yüksekliğini tutan tip-güvenli ağaç yapısı.

5. **`ui_workspace`:**
   * **Üst Bar (Top Bar):** Sistem simgeleri, sekme çubuğu, sekme sürükle-bırak kontrolcüsü ve split-view (bölünmüş ekran) yerleşim mantığı.
   * **Sol Panel (Sidebar):** Dosya ağacı gezgini, arama paneli ve ayarlar çekmecesi.
   * **Düzenleyici Alanı (Editor Area):** Ortalı içerik tuvali (canvas), metin akışı, katlama yöneticisi, imleç ve zengin metin render alanı.

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
