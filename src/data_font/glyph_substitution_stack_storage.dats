#include "data_font/glyph_substitution_stack_internal.hats"
extern fun substitution_stack_failed(): int = "mac#anth_die_int"
implement glyph_substitution_stack_make(maximum) = let
  val bytes=g0uint2int_size_int(sizeof<GlyphSubstitutionFrame>)
  val limit=idiv(MAX_REC_FUEL,imul(bytes,2))
  val size=airlock_pos(imin(maximum,64))
in if ilt(maximum,1) orelse igt(maximum,limit) then let val failed=substitution_stack_failed()
    in GlyphSubstitutionStack(arrayptr_make_elt<GlyphSubstitutionFrame>(i2sz(size),glyph_substitution_frame_empty()),size,failed) end
  else GlyphSubstitutionStack(arrayptr_make_elt<GlyphSubstitutionFrame>(i2sz(size),glyph_substitution_frame_empty()),size,maximum) end
implement glyph_substitution_stack_get(stack,index) = let val+ GlyphSubstitutionStack(rows,n,maximum)=stack
in arrayptr_get_at<GlyphSubstitutionFrame>(rows,i2sz(airlock_below(index,n))) end
implement glyph_substitution_stack_set(stack,index,value) = let val+ GlyphSubstitutionStack(rows,n,maximum)=stack
in arrayptr_set_at<GlyphSubstitutionFrame>(rows,i2sz(airlock_below(index,n)),value) end
implement glyph_substitution_stack_dispose(stack) = let val+ ~GlyphSubstitutionStack(rows,n,maximum)=stack
in arrayptr_free(rows) end
