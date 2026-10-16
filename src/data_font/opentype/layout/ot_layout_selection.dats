#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_records.sats"
staload "data_font/opentype/layout/ot_layout_tags.sats"
staload "data_font/opentype/layout/ot_layout_language.sats"

implement ot_script_select(b,info,tag) = let val found=ot_record_find(b,info.scripts,tag) in
  if found.found then ot_record_child(b,info.scripts,found.index) else let
    val fallback=ot_record_find(b,info.scripts,ot_tag_default())
  in if fallback.found then ot_record_child(b,info.scripts,fallback.index)
    else @{kind=ChildMissing(),span= @{offset=0,length=0}} end end

implement ot_language_default(b,script) = case+ script.kind of
  | ChildMissing() => script | ChildInvalid() => script
  | ChildPresent() => let val r=ot_record_list(b,script.span,4) in
    ot_optional_child(r.span,ot_u16(b,r.span,0),iadd(4,imul(r.count,6))) end

implement ot_language_named(b,script,tag) = case+ script.kind of
  | ChildMissing() => script | ChildInvalid() => script
  | ChildPresent() => let
    val r=ot_record_list(b,script.span,4)
    val found=ot_record_find(b,r,tag)
  in if found.found then ot_record_child(b,r,found.index) else ot_language_default(b,script) end
