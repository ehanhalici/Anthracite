#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
staload "data_font/gpos_mark_shared_types.sats"
staload "data_font/gpos_mark_shared.sats"
staload "data_font/gpos_mark_shared_work.sats"
fun accepted(b: !Buf,root: OtSpan,marks: OtCoverageInfo,targets: OtCoverageInfo,
  mark: OtSpan,target: OtSpan,glyphs: int): GposMarkHeaderRead = let
  val m=ot_u16(b,mark,0) and t=ot_u16(b,target,0) and classes=ot_u16(b,root,6)
in if ine(m,marks.total) orelse ine(t,targets.total) then MarkHeaderRejected(ot_error(OtCoverageIndex(),root))
  else if not(ot_rows_fit(mark,2,m,4)) then MarkHeaderRejected(ot_error(OtBounds(),mark))
  else if not(gpos_mark_records(b,mark,m,classes)) then MarkHeaderRejected(ot_error(OtReference(),mark))
  else if not(ot_anchor_cache_capacity(m)) then MarkHeaderRejected(ot_error(OtCapacity(),mark))
  else MarkHeaderAccepted(@{marks=marks,targets=targets,markArray=mark,targetArray=target,
    classes=classes,markCount=m,targetCount=t,glyphs=glyphs}) end
fun target(b: !Buf,s: OtSpan,m: OtCoverageInfo,t: OtCoverageInfo,mark: OtSpan,glyphs: int): GposMarkHeaderRead = let
  val child=ot_optional_child(s,ot_u16(b,s,10),12)
in case+ child.kind of
  | ChildMissing() => MarkHeaderRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => MarkHeaderRejected(ot_error(OtBounds(),s))
  | ChildPresent() => if ilt(child.span.length,2) then MarkHeaderRejected(ot_error(OtBounds(),child.span))
    else accepted(b,s,m,t,mark,child.span,glyphs) end
implement gpos_mark_arrays(b,s,m,t,glyphs) = let val child=ot_optional_child(s,ot_u16(b,s,8),12) in
  case+ child.kind of
  | ChildMissing() => MarkHeaderRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => MarkHeaderRejected(ot_error(OtBounds(),s))
  | ChildPresent() => if ilt(child.span.length,2) then MarkHeaderRejected(ot_error(OtBounds(),child.span))
    else target(b,s,m,t,child.span,glyphs) end
