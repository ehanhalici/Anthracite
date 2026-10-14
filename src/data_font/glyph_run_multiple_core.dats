#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/gdef_types.sats"
fun expanded_kind(kind: GdefGlyphKind): GdefGlyphKind = case+ kind of
  | GlyphLigature() => GlyphBase() | GlyphBase() => kind | GlyphMark() => kind
  | GlyphComponent() => kind | GlyphUnclassified() => kind
fun component(core: GlyphCore,index: int): int = case+ core.association of
  | Unassociated() => index | LigatureMark() => core.component
  | LigatureOwner() => core.component | LigatureForward() => core.component
implement glyph_run_multiple_core(core,glyph,index,count) =
  if ieq(count,1) then glyph_run_new_glyph(core,glyph) else
  @{glyph=glyph,scalar=core.scalar,sourceStart=core.sourceStart,sourceEnd=core.sourceEnd,
    cluster=core.cluster,mask=core.mask,association=core.association,ligature=core.ligature,
    component=component(core,index),components=core.components,multiplied=true,unicodeKind=expanded_kind(core.unicodeKind),ignorable=core.ignorable}
