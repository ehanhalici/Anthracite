#include "data_font/glyph_unicode_internal.hats"
implement glyph_unicode_prepare(category,ignorables,run) = let val+ ~GlyphRun(phase,meta,s)=run
  val ()=glyph_unicode_walk(category,ignorables,s,meta)
  val next: GlyphRunMeta= @{used=meta.used,live=meta.live,head=meta.head,tail=meta.tail,font=meta.font,
    glyphs=meta.glyphs,sourceLength=meta.sourceLength,nextLigature=meta.nextLigature,properties=GlyphSourceUnicode()}
in GlyphRun(phase,next,s) end
