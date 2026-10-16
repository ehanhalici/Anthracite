#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "data_font/resources/font_hit.sats"
staload "data_font/text/run/font_run.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/text/run/private/font_run_work.sats"
implement font_hit_edge(query,source,x,best) = let
  val distance=case+ query of | QueryCaret(byte) => iabs(isub(byte,source)) | QueryClick(pixel) => iabs(isub(pixel,x))
  val value=case+ query of | QueryCaret(byte) => x | QueryClick(pixel) => source
in if ilt(distance,best.distance) then @{distance=distance,value=value} else best end
fun edges(v: GlyphView,d: GlyphPositionDirection,offset: int,origin: FontRunPen,query: TextQuery,best: TextHit): TextHit =
  if ile(v.position.xAdvance,0) then best else let val left=iadd(offset,origin.x) val right=iadd(left,v.position.xAdvance)
    val start=case+ d of | PositionLTR() => left | PositionRTL() => right
    val finish=case+ d of | PositionLTR() => right | PositionRTL() => left
    val first=font_hit_edge(query,v.core.sourceStart,start,best)
  in font_hit_edge(query,v.core.sourceEnd,finish,first) end
fun walk{n:nat} .<n>. (left: int(n),p: !GlyphPositioned(1),offset: int,query: TextQuery,node: int,pen: FontRunPen,best: TextHit): TextHit =
  if left = 0 then best else let val v=glyph_position_query(p,node) val d=glyph_position_direction(p)
    val next=edges(v,d,offset,font_run_origin(d,pen,v.position),query,best)
  in walk(left-1,p,offset,query,v.links.next,font_run_next(d,pen,v.position),next) end
implement font_position_hit(p,offset,query,best) = let val meta=glyph_position_meta(p) val extent=font_run_measure(p)
in walk(airlock_nat(meta.live),p,offset,query,meta.head,font_run_initial(glyph_position_direction(p),extent),best) end
