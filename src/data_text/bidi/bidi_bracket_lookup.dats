#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_bracket_data.sats"

extern fun bracket_invalid(): BracketKind = "mac#anth_die_box"
extern fun bracket_exhausted(): int = "mac#anth_die_int"

implement bidi_bracket_kind_of(code) = case+ code of
  | 0 => NoBracket() | 1 => OpenBracket() | 2 => CloseBracket() | _ => bracket_invalid()
implement bidi_bracket_kind_code(kind) = case+ kind of
  | NoBracket() => 0 | OpenBracket() => 1 | CloseBracket() => 2
implement bidi_bracket_is_open(kind) = case+ kind of
  | NoBracket() => false | OpenBracket() => true | CloseBracket() => false
implement bidi_bracket_is_close(kind) = case+ kind of
  | NoBracket() => false | OpenBracket() => false | CloseBracket() => true
implement bidi_bracket_canonical(cp) = if ieq(cp,9002) then 12297 else cp

fun find {n:nat} .<n>. (n: int(n), rows: !Buf, cp: int, low: int, high: int): int =
  if ige(low,high) then ~1 else if n = 0 then bracket_exhausted() else let
    val mid = iadd(low,idiv(isub(high,low),2))
    val value = buf_get32(rows,imul(mid,3))
  in if ilt(cp,value) then find(n-1,rows,cp,low,mid)
    else if igt(cp,value) then find(n-1,rows,cp,iadd(mid,1),high) else mid end

implement bidi_bracket_index(data,cp) = let val+ BidiBrackets(rows,count)=data
in find(airlock_nat(iadd(count,1)),rows,cp,0,count) end
implement bidi_bracket_info(data,cp) = let
  val+ BidiBrackets(rows,count) = data
  val index = find(airlock_nat(iadd(count,1)),rows,cp,0,count)
in if ilt(index,0) then @{kind=NoBracket(),paired=cp} else let
    val at = imul(index,3)
    val kind = bidi_bracket_kind_of(buf_get32(rows,iadd(at,2)))
  in @{kind=kind,paired=buf_get32(rows,iadd(at,1))} end end

implement bidi_brackets_dispose(data) = let val+ ~BidiBrackets(rows,count) = data in buf_free(rows) end
