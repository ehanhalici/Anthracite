#include "data_font/glyph_unicode_internal.hats"
extern fun glyph_unicode_exhausted(): void = "mac#anth_die_void"
fun walk{n,k:nat} .<k>. (left: int(k),category: !PropertyMap(6),ignorables: !PropertyMap(8),
  s: !GlyphStorage(n),meta: GlyphRunMeta,node: int): void =
  if ieq(node,~1) then (if left = 0 then () else glyph_unicode_exhausted())
  else if left = 0 then glyph_unicode_exhausted()
  else if not(glyph_run_node(s,meta,node)) then glyph_unicode_exhausted() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val ignored=ieq(property_value(ignorables,core.scalar),1)
    val kind=glyph_unicode_kind_of(property_value(category,core.scalar),ignored)
    val ()=glyph_storage_set_core(s,node,glyph_unicode_core(core,kind,ignored))
  in walk(left-1,category,ignorables,s,meta,links.next) end
implement glyph_unicode_walk(category,ignorables,s,meta) =
  walk(airlock_nat(meta.live),category,ignorables,s,meta,meta.head)
