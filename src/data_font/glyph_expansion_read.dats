#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/ot_sequence_lookup_types.sats"
staload "data_font/ot_sequence_lookup.sats"
staload "data_font/glyph_pass_sequence_work.sats"
staload "data_font/glyph_expansion_types.sats"
staload "data_font/glyph_expansion_work.sats"
extern fun expansion_invariant(): GlyphExpansionRead = "mac#anth_die_box"
fun association(core: GlyphCore): bool = case+ core.association of
  | Unassociated() => true | LigatureOwner() => false | LigatureMark() => false | LigatureForward() => false
fun check(meta: GlyphRunMeta,core: GlyphCore,v: GsubSequenceView,added: int): GlyphPassStatus =
  if not(v.matched) then GlyphPassApplied()
  else if igt(v.count,1) andalso not(association(core)) then GlyphPassReference()
  else if not(glyph_storage_capacity(iadd(meta.used,iadd(added,isub(v.count,1))))) then GlyphPassCapacity()
  else GlyphPassApplied()
fun chosen(b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata,h: OtLookupInfo(1),
  selection: GlyphSelection,core: GlyphCore): GsubSequenceView =
  if glyph_pass_sequence_eligible(b,m,h,selection,core) then ot_multiple_lookup_query(b,t,core.glyph)
  else @{matched=false,span= @{offset=0,length=0},count=0}
fun rejected{n,i:nat}(plan: GlyphExpansionPlan(n,i),status: GlyphPassStatus): GlyphExpansionRead = let
  val ()=glyph_expansion_dispose(plan)
in ExpansionRejected(status) end
fun read{n,i,c:nat | i <= c} .<c-i>. (b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,h: OtLookupInfo(1),selection: GlyphSelection,plan: GlyphExpansionPlan(c,i),node: int): GlyphExpansionRead = let
  val+ GlyphExpansionPlan(rows,count,filled,added,matches)=plan
in if filled = count then (if ieq(node,~1) then ExpansionAccepted(plan)
  else let val ()=glyph_expansion_dispose(plan) in expansion_invariant() end)
  else if not(glyph_run_node(s,meta,node)) then let val ()=glyph_expansion_dispose(plan) in expansion_invariant() end else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val v=chosen(b,t,m,h,selection,core)
  in case+ check(meta,core,v,added) of
    | GlyphPassApplied() => read(b,t,m,s,meta,h,selection,glyph_expansion_append(plan,@{node=node,view=v}),links.next)
    | GlyphPassDomain() => rejected(plan,GlyphPassDomain())
    | GlyphPassReference() => rejected(plan,GlyphPassReference())
    | GlyphPassCapacity() => rejected(plan,GlyphPassCapacity()) end end
implement glyph_expansion_read(b,t,m,s,meta,selection) =
  read(b,t,m,s,meta,ot_sequence_lookup_header(t),selection,glyph_expansion_make(airlock_nat(meta.live)),meta.head)
