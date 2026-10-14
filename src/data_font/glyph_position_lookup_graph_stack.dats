#include "data_font/glyph_position_lookup_graph_internal.hats"
implement glyph_position_lookup_graph_stack_make(maximum) = let val n=airlock_pos(imin(maximum,64))
in GlyphPositionLookupGraphStack(arrayptr_make_elt<GlyphPositionLookupGraphFrame>(i2sz(n),glyph_position_lookup_graph_empty()),n,maximum) end
implement glyph_position_lookup_graph_stack_get(stack,index) = let val+ GlyphPositionLookupGraphStack(rows,n,maximum)=stack
in arrayptr_get_at<GlyphPositionLookupGraphFrame>(rows,i2sz(airlock_below(index,n))) end
implement glyph_position_lookup_graph_stack_set(stack,index,value) = let val+ GlyphPositionLookupGraphStack(rows,n,maximum)=stack
in arrayptr_set_at<GlyphPositionLookupGraphFrame>(rows,i2sz(airlock_below(index,n)),value) end
implement glyph_position_lookup_graph_stack_dispose(stack) = let val+ ~GlyphPositionLookupGraphStack(rows,n,maximum)=stack
in arrayptr_free(rows) end
