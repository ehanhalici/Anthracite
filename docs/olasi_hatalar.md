# Açık hatalar ve sonraki işler

Bu listede yalnız açık sorunlar tutulur. Çözülen maddeler listeden çıkarılır;
kanıtları, düzeltmeleri ve test kayıtları Git geçmişinden erişilebilir.
Yeni bulgular mevcut en yüksek BUG numarasından devam eder; numaralar yeniden kullanılmaz.

## BUG-034 — Arama bolumu duzgun calismiyor
- Durumu: acik
- Kasa/belge de ara bolumu birbiri icine girmis, buton mantigi buraya da gelmeli
- arama yerine bir kelime yazilinca birbirine girmis sonuclar cikiyor, ! ile gosterilen alt agac mantigi buraya da gelmeli
- bulunan bir veriye tikladigimda duz o sayfa aciliyor, ama internal link gibi o sayfa acilmali, o aranan kelimenin oldugu yere kaymali ve 1 sn boyunca mor ile vurgulanmali
- bulunan sonuclar, kelime eslemesi olarak bulunmuyor, burda ast kullaniliyor olabilir ama rg tarzi paralel cpu kullanan ve belgede/kasada arama yapan bir yapiya gecilebilri, regex destegine gerek yok, sadece birebir metin eslemesine baksa yeterli. buyuk/kucuk harfe duyarsiz olmali
