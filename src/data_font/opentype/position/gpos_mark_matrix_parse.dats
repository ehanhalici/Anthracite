#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix.sats"
staload "data_font/opentype/position/gpos_mark_matrix_work.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_shared.sats"
fun targets {kind:int}{m:nat}(b: !Buf,info: GposMarkMatrixInfo,domain: GposMarkMatrixDomain(kind),
  marks: OtAnchorCache(m,m)): GposMarkMatrixRead(kind) = let
  val count=imul(info.classes,info.targetCount)
in case+ gpos_mark_anchors(b,info.targetArray,count,iadd(2,imul(count,2)),AttachmentFields(),AnchorOptional()) of
  | ~AnchorCacheRejected(e) => let val ()=ot_anchor_cache_dispose(marks) in MarkMatrixRejected(e) end
  | ~AnchorCacheAccepted(cache) => MarkMatrixAccepted(GposMarkMatrix(domain,info,marks,cache)) end
fun marks{kind:int}(b: !Buf,info: GposMarkMatrixInfo,domain: GposMarkMatrixDomain(kind)): GposMarkMatrixRead(kind) =
  case+ gpos_mark_anchors(b,info.markArray,info.markCount,iadd(2,imul(info.markCount,4)),MarkRecordFields(),AnchorRequired()) of
  | ~AnchorCacheRejected(e) => MarkMatrixRejected(e) | ~AnchorCacheAccepted(cache) => targets(b,info,domain,cache)
implement gpos_mark_matrix_parse(b,s,glyphs,domain) = case+ gpos_mark_matrix_header(b,s,glyphs) of
  | ~MarkMatrixHeaderRejected(e) => MarkMatrixRejected(e) | ~MarkMatrixHeaderAccepted(info) => marks(b,info,domain)
