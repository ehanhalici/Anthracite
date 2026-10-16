#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/tables/opentype_classdef.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/opentype/definition/gdef_classes.sats"

fun empty(): OtClassInfo =
  @{span= @{offset=0,length=0},encoding=OtList(),count=0,first=0,maximum=0}
fun present(child: OtChild): bool = case+ child.kind of
  | ChildPresent() => true | ChildMissing() => false | ChildInvalid() => false
fun parse_child(b: !Buf,child: OtChild,glyphs: int): OtClassRead = case+ child.kind of
  | ChildMissing() => ClassAccepted(empty())
  | ChildPresent() => ot_classdef_parse(b,child.span,glyphs)
  | ChildInvalid() => ClassRejected(ot_error(OtBounds(),child.span))

fun with_attachment(b: !Buf,h: GdefHeaderInfo,glyphs: int,c: OtClassInfo): GdefClassRead =
  case+ parse_child(b,h.markAttach,glyphs) of
  | ~ClassRejected(e) => GdefClassRejected(e)
  | ~ClassAccepted(a) => GdefClassAccepted(@{classes=c,attachment=a,
      defined=present(h.classes),attachmentDefined=present(h.markAttach)})

implement gdef_classes_parse(b,h,glyphs) =
  if not(ot_glyph_domain_valid(glyphs)) then GdefClassRejected(ot_error(OtGlyphDomain(),h.span)) else
    case+ parse_child(b,h.classes,glyphs) of
    | ~ClassRejected(e) => GdefClassRejected(e)
    | ~ClassAccepted(c) => if igt(c.maximum,4) then GdefClassRejected(ot_error(OtGlyphDomain(),c.span))
      else with_attachment(b,h,glyphs,c)
