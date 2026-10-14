#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_property.sats"
staload "data_text/bidi_types.sats"

fun fill {n:nat} .<n>. (
  n: int(n), map: !PropertyMap(2), text: !ScalarText, original: !Buf,
  current: !Buf, matching: !Buf, i: int, start: int
): void =
  if n = 0 then () else let
    val kind = property_value(map,scalar_value(text,iadd(start,i)))
    val () = buf_set(original,i,kind)
    val () = buf_set(current,i,kind)
    val () = buf_set32(matching,i,~1)
  in fill(n-1,map,text,original,current,matching,iadd(i,1),start) end

extern fun bidi_invalid_range(): BidiWork = "mac#anth_die_box"

implement bidi_make(map,text) = bidi_make_range(map,text,0,scalar_count(text))

implement bidi_make_range(map,text,start,finish) =
  if ilt(start,0) orelse ilt(finish,start) orelse igt(finish,scalar_count(text)) then bidi_invalid_range()
  else let
  val n = isub(finish,start)
  val original = buf_make(n)
  val current = buf_make(n)
  val levels = buf_make(n)
  val matching = buf_make(imul(n,4))
  val () = fill(airlock_nat(n),map,text,original,current,matching,0,start)
in BidiWork(original,current,levels,matching,n,start) end

implement bidi_count(work) = let val+ BidiWork(original,current,levels,matching,n,start) = work in n end
implement bidi_original(work,i) = let val+ BidiWork(original,current,levels,matching,n,start) = work in
  bidi_class_of(buf_get(original,i)) end
implement bidi_current(work,i) = let val+ BidiWork(original,current,levels,matching,n,start) = work in
  bidi_class_of(buf_get(current,i)) end
implement bidi_set_class(work,i,kind) = let val+ BidiWork(original,current,levels,matching,n,start) = work in
  buf_set(current,i,bidi_class_code(kind)) end
implement bidi_level(work,i) = let val+ BidiWork(original,current,levels,matching,n,start) = work in buf_get(levels,i) end
implement bidi_set_level(work,i,level) = let val+ BidiWork(original,current,levels,matching,n,start) = work in
  buf_set(levels,i,level) end
implement bidi_match(work,i) = let val+ BidiWork(original,current,levels,matching,n,start) = work in
  buf_get32(matching,i) end
implement bidi_set_match(work,left,right) = let val+ BidiWork(original,current,levels,matching,n,start) = work in
  buf_set32(matching,left,right); buf_set32(matching,right,left) end

implement bidi_dispose(work) = let
  val+ ~BidiWork(original,current,levels,matching,n,start) = work
  val () = buf_free(original)
  val () = buf_free(current)
  val () = buf_free(levels)
in buf_free(matching) end

implement bidi_source_index(work,i) = let val+ BidiWork(original,current,levels,matching,n,start) = work in iadd(start,i) end
