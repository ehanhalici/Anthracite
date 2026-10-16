#include "data_font/glyph/context/glyph_context_arena_internal.hats"
extern fun arena_invariant(): int = "mac#anth_die_int"
implement glyph_context_arena_make(maximum) =
  if ilt(maximum,0) orelse igt(maximum,idiv(MAX_REC_FUEL,16)) then let val failed=arena_invariant()
    in GlyphContextArena(buf_make(0),0,failed) end else GlyphContextArena(buf_make(imul(imin(maximum,64),8)),0,maximum)
implement glyph_context_arena_dispose(arena) = let val+ ~GlyphContextArena(rows,used,maximum)=arena in buf_free(rows) end
implement glyph_context_arena_reset(arena) = let val+ @GlyphContextArena(rows,used,maximum)=arena
  val ()=used := 0 val ()=buf_set_len(rows,0) prval ()=fold@(arena)
in () end
implement glyph_context_arena_valid(arena,id) = let val+ GlyphContextArena(rows,used,maximum)=arena
in ige(id,0) andalso ilt(id,used) end
implement glyph_context_arena_value(arena,id) = let val+ GlyphContextArena(rows,used,maximum)=arena
in if glyph_context_arena_valid(arena,id) then buf_get32(rows,imul(id,2)) else arena_invariant() end
implement glyph_context_arena_next(arena,id) = let val+ GlyphContextArena(rows,used,maximum)=arena
in if glyph_context_arena_valid(arena,id) then buf_get32(rows,iadd(imul(id,2),1)) else arena_invariant() end
implement glyph_context_arena_link(arena,id,next) = let val+ GlyphContextArena(rows,used,maximum)=arena
in if not(glyph_context_arena_valid(arena,id)) orelse (ine(next,~1) andalso not(glyph_context_arena_valid(arena,next)))
  then let val failed=arena_invariant() in seen_int(failed) end else buf_set32(rows,iadd(imul(id,2),1),next) end
