# Büyük belge ve gömülü referans performansı

Başlangıç: `8ca4286`, 2026-10-17. Kişisel dosyalar salt okunur ölçülür;
içerikleri ve mutlak yolları regresyon fixture'larına eklenmez.

## Başlangıç bulguları

- Gömülü belge örneği: 5.372 bayt, 37 blok referansı, 31 farklı hedef dosya.
  Yedi referans aynı dosyanın farklı bloklarını gösterir; tüm hedefler mevcuttur.
- Uzun belge örneği: 129.924 bayt, 807 mantıksal satır, 3.411 AST düğümü.
- Kaynak kanıtları BUG-017–023 altında kayıtlıdır. Başsız fold-dump ölçümü
  native font, sarma, gömülü dosyalar ve GPU çizimi için ölçüm değildir.

## Ölçüm yöntemi

`document_performance VAULT FILE [read|edit]` üretim Doc/Font/Rend hattını
1280×800 ve 18 px koşullarında çalıştırır; dosya yükleme ve ilk/sıcak kareleri
ayrı raporlar. GL tamamlanması da kare süresine dahildir. Özel oturum açmaz,
notları kaydetmez; işletim sistemi dosya önbelleği zorla temizlenmez.

Sayaçlar yalnız bu yürütücüde etkinleştirilir; C sınırı yalnız tahsissiz,
tek iş parçacıklı telemetri tamsayılarını tutar, algoritma/sahiplik içermez.
Bu sayaçlar aşama atfı içindir; keyfî girdiler için doğruluk ispatı değildir.

Hedefler: kullanılabilir ilk görünüm medyanı ≤500 ms; sıcak kaydırma/çizim
p95 ≤16,7 ms. Grafik ortamı ve fontlar ölçümle birlikte belirtilmelidir.

## Değişiklik öncesi grafik ölçümü

Release, Xvfb :93, 1280×800, 18 px; iki dosya ayrı süreçlerde sırayla
çalıştırıldı. Yeni süreç soğuk uygulama cache'idir, OS cache temizlenmedi.

| Örnek | Doc yükleme | İlk kare | Sıcak 1 / 2 | İlk kare shaping |
|---|---:|---:|---:|---:|
| Gömülü referanslı | 0,207 ms | 2.859 ms | 6,40 / 2,81 ms | 23.036 çağrı |
| Uzun metin | 2,98 ms | 9.639 ms | 1,26 / 1,02 ms | 88.269 çağrı |

Gömülü örneğin ilk karesi 38 çocuk belge yüklemesi, 39 sarma ve 39 görsel
indeks hazırlığı yaptı. Uzun metinde şekillendirilen toplam bayt 4.221.439'dur.
Bu tek koşunun başlangıç ölçümüdür; medyan/p95 veya gerçek GPU garantisi değildir.

## Katlama hazırlığı

Yeniden ayrıştırmada hazırlık bir kez yapılır. Bölge sahipleri tek monoton
düğüm imleciyle eşlenir; `fold_scaling_contracts` 32/256/2048 başlıkta ziyaret
sayısının düğüm + bölge sayısını aşmadığını ve sahip bayraklarını doğrular.

## Sarma: paragraf küme genişlikleri

Her paragraf bir kez analiz/shape edilir; mantıksal kaynak sırasındaki küme
advance'ları byte-indeksli prefix tablosuna aktarılır. Bidi görsel caret x'i
prefix olarak kullanılmaz. Ligatür içi kırılma engellenir; seçilen gerçek satır
yeniden şekillendirilir ve kenar birleşmesi genişliği artırırsa daraltılır.
U+2029 gibi bir fiziksel satırdaki çoklu paragraflar zorunlu sınırlarda ayrılır.

Ara ölçüm (aynı Release/Xvfb koşulları, tek koşu): gömülü örnek 263 ms /
777 shaping çağrısı; uzun örnek 534 ms / 2.415 çağrı. Başlangıca göre yaklaşık
11× / 18× daha hızlıdır. Henüz son medyan/p95 kabul ölçümü değildir.
64/256/1024 tekrar içeren karışık Türkçe/Arapça test, şekillendirmeyi satır
sayısına göre sınırlar; önceki her grapheme için yeniden ölçme yolunu reddeder.

Görünür satırın şekillendirilmiş planı Font ölçüm cache'inden VisualRows
sahipliğine aktarılır; bir miss'te bir kez üretilir. 128 yuvalı indeksli cache
satır boyama, yön, hit/caret ve seçim arasında paylaşılır. Çakışan yuva,
geçersiz font token'ı ve görünüm kapanışı eski planı serbest bırakır. Genel
font cache'i tahliye edilse de görünüm planı geçerliliğini korur; testte yeni
shaping sayısı sıfırdır. Offscreen satır planları yalnız ihtiyaçta oluşturulur.

Benchmark artık ilk kare ve iki sıcak sabit kare sonrasında 60 kaydırma
karesi ölçer: belge boyunca eşit aralıklı 30 konum, iki geçiş. Bu gerçek içerik
çizimidir; yalnız yer tutucu/boş kare ölçümü değildir. `tools/performance/summarize.py`
loglardan medyan ve nearest-rank p95 çıkarır. İlk görünüm medyanı için birden
çok ayrı süreç logu verilmelidir. Dosya yüklenemezse benchmark başarısız döner.
