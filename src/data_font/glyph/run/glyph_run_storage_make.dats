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
implement glyph_core_empty() = @{glyph=0,scalar=0,sourceStart=0,sourceEnd=0,cluster=0,mask=0u,
  association=Unassociated(),ligature=0,component=0,components=0,multiplied=false,unicodeKind=GlyphUnclassified(),ignorable=false}
implement glyph_links_empty() = @{life=GlyphVacant(),previous= ~1,next= ~1}
implement glyph_position_empty() = @{xAdvance=0,yAdvance=0,xOffset=0,yOffset=0,
  attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0}
implement glyph_storage_capacity(count) = let
  val core=g0uint2int_size_int(sizeof<GlyphCore>)
  val links=g0uint2int_size_int(sizeof<GlyphLinks>)
  val position=g0uint2int_size_int(sizeof<GlyphPosition>)
  val bytes=iadd(core,iadd(links,position))
in ige(count,0) andalso ile(count,idiv(MAX_REC_FUEL,bytes)) end
implement glyph_storage_make(count) = let val size=g1int2uint_int_size(count)
  val core=arrayptr_make_elt<GlyphCore>(size,glyph_core_empty())
  val links=arrayptr_make_elt<GlyphLinks>(size,glyph_links_empty())
  val positions=arrayptr_make_elt<GlyphPosition>(size,glyph_position_empty())
in GlyphStorage(count,core,links,positions) end
implement glyph_storage_count(s) = let val+ GlyphStorage(count,core,links,positions)=s in count end
implement glyph_storage_dispose(s) = let val+ ~GlyphStorage(count,core,links,positions)=s
  val ()=arrayptr_free(core) and ()=arrayptr_free(links)
in arrayptr_free(positions) end
