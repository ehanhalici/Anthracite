# Yerel Metin ve Tipografi Motoru: Uygulama Durumu ve Mimari Rapor

**Son Güncelleme:** 2026-10-15  
**Durum:** Üretim Seviyesinde Aktif (Production-Ready)  
**İlgili Modüler Yetenek Rehberleri:**
* [Metin ve Unicode 18 Motoru](file:///home/emrehan/kod/kod/anthracite/docs/metin_ve_unicode_motoru.md)
* [Yazı Tipi ve OpenType Harf Biçimlendirme Motoru](file:///home/emrehan/kod/kod/anthracite/docs/yazi_tipi_glif_motoru.md)
* [OpenGL Çekirdek Çizim Motoru](file:///home/emrehan/kod/kod/anthracite/docs/cizim_motoru.md)

---

## 1. Genel Durum Özeti

Anthracite editöründe normal çalışma alanı başlangıcında yerel (native) metin ve tipografi motoru varsayılan olarak devrededir. Başlangıç günlüklerinde `engine=native ... status=ready` ve `workspace_frame status=presented` çıktıları ilk çerçevenin başarıyla ekrana basıldığını doğrular.

Harici hiçbir üçüncü taraf metin kütüphanesine (HarfBuzz, FreeType, Pango, ICU, FriBidi vb.) bağımlılık olmaksızın; UTF-8 çözümleme, Unicode 18 özellikleri, UAX #29 grafem/kelime sınırları, UAX #14 satır kesme, dört normalizasyon formu (NFC/NFD/NFKC/NFKD), UAX #9 çift yönlü metin (BiDi) ve OpenType (GSUB/GPOS) harf biçimlendirme saf ATS2 (Postiats 0.4.2) ile gerçekleştirilmiştir.

---

## 2. Tamamlanan ve Doğrulanan Bileşenler

### A. Metin ve Unicode Hattı (`src/data_text/`)
1. **`data_text/utf8`:**
   - Katı Unicode skalar kod çözümü, geçersiz baytlarda W3C/Unicode standardına uygun *Maximal Subpart Replacement* ($U+FFFD$).
   - Orijinal bayt aralığı haritasının korunması ve çözümlenen dizilerin doğrusal (`linear ownership`) sahipliği.
   - Beş bağımsız derlenen alt modüle bölünmüştür (her biri $\le 45$ satır).
2. **`data_text/unicode_db`:**
   - Resmi Unicode 18 verilerinden derlenmiş, sürüm denetimli özellik veritabanı.
   - Ne Python ne de işletim sisteminin Unicode sürümüne bağımlıdır; doğrudan ATS2 içinde derlenmiştir.
3. **`data_text/grapheme`:**
   - Unicode 18 Genişletilmiş Grafem Kümeleri (Extended Grapheme Clusters), güncel `GB9c` kuralı dahil.
   - 853 resmi `GraphemeBreakTest` test durumunun tamamı geçer.
4. **`data_text/word_*`:**
   - Unicode 18 kelime sınırları motoru.
   - 1.944 resmi `WordBreakTest` test durumunun tamamı geçer; birleştirme kuralları ve durum geçişleri bağımsız modüllerdedir.
5. **`data_text/line_*`:**
   - Unicode 18 varsayılan satır kesme algoritması (UAX #14, Revizyon 57).
   - Sayısal diziler, bağlamsal tırnaklar, Brahmic heceleri, bölgesel göstergeler (RI).
   - 19.346 resmi `LineBreakTest` test durumunun tamamı dengeli tampon sahipliğiyle geçer.
   - 25 bağımsız derlenen modüle ayrılmıştır (her biri $\le 128$ satır).
6. **`data_text/normalization_*`:**
   - Dört normalizasyon formu (NFC, NFD, NFKC, NFKD).
   - Algoritmik Hangul birleştirme/ayırma, kanonik sıralama ve tam kompozisyon dışlama kuralları.
   - 20.171 resmi durum ve 403.420 bağıntı kontrolünün tamamı sıfır hatayla geçer. Kalan 1.094.910 Unicode skaları da kimlik kontrollerini geçer.
7. **`data_text/bidi_*`:**
   - Yerel Unicode 18 çift yönlü metin motoru (UAX #9).
   - P1–I2 paragraf çözümleme, L1/L2 satır seviyesi görsel sıralama, eşleşen parantezler (BD16/N0) ve L4 ayna karakter eşleme.
   - 91.707 `BidiCharacterTest` ve 770.241 `BidiTest` yön kombinasyonunun tamamı dengeli tampon sahipliğiyle geçer.

---

### B. Yazı Tipi ve Glif Hattı (`src/data_font/`)
1. **`data_font/sfnt`:**
   - Doğrudan CPU üzerinde çalışan statik TrueType / OpenType tablo okuyucu.
   - Tablo dizini, çakışma kontrolleri, metrik tabloları, `loca` ve Unicode `cmap` (Format 4 ve 12) glif ID eşlemeleri.
2. **`data_font/glyph_component`:**
   - Bileşik glif (compound glyph) kayıtları, işaretli XY ofsetleri, afin matris kompozisyonu.
3. **`data_font/opentype_*`:**
   - Coverage Format 1/2, ClassDef Format 1/2 ve Device Format 1/2/3 ayrıştırması.
   - Glif sayısı unsigned 16-bit `maxp.numGlyphs` sınırına (1–65.535 glif) tam uyumludur.
4. **`data_font/gdef_*`:**
   - GDEF 1.0/1.2/1.3 başlıkları, glif sınıfları, hareke bağlama sınıfları ve mark-glyph-set tabloları.
5. **`data_font/gsub_*`:**
   - OpenType Layout GSUB ikameleri: Single, Sequence, Ligature, Reverse Chaining Contextual.
   - Kodlama ligatürleri (`=>`, `!=`, `===`, `->`, `fi`, `fl` vb.) tam desteklenir.
6. **`data_font/gpos_*`:**
   - OpenType Layout GPOS konumlandırmaları: Single adjustment, Pair kerning, Cursive attachment, Mark-to-Base, Mark-to-Ligature ve Mark-to-Mark.
7. **`data_font/arabic_join` & `arabic_marks`:**
   - Arap alfabesi harf birleştirme FSM'si (İzole, Başlangıç, Orta, Bitiş formları) ve hareke yerleşimi.

---

## 3. Çalışma Zamanı Mimarisi ve Ekran Entegrasyonu

* **Piksel Sarmalı Satırlar (Pixel-Wrapped Rows):** Sıradan metin satırları çizim (`core_render`), yükseklik (`doc_layout`), fare seçimi, imleç hit-testi ve dikey navigasyon arasında ortak projektif koordinatları paylaşır.
* **Görsel Satır Adımı (`step`):** Katlama motoru (`fold_region`) tarafından gizlenen satırlar yerleşim motorunda `step=0` alır; görünür satırlar glif avans değerlerine göre milimetrik yerleşir.
* **Performans:** Glif atlası dokusu üzerinden GPU'ya tek geçişte kuad gönderimi yapılarak yüksek kare hızları (60+ FPS) ve düşük bellek tüketimi korunur.

---

## 4. Test ve Kalite Güvencesi

Tüm motor bileşenleri `./build/anthracite --selftest` ve `ctest` süiti üzerinden test edilmektedir:
* `bidi_character_conformance` (91.707 test)
* `bidi_class_conformance`
* `bidi_document_conformance`
* `line_conformance` (19.346 test)
* `line_contracts`
* `arabic_marks_conformance`
* `gsub_single_conformance`, `gsub_ligature_conformance`, `gpos_pair_conformance`
* Toplam **77 CTest testinin tamamı (%100)** yeşil geçer.
* Sıkı bellek değişmezi **`live=1530113`** baytına kadar doğrulanmıştır.
