#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/font_run.sats"
typedef RunBounds = @{x=llint,y=llint,minX=llint,maxX=llint,minY=llint,maxY=llint}
fun bounded(low: llint,high: llint): bool = low >= ~2147483648LL andalso high <= 2147483647LL
fun limits(d: GlyphPositionDirection,b: RunBounds): bool = case+ d of
  | PositionLTR() => bounded(b.minX,b.maxX) andalso bounded(b.minY,b.maxY)
  | PositionRTL() => bounded(b.x-b.maxX,b.x-b.minX) andalso bounded(b.y-b.maxY,b.y-b.minY)
fun advance(b: RunBounds,p: GlyphPosition): RunBounds = let
  val x=b.x+g0int2int_int_llint(p.xAdvance) and y=b.y+g0int2int_int_llint(p.yAdvance)
in @{x=x,y=y,minX=if x < b.minX then x else b.minX,maxX=if x > b.maxX then x else b.maxX,
  minY=if y < b.minY then y else b.minY,maxY=if y > b.maxY then y else b.maxY} end
fun finish(d: GlyphPositionDirection,b: RunBounds): FontRunExtent =
  if not(limits(d,b)) then @{status=FontRunOverflow(),xAdvance=0,yAdvance=0,drawn=0}
  else @{status=FontRunReady(),xAdvance=airlock_i32(b.x),yAdvance=airlock_i32(b.y),drawn=0}
fun sum{n:nat} .<n>. (left: int(n),p: !GlyphPositioned(1),node: int,b: RunBounds): FontRunExtent =
  if left = 0 then (if ieq(node,~1) then finish(glyph_position_direction(p),b) else @{status=FontRunGraph(),xAdvance=0,yAdvance=0,drawn=0}) else let
    val v=glyph_position_query(p,node)
  in case+ v.kind of | GlyphMissing() => @{status=FontRunGraph(),xAdvance=0,yAdvance=0,drawn=0}
    | GlyphPresent() => sum(left-1,p,v.links.next,advance(b,v.position)) end
implement font_run_measure(p) = let val meta=glyph_position_meta(p)
in sum(airlock_nat(meta.live),p,meta.head,@{x=0LL,y=0LL,minX=0LL,maxX=0LL,minY=0LL,maxY=0LL}) end
