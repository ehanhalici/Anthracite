#include "data_font/glyph_position_lookup_graph_internal.hats"
fun copy{n,m:nat}{i:nat | i <= n} .<n-i>. (index: int(i),source: !arrayptr(GlyphPositionLookupGraphFrame,n),
  target: !arrayptr(GlyphPositionLookupGraphFrame,m),count: int(n),size: int(m)): void =
  if index = count then () else let
    val row=arrayptr_get_at<GlyphPositionLookupGraphFrame>(source,i2sz(index))
    val ()=arrayptr_set_at<GlyphPositionLookupGraphFrame>(target,i2sz(airlock_below(index,size)),row)
  in copy(index+1,source,target,count,size) end
fun grow(stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,needed: int): void = let
  val+ ~GlyphPositionLookupGraphStack(rows,n,maximum)=stack
  val size=airlock_pos(imin(maximum,imax(needed,imul(n,2))))
  val target=arrayptr_make_elt<GlyphPositionLookupGraphFrame>(i2sz(size),glyph_position_lookup_graph_empty())
  val ()=copy(0,rows,target,n,size)
  val ()=arrayptr_free(rows)
in stack := GlyphPositionLookupGraphStack(target,size,maximum) end
implement glyph_position_lookup_graph_stack_reserve(stack,needed) = let val+ GlyphPositionLookupGraphStack(rows,n,maximum)=stack
in if ilt(needed,0) orelse igt(needed,maximum) then PositionCapacity()
  else if ile(needed,n) then PositionReady() else let val ()=grow(stack,needed) in PositionReady() end end
