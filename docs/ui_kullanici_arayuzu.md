# Çalışma alanı, etkileşim ve görsel yerleşim

UI doğrudan OpenGL çizimi yapan yerel bileşenler kullanır. Genel yerleşim
üst bar, yan panel, sekmeler ve bir/iki belge bölmesinden oluşur. RAD Debugger
esintisi tasarım bağlamıdır; bağımlılık veya birebir API uyumluluğu değildir.

## Gruplar

| Grup | Görev |
|---|---|
| [application](../src/ui_workspace/application) | App sahibi, başlangıç, olay yönlendirme ve mevcut selftest'ler |
| [common](../src/ui_workspace/common) | Tipler, geometri, tampon ve yol yardımcıları |
| [commands](../src/ui_workspace/commands) | Komut çözümleme, menü ve prompt işlemleri |
| [state](../src/ui_workspace/state) | Editör durum/geçişleri |
| [tabs](../src/ui_workspace/tabs) | Sekme, odak ve bölmeler |
| [tree](../src/ui_workspace/tree), [search](../src/ui_workspace/search) | Dosya ağacı ve arama paneli |
| [widgets](../src/ui_workspace/widgets) | Hücre, panel, ikon, scrollbar ve metin girişi |
| [visual](../src/ui_workspace/visual) | Sarma, izdüşüm, hit-test, navigasyon ve seçim |
| [render](../src/ui_workspace/render), [embed](../src/ui_workspace/embed) | Belge çizimi, medya ve embed sahipliği |
| [text](../src/ui_workspace/text) | Native metin servisleriyle UI köprüsü |

## Durum ve sahiplik

`EditorState` idle, typing, selecting, prompt, menu ve split-drag varyantlarına
sahiptir. `editor_fsm_contracts` altı durum ve on bir eylemin 66 geçişini bağımsız
tabloyla, yük verileri ve editing/modal bayraklarıyla karşılaştırır.
`editor_fsm_is_modal` prompt ve menü durumlarında true döndürür. Menü FSM'si
kapatma/Escape dışındaki arka plan eylemlerini zaten yok sayar; modal bilgisi
bu geçiş politikasıyla uyumludur (BUG-002 çözüldü).

`Cache`, görsel dokuları ve sahipliği kendisinde olan gömülü `Doc` nesnelerini
tutar. Embed alındığında sahiplik cache'ten çıkar, çizim/ölçümden sonra geri
konur. İsimli kapasite sınırında eski girdiler bırakılır; kapanışta bütün
belge/doku sahipleri serbest bırakılır. Embed tazeliği etkin fiziksel/VFS kaynağın
saniye/nanosaniye, boyut, cihaz ve inode bilgileri üzerinden denetlenir.
Cache isabeti dosyayı yeniden okumamalıdır; kaçırma/geçersizleştirme yükleme yapabilir.
Ölçüm ve çizim aynı belge cache'ini paylaşır; global path→yükseklik tablosu
yoktur. Blok yüksekliği ilgili hedef aralığının görsel satırlarından türetilir.
Doc'un sürümlü seyrek medya indeksi sıcak karede bütün AST taramasını önler;
görsel düğüm indeksi yalnız yerleşim yenilendiğinde kurulur.
Kanonik dosya/AST cache'i (48 Doc) ile görünüm geometrisi cache'i (128 giriş,
64 MiB) ayrıdır. Anchor aralığı, genişlik ve tam font bağlamı görünüm anahtarına
dahildir. Kaynak aynıysa farklı blok veya bölme genişliği AST'yi çoğaltmaz.
Aktif yola dönen embed döngüsü durdurulur; diğer zincirler derinlik 8 ile sınırlıdır.
Görünür kaynaklar önceliklidir; bir viewport üst/alt taşma payındaki miss'ler
4 ms esnek bütçeyle aşamalı hazırlanır. Uzak kaynaklar yüklenmez. Görünürlük
ilk tahmini yüksekliklerle belirlenir, gerçek yükseklikler gelince tekrar
değerlendirilir; üst kaynak satırı + piksel ofseti korunarak kaydırma düzeltilir.
Seçili görünüm ve bütçeye sığan görünür görünümler LRU tahliyesinden önce korunur.

Çocuk çizimleri `rend_clip_push/pop` ile ebeveyn clip'ine kesiştirilir;
embed, widget veya sekme kendi sınırını genişletip üst UI alanını boyayamaz.

`doc_resolve_anchor` boş hedefte bütün dosyayı, `^id` için tam blok kimliğini,
diğer hedeflerde tam başlık adını çözer. Çok satırlı paragraf, liste maddesi,
önceki bloğa bağlı bağımsız işaret ve başlık bölümü kaynak aralığı döndürür.
Kod çiti içindeki işaretler hedef değildir. Mevcut başlık eşleştirmesi kaynak
başlık metnine duyarlıdır; biçimlendirme/harf normalleştirmesi iddia edilmez.

Embed kutusunda düz tıklama hedef sekmesini açar/yeniden kullanır. 5 px'lik
sürükleme metin seçer ve hedef açmayı iptal eder; seçim tek kutunun hedef
aralığına sınırlandırılır. Seçim çocuk Doc caret'inden bağımsızdır; aynı dosyayı
gösteren diğer kutu vurgulanmaz. Ctrl+C görünür izdüşüm metnini mantıksal sırada
kopyalar; embed seçimi etkinken kesme/yazma/silme uygulanmaz. Sekme/ebeveyn
değiştiren kullanıcı girdisi seçim ömrünü sonlandırır. Yeni hedefe kaydırma
yerleşim hesaplandıktan sonra yapılır.
İç içe gömü ve wiki/Markdown linklerinde en içteki hedef tıklaması dış kutunun
hedefinden önce gelir. Aynı-dosya anchor'ı gömülü dosyaya aittir; Ctrl+tıklama
da aynı hedef çözümlemesini kullanır. Gezinmeden önce kaynak tazeliği doğrulanır.

`native_graphics_contracts` DejaVu Sans Mono'nun sabit metriklerini ve depodaki
Noto Naskh Arabic fixture'ını kullanır; uygulamanın seçilebilir fontu değildir.
CTest için ekran gerekir; DejaVu fixture bulunamazsa yapılandırmada açık uyarı
verilir. Test gömülü dosya/anchor/cache, kaynak tazeliği, sarma, clip pikselleri
ve seçim izolasyonunu da çalıştırır. Süresi tükenmiş iş bütçesi, takip kareleri,
uzak kaynakların yüklenmemesi, kaydırma anchor'ı ve iç içe hedef önceliği de sınanır.

## Görsel koordinatlar

Kaynak bayt ofseti, fiziksel satır, görsel sarma satırı ve piksel koordinatı
ayrı kavramlardır. Çizim, caret, fare hit-test ve dikey hareket aynı görsel satır
verisini kullanır. Önce katlama görünürlüğü, sonra görsel izdüşüm/yerleşim hazırlanır.

`source_edit_conformance`, görsel fixture'lar, FSM testi ve grafik selftest birlikte
değerlendirilir. GPU çıktı ve kullanıcı etkileşimlerinin tamamı sonlu durum
testlerinden otomatik olarak kanıtlanmış sayılmaz.
