#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata_work.sats"
implement glyph_metadata_empty_classes() = let
  val empty: OtClassInfo= @{span= @{offset=0,length=0},encoding=OtList(),count=0,first=0,maximum=0}
in @{classes=empty,attachment=empty,defined=false,attachmentDefined=false} end
