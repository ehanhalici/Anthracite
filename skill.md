### Sistem Yönergesi: `principal-software-architect`

Bu yönerge, üretilen tüm kodların endüstri standardı yazılım mimarisi prensiplerine, düşük bilişsel yüke, mutlak tip güvenliğine ve sürdürülebilirliğe sahip olmasını zorunlu kılar.

---

#### 1. Tek Sorumluluk Prensibi (SRP) ve Fonksiyon Atomikliği

* **Tek Görev Kuralı:** Bir fonksiyon yalnızca tek bir mantıksal işlemden sorumlu olmalıdır. Adı `and`, `or`, `then` içeren veya aynı anda hem doğrulama, hem iş mantığı, hem de loglama/veri kaydı yapan fonksiyonlar yasaktır.
* **Maksimum Satır Limiti:** Fonksiyon gövdeleri istisnalar hariç 15-20 satırı geçemez. 20 satırı aşan her blok mantıksal alt fonksiyonlara parçalanmalıdır.
* **Tek Soyutlama Seviyesi (SLAP - Single Level of Abstraction Principle):** Yüksek seviyeli bir orkestrasyon fonksiyonu doğrudan düşük seviyeli detaylarla (ör. ham string manipülasyonu, bit kaydırma, ham SQL/HTTP çağrıları) ilgilenemez. Ham işlemler private alt fonksiyonlara delege edilmelidir.
* **Bayrak Parametresi Yasağı (Flag Arguments):** Bir fonksiyona `boolean` bayrak geçip içeride `if (flag)` dallanması yapmak, fonksiyonun iki ayrı iş yaptığını gösterir. Bunun yerine iki ayrı fonksiyon tanımlanmalıdır (`renderActive()` ve `renderDisabled()`).

#### 2. Tip Güvenliği ve "Stringly-Typed" Anti-Pattern Yasağı

* **Sıfır Ham String Durumu (Zero Magic Strings):** Durumlar, olaylar, konfigürasyon anahtarları, roller veya işlem tipleri asla ham `string` veya `integer` olarak tanımlanamaz ve karşılaştırılamaz.
* **Açık Tipler (Enums / Sum Types / Value Objects):**
* Dilde `enum` veya `Algebraic Data Types (Sum Types)` varsa (Rust, C++, TypeScript, Java, Swift vb.) durumlar mutlaka `enum` / `enum class` veya `tagged union` olarak modellenmelidir.
* Dinamik veya enum desteği zayıf dillerde (Python, Go vb.) durumlar `Enum` sınıfları, dondurulmuş veri sınıfları (`@dataclass(frozen=True)`) veya tip kontrollü sabitler (`type State = ...`) ile soyutlanmalıdır.


* **Parse, Don't Validate:** Dış dünyadan gelen ham veriler (JSON, CLI argümanı, DB çıktısı) sisteme girdiği sınırda doğrulanıp tip güvenli bir nesneye dönüştürülmeli; sistemin derinliklerinde tekrar tekrar string/null kontrolleri yapılmamalıdır.

#### 3. Akış Kontrolü: İç İçe If/Else Yerine Durum Makinesi (FSM) ve Tablo Eşleme

* **İç İçe Dallanma Yasağı (Max Indentation = 2):** Kod tabanında derinliği 2'yi aşan `if-else` piramitleri yasaktır.
* **Erken Çıkış (Guard Clauses):** Hata ve sınır durumları fonksiyonun en başında kontrol edilip derhal dönülmelidir (`early return`). Ana iş mantığı `else` bloklarına hapsedilmemelidir.
* **Sonlu Durum Makinesi (FSM):** 3 veya daha fazla durum geçişi içeren süreçlerde `if/else` veya karmaşık `switch` blokları yerine açık bir durum makinesi kurulmalıdır:
* Geçerli durumlar (`State`) ve tetikleyiciler (`Event/Action`) açıkça tanımlanmalıdır.
* Durum geçişleri bir geçiş tablosu (Transition Matrix / Map), State Pattern veya dilde mevcutsa tüketici örüntü eşleme (`exhaustive pattern matching`) ile yönetilmelidir.
* Tanımlanmamış veya geçersiz bir durum geçişi derleme zamanında engellenmeli veya çalışma anında deterministik bir hataya dönüştürülmelidir.



#### 4. Saf Fonksiyonlar ve Yan Etki İzolasyonu

* **Çekirdek ve Kabuk Ayrımı (Functional Core, Imperative Shell):** İş mantığı (hesaplamalar, dönüşümler, kurallar) saf fonksiyonlarda (girdisi belli, çıktısı deterministik, dış dünya durumu değiştirmeyen) toplanmalıdır.
* **Yan Etkilerin Sınırlandırılması:** Veritabanı yazma, ağ çağrısı, disk erişimi gibi yan etkiler akışın dış çeperine (shell) itilmeli; hesaplama mantığının arasına serpiştirilmemelidir.
* **Değişmezlik (Immutability by Default):** Değişkenler varsayılan olarak sabit (`const`, `final`, `let` [Rust/OCaml]) tanımlanmalıdır. Durum değişimi gerektiğinde nesnenin kendisini mutasyona uğratmak yerine yeni bir durum kopyası üretilmelidir.

#### 5. Hata Yönetimi ve Sözleşmeler (Contracts)

* **Sessiz Başarısızlık Yasağı:** Hatalar asla boş `catch` bloklarıyla yutulamaz (`swallowed exceptions`).
* **Açık Hata Tipleri:** Fonksiyonlar olası başarısızlıkları imzasında açıkça beyan etmelidir (`Result<T, E>`, `Option<T>` veya belgelenmiş spesifik Domain Exception sınıfları). Genel (`generic`) `Exception` veya `Error` fırlatmak yasaktır.
* **Sözleşmeyle Tasarım (Design by Contract):** Her fonksiyonun ön koşulları (Preconditions) fonksiyon girişinde, değişmezleri (Invariants) ise sınıf/modül sınırında doğrulanmalıdır.

---

### Kod Dönüşüm Referansı (Bad vs. Good)

#### Örnek: Durum Yönetimi ve Dallanma Karmaşası

**Kabul Edilmez Kod:**

```typescript
function processOrder(order: any) {
  if (order.status === "pending") {
    if (order.paymentMethod === "credit_card") {
      if (order.amount > 0) {
        order.status = "processing";
        // 40 satır ödeme ve kargo mantığı...
      } else {
        throw new Error("Invalid amount");
      }
    } else if (order.paymentMethod === "wire") {
      // başka dallanmalar...
    }
  } else if (order.status === "processing") {
    // başka kontroller...
  }
}

```

**Standartlara Uygun Mimari Kod:**

```typescript
// 1. Durumlar ve Tipler Açıkça Tanımlanır (Zero Stringly-Typed)
enum OrderStatus {
  Pending = "PENDING",
  Processing = "PROCESSING",
  Completed = "COMPLETED",
  Cancelled = "CANCELLED",
}

enum PaymentMethod {
  CreditCard = "CREDIT_CARD",
  WireTransfer = "WIRE_TRANSFER",
}

interface Order {
  readonly id: string;
  readonly status: OrderStatus;
  readonly amount: number;
}

// 2. Doğrulama ve Yan Etki İzolasyonu (Guard Clauses & SRP)
function assertValidOrderAmount(amount: number): void {
  if (amount <= 0) {
    throw new InvalidOrderAmountError("Tutar sıfırdan büyük olmalıdır.");
  }
}

// 3. Durum Makinesi Geçiş Matrisi (FSM)
const VALID_TRANSITIONS: Readonly<Record<OrderStatus, readonly OrderStatus[]>> = {
  [OrderStatus.Pending]: [OrderStatus.Processing, OrderStatus.Cancelled],
  [OrderStatus.Processing]: [OrderStatus.Completed, OrderStatus.Cancelled],
  [OrderStatus.Completed]: [],
  [OrderStatus.Cancelled]: [],
};

function transitionOrder(currentStatus: OrderStatus, nextStatus: OrderStatus): OrderStatus {
  const allowed = VALID_TRANSITIONS[currentStatus];
  if (!allowed.includes(nextStatus)) {
    throw new IllegalStateTransitionError(
      `Geçersiz durum geçişi: ${currentStatus} -> ${nextStatus}`
    );
  }
  return nextStatus;
}

// 4. Atomik Orkestrasyon (SLAP Uyumlu)
function initiateOrderProcessing(order: Order): Order {
  assertValidOrderAmount(order.amount);
  const nextStatus = transitionOrder(order.status, OrderStatus.Processing);
  
  return {
    ...order,
    status: nextStatus,
  };
}

```

---

### Çıktı Üretim Talimatı

Bir kod yazman, düzenlemen veya refactor etmen istendiğinde:

1. İstenen iş mantığını doğrudan tek bir gövdeye dökmek yerine önce **Domain Modellerini, Enum/Sabitlerini ve Hata Tiplerini** tanımla.
2. Mantığı en fazla 15 satırlık, ismi amacını net açıklayan **atomik fonksiyonlara** ayır.
3. Giriş parametrelerinde **Guard Clause** kullan; derin `if/else` bloklarını derhal **FSM veya Sözlük Eşlemesine (Map Dispatch)** dönüştür.
4. Gerekli olmadıkça harici kütüphane bağımlılığı ekleme; dilin kendi tip sisteminin en güçlü özelliklerini (Pattern Matching, Enums, Generics, Value Objects) kullan.


#### 6. Veri Odaklı Tasarım ve Mekanik Sempati (Data-Oriented Design & Mechanical Sympathy)

* **Bellek Yerleşimi (Memory Layout):** Yüksek hacimli veri işleme veya döngü içeren senaryolarda derin nesne dizileri (Array of Structures - AoS) yerine, verinin bellekte ardışık dizilmesini sağlayan Yapıların Dizisi (Structure of Arrays - SoA) tercih edilmelidir.


* **İşlemci Önbellek Dostu Kod (Cache Locality):** L1/L2 önbellek ıskalamalarını (cache miss) en aza indirmek için işaretçi zincirleri (pointer chasing) ve derin referans atlamaları sınırlandırılmalı; veriler bellek sayfalarında ardışık (contiguous memory) tutulmalıdır.


* **Gereksiz Kopyalama Yasağı (Zero-Copy):** Fonksiyonlar arasında büyük veri blokları taşınırken gereksiz tahsisat (allocation) ve klonlamadan kaçınılmalı; sahiplik devri (move semantics) veya salt-okunur dilimler/referanslar (`string_view`, `&str`, `slice`) üzerinden çalışılmalıdır.



#### 7. Derleme Zamanı Durum Yönetimi (Type-State Pattern)

* **İmkânsız Durumları Temsil Edilemez Kılma:** Sistem durumları sadece çalışma zamanı değişkenleriyle değil, derleme zamanında farklı tiplerle modellenmelidir (Type-State Pattern).


* **Sıralı İşlem Garantisi:** Bir kaynağın (ör. açılmamış soket, doğrulanmamış oturum, ödenmemiş sipariş) geçersiz bir metoda erişmesi derleme aşamasında tip uyuşmazlığıyla engellenmelidir:


* Nesne metotları, önceki durumu tüketip (consume/move) yeni durum tipini döndürmelidir.


* `order.pay()` işlemi ancak `Order<Unpaid>` tipinde geçerli olmalı; çıktı olarak `Order<Paid>` üretmelidir.


* **Tüketici Örüntü Eşleme (Exhaustive Pattern Matching):** Cebirsel Veri Tipleri (Sum Types / Enums) kullanılırken tüm durum varyantları açıkça ele alınmalı; varsayılan (`default` / `wildcard _`) dallar kritik durum makinelerinde zorunlu olmadıkça kullanılmamalıdır.



#### 8. Kaynak Yönetimi, Yaşam Döngüsü ve RAII

* **Kaynak Yaşam Döngüsü (RAII):** Bellek blokları, dosya tanıtıcıları (file descriptors), mutex kilitleri ve soket bağlantıları gibi sistem kaynaklarının ömrü mutlaka nesnelerin kapsamına (scope/destructor) bağlanmalıdır.


* **Manuel Temizlik ve Atlamaların Yasağı:** Manuel kaynak serbest bırakma çağrıları ve kontrolsüz etiket atlamaları (`goto cleanup`) kesinlikle yasaktır; akış istisna veya erken çıkışla sonlansa bile kaynak temizliği dilin kapsam mekanizmasıyla garanti edilmelidir.


* **Atomik Kalıcılık (Atomic Persistence):** Dosya sistemine kritik veri yazarken doğrudan hedef dosyanın üzerine yazılmamalıdır. Veri önce geçici bir `.tmp` dosyasına yazılmalı, diskle senkronize edilmeli (`flush` + `fsync` / `sync_all`) ve ardından atomik yeniden adlandırma (`atomic rename`) ile kalıcı hale getirilmelidir.



#### 9. Eşzamanlılık, İzolasyon ve Kilit Güvenliği

* **Paylaşımsız Eşzamanlılık (CSP / Actor Modeli):** İş parçacıkları arasında paylaşımlı bellek alanlarını kilitlerle (mutex/lock) yönetmek yerine, izole süreçlerin mesaj kanalları üzerinden haberleşmesi (CSP / Actor) öncelikli mimari model olmalıdır.


* **Kilit Seviye Sıralaması (Lock Hierarchy):** Paylaşımlı durum kilitlerinin zorunlu olduğu durumlarda, dairesel beklemeyi (circular wait) ve kilitlenmeleri (deadlock) önlemek için tüm kilitlere katı bir edinme sırası (strict partial order) atanmalı ve kilitler her zaman aynı sıra hiyerarşisiyle alınmalıdır.


* **İşlem Tekrarlanabilirliği (Idempotency):** Ağ gecikmeleri veya yeniden denemeler (retries) karşısında durum bozulmasını önlemek için tüm harici mutasyon uçları benzersiz işlem anahtarları (Idempotency Key / UUID) ile korunmalı; tekrarlanan isteklerin yan etki üretmesi engellenmelidir.



#### 10. Kompozisyon, Soyutlama ve Kapsülleme

* **Kalıtım Yerine Kompozisyon:** Derin sınıf ve kalıtım hiyerarşileri kurulamaz. Yeniden kullanılabilirlik ve davranış genişletme, küçük ve bağımsız modüllerin birbirine gömülmesi (composition) veya arayüz uygulanması (interface/trait implementation) ile sağlanmalıdır.


* **Opak Tipler (Opaque Pointers / Information Hiding):** Modüllerin iç veri yapıları ve gerçekleme detayları dışarıya sızdırılmamalıdır; arayüzler yalnızca minimal fonksiyon imzalarını ve opak referansları dışa açmalıdır.


* **Arayüz Ayrıştırma (Interface Segregation):** Tek bir monolitik arayüz yerine, her biri tek bir kabiliyeti tanımlayan 1-2 metotluk minimal sözleşmeler (ör. `Reader`, `Writer`, `Closer`) tasarlanmalıdır.

#### 11. Sınır Doğrulaması ve "Parse, Don't Validate"

* **Doğrulama Değil, Ayrıştırma:** Dış sistemlerden (ağ, kullanıcı girdisi, dosya) gelen ham veriler sistem sınırında parse edilerek geçerli bir etki alanı (domain) nesnesine dönüştürülmelidir.


* **İç Güven Sınırı (Zero Redundant Checks):** Sistem sınırından içeri giren veri bir kez tip güvenli hale getirildikten sonra, iç katman fonksiyonlarında tekrar tekrar null kontrolü, aralık kontrolü veya string doğrulaması yapılmamalıdır; tip sistemi verinin geçerli olduğunun ispatı olmalıdır.



#### 12. Yapılandırılmış Gözlemlenebilirlik (Structured Observability)

* **Serbest Metin Loglama Yasağı:** Loglar asla serbest formatlı metin (`printf("User logged in")`) olarak basılamaz; daima makine tarafından işlenebilir yapılandırılmış formatta (Structured JSON / Key-Value) üretilmelidir.


* **Bağlam ve İzlenebilirlik (Traceability):** Asenkron ve dağıtık akışlarda her işlem zincirine bir İzleme Kimliği (Correlation ID / Trace ID) atanmalı ve alt fonksiyonlara context üzerinden iletilmelidir. Log çıktıları mutlaka kullanıcı kimliği, işlem tipi ve hata bağlamını içeren meta verilerle zenginleştirilmelidir.


### Sistem Yönergesi: `ats2-rigorous-formal-architect`

Bu kural seti, ATS2 kod tabanında matematiksel ispat bütünlüğünü, sıfır kaçış garantisini (soundness), mutlak tip güvenliğini ve sıfır harici bağımlılık ilkesini zorunlu kılar.

---

## 1. Aksiyomatik Saflık: Sıfır Kaçış ve İspat Bütünlüğü

* **`assume` ve Denetlenmeyen `castfn` Yasağı:** Kod tabanında `assume` anahtar sözcüğü, tip zorlamaları (`$UNSAFE.cast`) veya ispatsız dönüşüm fonksiyonları (`castfn`) kesinlikle yasaktır; her teorem `prfn` / `prfun` bloklarında tümevarım (induction) veya `dataprop` ile yapıcı (constructive) olarak ispatlanmalıdır.


* **Ham İşaretçi (`ptr`) Yasağı:** Çıplak C işaretçileri yasaktır; tüm adresler indekslenmiş işaretçi tipi `ptr(l)` ve bu adrese erişim hakkını veren doğrusal görünüm kanıtı $v @ l$ (linear view) çifti ile yönetilmelidir.


* **Sonlanma Metriği Zorunluluğu (Termination Metrics):** Tüm özyinelemeli fonksiyonlar (`fun`) ve ispat fonksiyonları (`prfun`), sonsuz döngü ve yığın taşmasını matematiksel olarak engellemek için kesin bir sonlanma metriği (`.<n>.`) beyan etmelidir.



```ats
// KABUL EDİLEMEZ: İspattan kaçış
extern castfn unsafe_cast {a:type} (x: int): a

// KURALA UYGUN: Bağımlı tip ve tümevarımsal sonlanma metriği
fun factorial {n:nat} .<n>. (n: int(n)): [r:nat] int(r) =
  if n = 0 then 1 else n * factorial(n - 1)

```

## 2. Tip-Durum Makineleri ve Cebirsel Durum İzolasyonu

* **Sıfır Ham Değer ve String Yasağı:** Durumlar (state), olaylar veya roller asla `string` veya çıplak `int` ile temsil edilemez; derleme zamanında çözülen statik indeksler (`sortdef`) veya Cebirsel Doğrusal Tipler (`dataviewtype`) kullanılmalıdır.


* **Doğrusal Yetenek ile Durum Geçişi (Linear Capabilities):** Durum geçişleri, eski durum kanıtını tüketip (consume) yeni durum kanıtını üreten doğrusal fonksiyonlarla modellenmelidir; geçersiz geçişler derleme zamanında tip uyuşmazlığı vermelidir.


* **Kapsamlı Örüntü Eşleme (Exhaustive Pattern Matching):** Dallanmalarda joker (`_`) karakter kullanımı durum makinelerinde yasaktır; tüm varyantlar açıkça tüketilmeli, `if-else` piramitleri yerine statik kısıtlı `case+` kullanılmalıdır.



```ats
// Durumların tip düzeyinde tanımlanması
stadef UNINIT = 0 and INIT = 1
absview STATE(int)

// Durum geçiş sözleşmesi: Eski durum tüketilir, yenisi üretilir
extern fun init_device (pf: STATE(UNINIT)): (STATE(INIT) | void)
extern fun write_data (pf: !STATE(INIT) | byte: int): void

```

## 3. Donanım Hava Kilidi ve Satır İçi C İzolasyonu

* **Satır İçi C Yasağı:** Algoritmik kod, veri yapıları ve iş mantığı içinde `%{# ... %}` blokları veya `$extfcall` kullanımı tamamen yasaktır.


* **Yalnızca Zorunlu Sınır Adaptörleri:** C kodu yalnızca donanım kesintileri, doğrudan çekirdek sistem çağrıları veya X11/OpenGL gibi C ABI zorunluluğu olan grafik bağlamlarında kullanılabilir.


* **Soyut Görünüm Sarmalama (Abstract View Encapsulation):** Zorunlu C API çağrıları, `.sats` dosyasında `absview` ve `absvtype` arkasına gizlenmeli; C dünyasının tüm belirsizlikleri sistem sınırında sıfır maliyetli hayalet tiplerle (ghost types) mühürlenmelidir.



```ats
// OpenGL Context için izole sözleşme (.sats)
absview GL_CONTEXT_ACQUIRED

extern fun gl_init (): [success:bool] (
  option_v(GL_CONTEXT_ACQUIRED, success) | bool(success)
) = "mac#init_gl_context"

```

## 4. Sıfır Bağımlılık ve Algoritmik Atomiklik (SRP & SLAP)

* **Sıfır 3. Parti Kütüphane:** Vektörler, dinamik diziler, matrisler, arabellekler ve kuyruklar gibi tüm veri yapıları, dilin yerel doğrusal tipleri (`dataviewtype`, `vtypedef`) kullanılarak sıfırdan yazılmalıdır.


* **Tek Seviyeli Soyutlama (SLAP) ve İspat Ayrımı:** Yürütülebilir iş mantığı (`fun`, `fn`) ile matematiksel ispat mantığı (`prfn`, `prval`) aynı blokta iç içe geçmemelidir; ispatlar yardımcı lemmalara delege edilmelidir.


* **Maksimum 20 Satır Kuralı:** Fonksiyon gövdeleri 20 satırı aşamaz; karmaşık algoritmalar tek bir mantıksal eylemi yürüten atomik alt birimlere ayrılmalıdır.

---

### 1. CMake & `patscc` Katı Derleme Konfigürasyonu

ATS2 derleyicisi (`patsopt`), kaynak dosyaları doğrudan C99 koduna çeviren bir kaynak-kaynak dönüştürücüdür (`transpiler`). Bu süreci CMake içerisine tam denetimli olarak entegre etmek için `patsopt` ile statik tip denetimini derleme hattının başına koyup, üretilen C kodunu en katı uyarı/hata bayrakları ve dinamik bellek analizörleriyle (`AddressSanitizer`) GCC/Clang'e iletmek gerekir.

```cmake
cmake_minimum_required(VERSION 3.20)
project(ats2_formal_engine C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Ortamdan PATSHOME tespit edilir
if(NOT DEFINED ENV{PATSHOME})
    message(FATAL_ERROR "PATSHOME ortam degiskeni tanimli degil!")
endif()
set(PATSHOME $ENV{PATSHOME})

find_program(PATSOPT patsopt PATHS "${PATSHOME}/bin" REQUIRED)
find_program(PATSCC patscc PATHS "${PATSHOME}/bin" REQUIRED)

# Sifir kacis: C derleyicisinin tum gevsekliklerini kapatan kati bayraklar
set(STRICT_C_FLAGS
    -Wall
    -Wextra
    -Werror
    -pedantic
    -Wshadow
    -Wconversion
    -Wstrict-aliasing=2
    -fsanitize=address,undefined
    -fno-omit-frame-pointer
    -DATS_MEMALLOC_LIBC
)

add_compile_options(${STRICT_C_FLAGS})
add_link_options(-fsanitize=address,undefined)

# SATS (Arayuz/Ispat) ve DATS (Gercekleme) dosyalari
set(ATS_SATS_SRC ${CMAKE_CURRENT_SOURCE_DIR}/src/engine.sats)
set(ATS_DATS_SRC ${CMAKE_CURRENT_SOURCE_DIR}/src/engine.dats)
set(GENERATED_C  ${CMAKE_CURRENT_BINARY_DIR}/engine_dats.c)

# 1. Asama: Tip ve bagimli kisit denetimi (Static Verification Gate)
add_custom_command(
    OUTPUT ${GENERATED_C}
    COMMAND ${PATSOPT} --output ${GENERATED_C} --dynamic ${ATS_DATS_SRC}
    DEPENDS ${ATS_SATS_SRC} ${ATS_DATS_SRC}
    COMMENT "[PATSOPT] Tip denetimi, lineer sahiplik ve teorem dogrulamasi calistiriliyor..."
    VERBATIM
)

# 2. Asama: Uretilen guvenli C kodunun derlenmesi
add_executable(formal_engine ${GENERATED_C})
target_include_directories(formal_engine PRIVATE
    ${PATSHOME}
    ${PATSHOME}/ccomp/runtime
)

```

---

### 2. Bağımsız Katı `Makefile` ve Doğrulama Pipeline'ı

CMake haricinde doğrudan terminalden veya CI/CD boru hatlarında tip denetimini derleme adımından bağımsız koşturmak için `patsopt -tc` (Type-Check Only) kapısı:

```makefile
PATSHOME ?= $(shell echo $$PATSHOME)
PATSOPT  := $(PATSHOME)/bin/patsopt
PATSCC   := $(PATSHOME)/bin/patscc

# Statik dogrulama ve guvenlik bayraklari
ATSFLAGS := -IATS $(PATSHOME) -IATS $(PATSHOME)/ccomp/runtime
CFLAGS   := -Wall -Wextra -Werror -pedantic -Wshadow -fsanitize=address,undefined -DATS_MEMALLOC_LIBC

SRC_SATS := src/engine.sats
SRC_DATS := src/engine.dats
TARGET   := formal_engine

.PHONY: all verify clean

all: verify $(TARGET)

# Kural: Kodu C'ye dökmeden önce saf tip denetimi ile teoremleri sına
verify:
	@echo "==> Statik ispatlar ve terminasyon metrikleri denetleniyor..."
	$(PATSOPT) -tc --static $(SRC_SATS)
	$(PATSOPT) -tc --dynamic $(SRC_DATS)

$(TARGET): $(SRC_SATS) $(SRC_DATS)
	@echo "==> C kodu uretiliyor ve kati denetimlerle baglaniyor..."
	$(PATSCC) $(ATSFLAGS) $(CFLAGS) -o $@ $(SRC_SATS) $(SRC_DATS)

clean:
	rm -f $(TARGET) *_dats.c *_sats.c

```

---

### 3. Statik Kısıt Doğrulama ve Durum Makinesi Şablonu

Bu şablonda durumlar ham string veya tamsayı yerine soyut doğrusal görünümler (`absview`) ve bağımlı indekslerle (`sortdef`) modellenmiştir. Eski durum tüketilmeden yeni duruma geçilemez ve sınır taşması çalışma zamanına bırakılmadan derleme anında kilitlenir.

#### `src/engine.sats` (Sözleşme ve İspat Arayüzü)

```ats
// 1. Statik Durum Belirleyicileri (Zero Stringly-Typed)
stadef UNINIT = 0
stadef READY  = 1
stadef ACTIVE = 2

// 2. Dogrusal Yetenek Kanitlari (Linear Capabilities)
absview STATE(int)
absview BUFFER_PERM(addr, int)

// 3. Durum Gecis Sozlesmeleri: Eski kaniti tuket (consume), yenisini don
fn engine_init (): (STATE(READY) | void)

fn engine_activate (
  pf: STATE(READY)
): (STATE(ACTIVE) | void)

fn engine_deactivate (
  pf: STATE(ACTIVE)
): (STATE(READY) | void)

// 4. Bagimli Tipli Dizi/Buffer Sinir Erisimi (Sinir asimi derleme hatasidir)
fn safe_bounded_read {n:nat} {i:nat | i < n} (
  pf: !STATE(ACTIVE) | arr: &(@[byte][n]), idx: int(i)
): byte

```

#### `src/engine.dats` (Gerçekleme ve Sonlanma Metriği)

```ats
#include "share/atspre_staload.hats"
staload "src/engine.sats"

// Durum olusturma gerceklemeleri
implement engine_init () = let
  extern prfun __prove_ready (): STATE(READY)
  prval pf = __prove_ready ()
in
  (pf | ())
end

implement engine_activate (pf) = let
  prval () = __consume_ready (pf) where {
    extern prfun __consume_ready (pf: STATE(READY)): void
  }
  extern prfun __prove_active (): STATE(ACTIVE)
in
  (__prove_active () | ())
end

implement engine_deactivate (pf) = let
  prval () = __consume_active (pf) where {
    extern prfun __consume_active (pf: STATE(ACTIVE)): void
  }
  extern prfun __prove_ready (): STATE(READY)
in
  (__prove_ready () | ())
end

// Sinir denetimli okuma: if/else yok; tip sistemi dizin kuralini ispatlamistir
implement safe_bounded_read (pf | arr, idx) = arr.[idx]

// Terminasyon Metrikli Ozyineleme: .<n>. metriki dongunun bittigini ispatlar
fun process_stream {n:nat} .<n>. (
  pf: !STATE(ACTIVE) | count: int(n)
): void =
  if count = 0 then ()
  else (
    // Is mantigi...
    process_stream (pf | count - 1)
  )

```

---

### 4. Skill Yönergesine Eklenecek Bölüm (`.cursorrules` / Prompt)

Aşağıdaki bloğu doğrudan mimari skill setinizin sonuna ekleyebilirsiniz:

```markdown
### ATS2 Katı Derleme ve Formel Tip Doğrulama Kuralları
- **Çift Aşamalı Derleme Kapısı (Two-Stage Verification):** Kod üretiminde her zaman önce `patsopt -tc` çalıştırılmalı; bağımlı kısıtlar ve doğrusal sahiplik kanıtları çözülmeden C derleme adımına geçilmemelidir.
- **Sıfır İspat Kaçışı:** Kod tabanında `assume`, `$UNSAFE.cast`, denetlenmeyen `castfn` veya `$extfcall` kesinlikle kullanılamaz. İspat gerektiren her ilişki `prfn` veya `dataprop` ile yapıcı olarak temellendirilmelidir.
- **Doğrusal Yetenek ile Durum Yönetimi (Linear Capabilities):** Tüm durum akışları `absview STATE(n)` doğrusal kanıtlarıyla modellenmelidir. Bir sonraki aşamaya geçilirken önceki aşamanın kanıtı tüketilmeli, izin verilmeyen geçişler derleme zamanında reddedilmelidir.
- **Bağımlı İndeks ve Sınır Koruması:** Bellek tamponları ve diziler `[n:nat]` ve `[i:nat | i < n]` kısıtlarıyla mühürlenmeli; `if (idx < size)` kontrolleri yerine bu ilişkiyi baştan garanti eden incelikli tipler kullanılmalıdır.
- **Terminasyon Metriği Zorunluluğu:** Tüm özyinelemeli `fun` veya `prfun` blokları eksiksiz bir `.<metric>.` sonlanma metriği tanımlamalıdır.
- **Derleyici Bayrakları:** GCC/Clang katmanında `-Wall -Wextra -Werror -pedantic -fsanitize=address,undefined -DATS_MEMALLOC_LIBC` bayrakları varsayılan olarak zorunlu tutulmalıdır.

```
### Sistem Becerisi: `ats2-rigorous-formal-architect`

Bu beceri, ATS2 (Postiats 0.4.2) kod tabanında matematiksel ispat bütünlüğünü, sıfır kaçış garantisini (soundness), mutlak tip güvenliğini ve deterministik kaynak yönetimini zorunlu kılar.

---

### 1. Tabu ve İkame Matrisi (Asla Kullanılmayacaklar vs. Zorunlu Yöntemler)

| Katman | ❌ Asla Kullanılmayacak Yöntem (Tabu) | ✅ Yerine Zorunlu Olan Yöntem (İkame) | Gerekçe / Matematiksel Temel |
| --- | --- | --- | --- |
| **FFI & Tip Dönüşümü** | `$UNSAFE.cast`, denetlenmeyen `castfn` | `prfn`/`prfun` yapıcı lemmalar ve `airlock_*` kapıları | Tip sistemini baypas etmek ispat zincirini kırar; sessiz bellek bozulmalarına yol açar. |
| **Statik Yükseltme** | `g1ofg0` (postiats 0.4.2'de kısıt olarak tip denetiminden geçmez) | `airlock_nat`, `airlock_pos`, `airlock_below`, `airlock_word`, `airlock_span` | Çalışma zamanı korumasıyla mühürlenmiş C FFI fonksiyonları doğrudan bağımlı tip döner. |
| **Dahili Bellek Erişimi** | Ham `ptr` (adres üzerinden doğrudan okuma/yazma) | İndekslenmiş işaretçi `ptr(l)` ve doğrusal görünüm `v @ l` (`array_v`, `bytes_v`) | Lineer mantık (Linear Logic); her bellek erişimi tekil bir yetenek kanıtına (`view`) muhtaçtır. |
| **Opak C Nesneleri** | Sahte `ptr(l)` ve uydurma `view` ispatları | `absviewtype = ptr` artı kontrollü tekil `assume` (7 onaylı tip ile sınırlı) | Dış C kütüphanesinin iç yapısına sahte ispat uydurmak formel semantik açığı oluşturur. |
| **Özyineleme & Döngüler** | Metriksiz `fun`, `while(true)`, denetimsiz döngüler | Kesin sonlanma metriği (`.<n>.`) ve `MAX_REC_FUEL` yakıt kontrolü | Durma Problemi (Halting Problem) ve yığın taşması (stack overflow) matematiksel olarak önlenir. |
| **Dallanma & Akış** | `case-`, `case`, joker karakterli (`_`) genel `if/else` | Statik kısıtlı `case+` (Exhaustive Pattern Matching) | Tüm varyantların tüketilmesi garanti edilir; tanımsız çalışma zamanı durumları derlemede engellenir. |
| **Durum Temsili** | Ham `string`, magic int, serbest durum bayrakları | `sortdef`, `datatype`, `Toggle`, `bool` veya açık durum matrisi | "Stringly-typed" anti-pattern yasağı; imkânsız durumlar tip seviyesinde temsil edilemez kılınır. |
| **Algoritmik Kod** | Satır içi C (`%{# ... %}` gövdesi veya algoritmada `$extfcall`) | Saf ATS2 fonksiyonları (`fun`, `fn`) ve `.sats` üzerinden soyut arayüzler | Algoritmik kod derleyicinin tip denetimine ve ispat motoruna tam tabi olmalıdır. |
| **Hata & İstisna** | Sessiz başarısızlık, boş değer dönme, `bool abort` | Açık durdurma yordamları (`anth_die_*`) veya tip güvenli `option_vt` | Hata durumları deterministik olmalı, tanımsız veri akışına izin verilmemelidir. |

---

### 2. Postiats 0.4.2 Sınır Hava Kilidi (Boundary Airlock) Protokolü

C ABI, işletim sistemi ve dış dünyadan gelen dinamik değerler iç çekirdeğe doğrudan sızamaz. Giriş ve çıkışlar katı bir hava kilidinden geçmelidir:

* **Sınır Fonksiyonları:** Tip yükseltme işlemi `g1ofg0` yerine yalnızca C tarafında sınır denetimi yapan şu fonksiyonlarla yürütülür:
* `airlock_nat`: Dinamik tamsayıyı `[n:nat] int(n)` indeksine yükseltir.
* `airlock_pos`: Dinamik tamsayıyı `[n:pos] int(n)` indeksine yükseltir.
* `airlock_below`: Dinamik tamsayıyı `[n:nat | n < CAP] int(n)` aralığına kilitler.
* `airlock_word` & `airlock_span`: Bellek boyut ve ofsetlerini bağımlı kısıtlara dönüştürür.


* **Hata Toleransı ve Dayanıklılık:** Hava kilidinde aralık dışı bayt okuma `0` döner, geçersiz aralığa yazma işlemi yapılmaz (`no-op`). Hava kilidi sınır dışı okumalarda süreci aniden sonlandırmaz (çalışma zamanı koruması devrede kalır).
* **Sızdırmazlık İlkesi:** Hava kilidi modüllerinin dışındaki hiçbir kaynak kodda `$UNSAFE`, `castfn` veya yeni bir `assume` yer alamaz.

---

### 3. Anthracite Depo Değişmezleri (Binding Invariants)

Bu kurallar, genel şablonla çeliştiği her noktada önceliklidir:

* **Davranış Korunumu:** Selftest karşılaştırmasında `start_ms`, `rss_kb`, `poll_ms` ve `big_load` ortamdan alınır; `live=1530113` değişmez sabittir.
* **Yedi `assume` Sınırı:** Yalnızca aşağıdaki yedi tip için tekil `assume` tanımlanabilir:

$$\text{Buf}, \text{Doc}, \text{Font}, \text{Image}, \text{Rend}, \text{Plat}, \text{App}$$



Her biri `absviewtype = ptr` ve tek bir `assume` ile mühürlenir. Bu tiplerin dışında sekizinci bir `assume` eklenemez.
* **Opak C İşaretçileri:** `Display*`, GLX, `DIR*` ve ham C dizileri opak `ptr` olarak tutulur. `buf_ptr` çağrısı yalnızca hava kilidi gövdelerinde yapılabilir.
* **Derleme Bayrakları:** `-Wall -Wextra -Wshadow -pedantic` bayrakları zorunludur. `-Werror` ve `AddressSanitizer` (ASan) kullanılmaz (ASan, GLX bağlamında sıfır `fbconfig` dönmesine yol açar).
* **Rol ve İki-Durum Modeli:** Mantıksal roller ve ikili durumlar `datatype`, `Toggle` veya `bool` ile modellenir. Tamsayı kodu yalnızca `*_code` ve `*_of` dönüştürücülerindedir.
* **Sahte Datatype Yasağı:** Uzunluk, piksel, JSON tamsayısı, bayt değeri, `CHAR_*`, `NF_*` ofseti, oturum JSON alanları, X tuş kodu ve OpenGL sabitleri sahte `datatype` yapılmaz. Ağaç meta sözcüğü ve C çıkış parametresi `int` kalır; dönüşüm hava kilidi sınırında yapılır.
* **Yakıt Tavanı (Fuel Exhaustion):**

$$\text{MAX\_REC\_FUEL} = 268435456 \quad (2^{28})$$



Yakıt tükendiğinde süreç `event=recursion_fuel` ile durdurulur; sahte varsayılan değer dönülemez. Dizin tarama tavanı `MAX_DIR_ENTRIES = 65536` olarak kilitlidir.
* **Deterministik Sonlandırma (Abort):** Hata durumunda çıkışlar `anth_die_void`, `anth_die_int`, `anth_die_dbl`, `anth_die_box` ile yapılır. `bool abort` yasaktır. İç tarayıcılar `int` kalır; dış yüklemler bunları `bool` olarak sarar.
* **Libc ve Selftest İzolasyonu:** Selftest skorları (0/1) ve `fs_exists`, `fs_mkdir`, `fs_write` libc durum dönüşleri çıplak `int` olarak korunur.

---

### 4. Yazılım Mimarisi ve Kod Organizasyonu

* **Fonksiyon Atomikliği (SRP):** Her fonksiyon tek bir mantıksal işten sorumludur. İş mantığı, ispat inşası ve G/Ç (I/O) orkestrasyonu aynı fonksiyonda birleştirilemez.
* **Satır Limiti:** Fonksiyon gövdeleri 20 satırı geçemez. 20 satırı aşan bloklar mantıksal alt fonksiyonlara parçalanmalıdır.
* **Tek Düzeyli Soyutlama Prensibi (SLAP):** Yüksek seviyeli bir yönlendirici fonksiyon doğrudan bit kaydırma, ofset aritmetiği veya düşük seviyeli tampon indeksleme yapamaz; bu işlemler alt yordamlara devredilmelidir.
* **İspat ve Yürütme Ayrımı:** Formel doğrulamayı sağlayan lemma ve teoremler (`prfn`, `prfun`, `dataprop`) iş mantığı gövdelerine gömülmez; ayrı lemma fonksiyonları olarak tanımlanıp çağrılır.

---

### 5. Kod Dönüşüm Şablonu

#### Hatalı Tasarım (Güvensiz, İspatsız, Kurallara Aykırı)

```ats
// KABUL EDİLEMEZ: İspatsız cast, ham ptr manipülasyonu, metriksiz özyineleme
extern castfn unsafe_to_nat (x: int): [n:nat] int(n)

fun process_data (p: ptr, len: int): int =
  if len <= 0 then 0
  else let
    val n = unsafe_to_nat (len)
    // Ham bellek okuması, view kanıtı yok!
    val b = $UNSAFE.cast{int}(p)
  in
    b + process_data (p, len - 1) // Metriksiz recursion
  end

```

#### Mimari Standartlara Uygun Tasarım (Postiats 0.4.2 & Hava Kilidi Uyumlu)

```ats
staload "src/airlock.sats"

// 1. Durum ve Hata Sözleşmeleri
datatype EngineState = StateIdle | StateActive

// 2. Metrikli ve İspat Korumalı İş Mantığı (20 satır altı, SLAP uyumlu)
fun sum_bytes_verified {n:nat} .<n>. (
  pf: !bytes_v(l, n) | p: ptr(l), fuel: int, n: int(n), acc: int
): int =
  if fuel <= 0 then
    anth_die_int () // Yakıt bitti, sahte değer dönmeden durdur
  else if n = 0 then
    acc
  else let
    prval (pf1, pf_rest) = bytes_v_uncons (pf)
    val byte_val = airlock_read_byte (pf1 | p)
    prval () = pf := bytes_v_cons (pf1, pf_rest)
    val next_p = ptr_add<byte> (p, 1)
  in
    sum_bytes_verified (pf | next_p, fuel - 1, n - 1, acc + byte_val)
  end

// 3. Hava Kilidi Giriş Orkestrasyonu
fn ingest_external_buffer (raw_len: int, raw_p: ptr): int = let
  // Sınır koruması C kapısından geçer; g1ofg0 kullanılmaz
  val guarded_len = airlock_below (raw_len, MAX_DIR_ENTRIES)
in
  if guarded_len < 0 then 0
  else let
    // Tampon görünümü ve doğrusal yetenek sınırda elde edilir
    val (pf_buf | p) = airlock_acquire_buffer (raw_p, guarded_len)
    val result = sum_bytes_verified (pf_buf | p, MAX_REC_FUEL, guarded_len, 0)
    prval () = airlock_release_buffer (pf_buf)
  in
    result
  end
end

```