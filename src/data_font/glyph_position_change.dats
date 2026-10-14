#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_work.sats"
implement glyph_position_change(xa,ya,xo,yo,old) = let
  val status=if not(glyph_position_ready(xa.status)) then xa.status
    else if not(glyph_position_ready(ya.status)) then ya.status
    else if not(glyph_position_ready(xo.status)) then xo.status else yo.status
in @{status=status,value= @{xAdvance=xa.value,yAdvance=ya.value,xOffset=xo.value,yOffset=yo.value,
  attachment=old.attachment,parent=old.parent,anchorX=old.anchorX,anchorY=old.anchorY}} end
