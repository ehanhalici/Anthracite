#include "data_font/font_native_slot_internal.hats"
extern fun generation_exhausted(): int = "mac#anth_die_int"
implement font_native_generation_next(value) = if ige(value,2147483647) then generation_exhausted() else iadd(value,1)
implement font_native_cache_release(slot) = case+ slot of
  | ~None_vt() => () | ~Some_vt(cache) => native_shape_cache_dispose(cache)
implement font_native_cache_reset(slot) = let val old=slot val ()=slot := None_vt()
in font_native_cache_release(old) end
