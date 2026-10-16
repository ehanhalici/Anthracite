#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
implement glyph_run_node(s,meta,node) = if ilt(node,0) orelse ige(node,meta.used) then false else
  let val links=glyph_storage_links(s,node) in case+ links.life of
    | GlyphVacant() => false | GlyphLive() => true | GlyphRemoved() => false end
implement glyph_run_glyph(meta,glyph) = ige(glyph,0) andalso ilt(glyph,meta.glyphs)
implement glyph_run_seed(meta,seed) = glyph_run_glyph(meta,seed.glyph)
  andalso ige(seed.scalar,0) andalso ile(seed.scalar,UNICODE_MAX_SCALAR)
  andalso (ilt(seed.scalar,UNICODE_SURROGATE_START) orelse igt(seed.scalar,57343))
  andalso ige(seed.sourceStart,0) andalso ige(seed.sourceEnd,seed.sourceStart)
  andalso ile(seed.sourceEnd,meta.sourceLength) andalso ige(seed.cluster,0)
implement glyph_run_seed_core(seed) = @{glyph=seed.glyph,scalar=seed.scalar,sourceStart=seed.sourceStart,
  sourceEnd=seed.sourceEnd,cluster=seed.cluster,mask=seed.mask,
  association=Unassociated(),ligature=0,component=0,components=1,multiplied=false,unicodeKind=GlyphUnclassified(),ignorable=false}
implement glyph_run_new_glyph(core,glyph) = @{glyph=glyph,scalar=core.scalar,sourceStart=core.sourceStart,
  sourceEnd=core.sourceEnd,cluster=core.cluster,mask=core.mask,association=core.association,
  ligature=core.ligature,component=core.component,components=core.components,multiplied=core.multiplied,unicodeKind=core.unicodeKind,ignorable=core.ignorable}
implement glyph_run_new_mask(core,mask) = @{glyph=core.glyph,scalar=core.scalar,sourceStart=core.sourceStart,
  sourceEnd=core.sourceEnd,cluster=core.cluster,mask=mask,association=core.association,
  ligature=core.ligature,component=core.component,components=core.components,multiplied=core.multiplied,unicodeKind=core.unicodeKind,ignorable=core.ignorable}
implement glyph_run_new_cluster(core,cluster) = @{glyph=core.glyph,scalar=core.scalar,sourceStart=core.sourceStart,
  sourceEnd=core.sourceEnd,cluster=cluster,mask=core.mask,association=core.association,
  ligature=core.ligature,component=core.component,components=core.components,multiplied=core.multiplied,unicodeKind=core.unicodeKind,ignorable=core.ignorable}
