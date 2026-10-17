#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_classdef.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/opentype/definition/gdef_classes.sats"

extern fun invalid_glyph_class(): GdefGlyphKind = "mac#anth_die_box"
implement gdef_glyph_kind_of(code) = case+ code of
  | 0 => GlyphUnclassified() | 1 => GlyphBase() | 2 => GlyphLigature()
  | 3 => GlyphMark() | 4 => GlyphComponent() | _ => invalid_glyph_class()
implement gdef_glyph_kind(b,m,gid) =
  if m.defined then gdef_glyph_kind_of(ot_classdef_value(b,m.classes,gid)) else GlyphUnclassified()
implement gdef_mark_attachment(b,m,gid) =
  if m.attachmentDefined then ot_classdef_value(b,m.attachment,gid) else 0
