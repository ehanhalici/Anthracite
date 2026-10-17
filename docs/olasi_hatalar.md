# Açık hatalar ve sonraki işler

Bu listede yalnız açık sorunlar tutulur. Çözülen maddeler listeden çıkarılır;
kanıtları, düzeltmeleri ve test kayıtları Git geçmişinden erişilebilir.
Son kullanılan kimlik BUG-036'dır; yeni bulgular BUG-037'den devam eder.
Listeden çıkarılmış numaralar yeniden kullanılmaz.

## BUG-036 — Editör durum makinesinde GC'siz kutu sızıntısı

- Durumu: açık
- Yeniden üretme: sanitizer derlemesinde geçerli X11/GLX ekranıyla
  `ASAN_OPTIONS=detect_leaks=1 ctest --test-dir build/refactor-asan -R '^graphics_selftest$' -V`.
- Kanıt: işlevsel selftest bayrakları başarılı olsa da LeakSanitizer 4 tahsiste
  56 bayt sızıntı buluyor. `addr2line -afi` çerçeveleri `editor_fsm_selftest`,
  `step_idle` ve `step_typing` içindeki payload taşıyan `EditorState` ve
  `EditorAction` kurucularına karşılık geliyor.
- `mem_live` dengesi bu ATS kutularını ölçmüyor. GC/suppression eklemek yerine
  durum ve eylemlerin sahipliği veya düz değer temsili düzeltilmeli; 66 geçişlik
  mevcut matrisin davranışı korunmalı.
