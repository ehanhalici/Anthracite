#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_mirror.sats"
extern fun mirror_exhausted(): int = "mac#anth_die_int"

fun search {n:nat} .<n>. (n: int(n), rows: !Buf, cp: int, low: int, high: int): int =
  if ige(low,high) then cp else if n = 0 then mirror_exhausted() else let
    val mid = iadd(low,idiv(isub(high,low),2))
    val at = imul(mid,2)
    val value = buf_get32(rows,at)
  in if ilt(cp,value) then search(n-1,rows,cp,low,mid)
    else if igt(cp,value) then search(n-1,rows,cp,iadd(mid,1),high)
    else buf_get32(rows,iadd(at,1)) end

implement bidi_mirror_codepoint(data,cp,level) =
  if ieq(imod(level,2),0) then cp else let
    val+ BidiMirrors(rows,count) = data
  in search(airlock_nat(iadd(count,1)),rows,cp,0,count) end

implement bidi_mirrors_dispose(data) = let val+ ~BidiMirrors(rows,count) = data in buf_free(rows) end
