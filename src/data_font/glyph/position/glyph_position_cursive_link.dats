#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_cursive_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_anchor.sats"
staload "data_font/glyph/position/glyph_position_cursive_work.sats"
implement glyph_position_cursive_detached(p) = @{xAdvance=p.xAdvance,yAdvance=p.yAdvance,xOffset=p.xOffset,yOffset=0,
  attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0}
implement glyph_position_cursive_attached(p,parent,y) = @{xAdvance=p.xAdvance,yAdvance=p.yAdvance,xOffset=p.xOffset,yOffset=y,
  attachment=AttachmentCursive(),parent=parent,anchorX=0,anchorY=0}
