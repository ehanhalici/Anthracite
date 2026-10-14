#include "data_font/glyph_substitution_stack_internal.hats"
fun copy{n,m:nat}{i:nat | i <= n} .<n-i>. (index: int(i),source: !arrayptr(GlyphSubstitutionFrame,n),
  target: !arrayptr(GlyphSubstitutionFrame,m),count: int(n),size: int(m)): void =
  if index = count then () else let
    val row=arrayptr_get_at<GlyphSubstitutionFrame>(source,i2sz(index))
    val ()=arrayptr_set_at<GlyphSubstitutionFrame>(target,i2sz(airlock_below(index,size)),row)
  in copy(index+1,source,target,count,size) end
fun grow(stack: &GlyphSubstitutionStack >> GlyphSubstitutionStack,needed: int): void = let
  val+ ~GlyphSubstitutionStack(rows,n,maximum)=stack
  val size=airlock_pos(imin(maximum,imax(needed,imul(n,2))))
  val target=arrayptr_make_elt<GlyphSubstitutionFrame>(i2sz(size),glyph_substitution_frame_empty())
  val ()=copy(0,rows,target,n,size)
  val ()=arrayptr_free(rows)
in stack := GlyphSubstitutionStack(target,size,maximum) end
implement glyph_substitution_stack_reserve(stack,needed) = let val+ GlyphSubstitutionStack(rows,n,maximum)=stack
in if ilt(needed,0) orelse igt(needed,maximum) then GlyphPassCapacity()
  else if ile(needed,n) then GlyphPassApplied() else let val ()=grow(stack,needed) in GlyphPassApplied() end end
