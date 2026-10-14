#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/opentype_classdef.sats"
staload "data_font/ot_context_match_work.sats"
fun value(b: !Buf,glyph: int,c: OtClassInfo,atom: OtContextAtom): int = case+ atom of
  | LiteralGlyph() => glyph | LiteralClass() => ot_classdef_value(b,c,glyph)
fun forward {n:nat} .<n>. (n: int(n),b: !Buf,p: OtContextPattern,at: int,input: !Buf,
  start: int,c: OtClassInfo,atom: OtContextAtom,i: int): bool =
  if n = 0 then true else let
    val expected=ot_u16(b,p.span,iadd(at,imul(i,2)))
    val actual=value(b,buf_get32(input,iadd(start,i)),c,atom)
  in if ine(expected,actual) then false else forward(n-1,b,p,at,input,start,c,atom,iadd(i,1)) end
fun backtrack {n:nat} .<n>. (n: int(n),b: !Buf,p: OtContextPattern,input: !Buf,
  start: int,c: OtClassInfo,atom: OtContextAtom,i: int): bool =
  if n = 0 then true else let
    val expected=ot_u16(b,p.span,iadd(p.backAt,imul(i,2)))
    val actual=value(b,buf_get32(input,isub(isub(start,1),i)),c,atom)
  in if ine(expected,actual) then false else backtrack(n-1,b,p,input,start,c,atom,iadd(i,1)) end
implement ot_context_atoms_match(b,info,p,input,start,atom) =
  backtrack(airlock_nat(p.backCount),b,p,input,start,info.backClass,atom,0) andalso
  forward(airlock_nat(isub(p.inputCount,1)),b,p,p.inputAt,input,iadd(start,1),info.inputClass,atom,0) andalso
  forward(airlock_nat(p.lookCount),b,p,p.lookAt,input,iadd(start,p.inputCount),info.lookClass,atom,0)
