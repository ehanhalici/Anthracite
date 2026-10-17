# Açık hatalar ve sonraki işler

Bu listede yalnız açık sorunlar tutulur. Çözülen maddeler listeden çıkarılır;
kanıtları, düzeltmeleri ve test kayıtları Git geçmişinden erişilebilir.
Yeni bulgular mevcut en yüksek BUG numarasından devam eder; numaralar yeniden kullanılmaz.

## BUG-035 — Acilamayan dosya var
- Numaralandırma: kullanıcı tarafından BUG-033 olarak eklenen bu kayıt,
  aynı numaradaki eski çözülmüş sorunla çakışmaması için BUG-035'e taşındı.
- Durum: acik
- /home/emrehan/notes/obsidian_notlar/kod/araçlar/obsidian.md acilmiyor, daha dogrusu uygulama kilitleniyor
- ayrica bunun icindeki mathx bolumu de duzgun basilamiyor, karakter kodlamasinda sorun var
- Yeniden üretme: salt okunur belge benchmark'ı matematik blokları görünür
  olduğunda ilerlemiyor. Debugger'da 500 hazırlık çağrısından sonra aynı
  `prepare_document_layout → prepare_visible` yolu gözlendi.
- Kök neden: medya bağlama matematik yüksekliğini `lineHeight + 12` yaparken
  layout damgalama bunu her seferinde 24'e geri yazıyor. Görünür hazırlığın
  sürüm sabitleme döngüsü bu yüzden bitmiyor.
- UTF8 bulgusu: üst/alt indis dönüştürücüleri desteklenmeyen karakterlerin
  her baytına `^`/`_` ekliyor; çok baytlı karakterlerin continuation baytları
  ayrılıp geçersiz UTF8 çıkıyor. Sentetik matematik fixture'ıyla sınanacak.

## BUG-034 — Arama bolumu duzgun calismiyor
- Durumu: acik
- Kasa/belge de ara bolumu birbiri icine girmis, buton mantigi buraya da gelmeli
- arama yerine bir kelime yazilinca birbirine girmis sonuclar cikiyor, ! ile gosterilen alt agac mantigi buraya da gelmeli
- bulunan bir veriye tikladigimda duz o sayfa aciliyor, ama internal link gibi o sayfa acilmali, o aranan kelimenin oldugu yere kaymali ve 1 sn boyunca mor ile vurgulanmali
- bulunan sonuclar, kelime eslemesi olarak bulunmuyor, burda ast kullaniliyor olabilir ama rg tarzi paralel cpu kullanan ve belgede/kasada arama yapan bir yapiya gecilebilri, regex destegine gerek yok, sadece birebir metin eslemesine baksa yeterli. buyuk/kucuk harfe duyarsiz olmali
