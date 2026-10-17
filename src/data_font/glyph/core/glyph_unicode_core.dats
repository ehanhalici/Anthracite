#include "data_font/glyph/core/glyph_unicode_internal.hats"
(* Matches the documented OpenType fallback: Mn only, excluding default
   ignorables (e.g. CGJ/variation selectors). CCC and Unicode blocks are not GC. *)
implement glyph_unicode_kind_of(category,ignorable) =
  if ieq(category,6) andalso not(ignorable) then GlyphMark() else GlyphBase()
implement glyph_unicode_core(core,kind,ignorable) =
  @{glyph=core.glyph,scalar=core.scalar,sourceStart=core.sourceStart,sourceEnd=core.sourceEnd,cluster=core.cluster,
    mask=core.mask,association=core.association,ligature=core.ligature,component=core.component,
    components=core.components,multiplied=core.multiplied,unicodeKind=kind,ignorable=ignorable}
