#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_glyphs.sats"
staload "data_font/ot_layout_work.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_context_pattern.sats"
staload "data_font/ot_layout_types.sats"
fun position_valid{kind:int}(domain: OtLayoutDomain(kind),position: int,count: int): bool = case+ domain of
  | OtSubstitution() => true (* Multiple may grow the matched input before this action. *)
  | OtPositioning() => ilt(position,count)
fun actions {n:nat}{kind:int} .<n>. (n: int(n),b: !Buf,p: OtContextPattern,lookups: int,
  domain: OtLayoutDomain(kind),i: int): bool =
  if n = 0 then true else let val at=iadd(p.actionsAt,imul(i,4)) in
    if not(position_valid(domain,ot_u16(b,p.span,at),p.inputCount)) orelse ige(ot_u16(b,p.span,iadd(at,2)),lookups) then false
    else actions(n-1,b,p,lookups,domain,iadd(i,1)) end
fun atoms(b: !Buf,p: OtContextPattern,glyphs: int,encoding: OtContextEncoding): bool = case+ encoding of
  | ContextClasses() => true | ContextCoverages() => true
  | ContextGlyphs() => ot_glyph_array_valid(b,p.span,p.backAt,p.backCount,glyphs) andalso
    ot_glyph_array_valid(b,p.span,p.inputAt,isub(p.inputCount,1),glyphs) andalso
    ot_glyph_array_valid(b,p.span,p.lookAt,p.lookCount,glyphs)
implement ot_context_rule_validate(b,p,encoding,glyphs,lookups,domain,remaining) = let
  val cost=iadd(iadd(iadd(p.backCount,p.inputCount),p.lookCount),p.actionCount)
in if not(ot_layout_charge(remaining,cost)) then Some_vt(ot_error(OtCapacity(),p.span))
  else if not(atoms(b,p,glyphs,encoding)) then Some_vt(ot_error(OtGlyphDomain(),p.span))
  else if not(actions(airlock_nat(p.actionCount),b,p,lookups,domain,0)) then Some_vt(ot_error(OtReference(),p.span))
  else None_vt() end
