#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_single_work.sats"
(* int16 delta arithmetic is modulo 65536, not a clamped/signed glyph ID. *)
implement gsub_delta_add(glyph,delta) = imod(iadd(glyph,iadd(delta,65536)),65536)
fun list {n:nat} .<n>. (n: int(n),b: !Buf,c: OtCoverageInfo,delta: int,glyphs: int,i: int): bool =
  if n = 0 then true else let
    val glyph=ot_u16(b,c.span,iadd(4,imul(i,2)))
  in if ige(gsub_delta_add(glyph,delta),glyphs) then false
    else list(n-1,b,c,delta,glyphs,iadd(i,1)) end
fun ranges {n:nat} .<n>. (n: int(n),b: !Buf,c: OtCoverageInfo,delta: int,glyphs: int,i: int): bool =
  if n = 0 then true else let
    val row=ot_range(b,c.span,i)
    val first=gsub_delta_add(row.first,delta)
    val count=iadd(isub(row.last,row.first),1)
  in if ige(first,glyphs) orelse igt(count,isub(glyphs,first)) then false
    else ranges(n-1,b,c,delta,glyphs,iadd(i,1)) end
(* A wrapped covered range necessarily contains glyph 65535, which cannot
   exist when maxp.numGlyphs itself is uint16. Lists may jump past that hole. *)
implement gsub_delta_valid(b,c,delta,glyphs) = case+ c.encoding of
  | OtList() => list(airlock_nat(c.count),b,c,delta,glyphs,0)
  | OtRanges() => ranges(airlock_nat(c.count),b,c,delta,glyphs,0)
