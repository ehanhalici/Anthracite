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
staload "data_font/opentype/tables/opentype_coverage.sats"
fun missing(): GposMarkMatrixView = @{matched=false,mark=ot_anchor_missing(),target=ot_anchor_missing(),markClass=0}
fun slots{m,t:nat}(b: !Buf,info: GposMarkMatrixInfo,marks: !OtAnchorCache(m,m),
  targets: !OtAnchorCache(t,t),mark: int,target: int): GposMarkMatrixView = let
  val class=ot_u16(b,info.markArray,iadd(2,imul(mark,4)))
  val a=ot_anchor_cache_get(marks,mark)
  val c=ot_anchor_cache_get(targets,iadd(imul(target,info.classes),class))
  val found=case+ c.kind of | AnchorMissing() => false | AnchorPresent() => true
in @{matched=found,mark=a,target=c,markClass=class} end
implement gpos_mark_matrix_query(b,table,mark,target) = let
  val+ GposMarkMatrix(domain,info,marks,targets)=table
  val m=ot_coverage_index(b,info.marks,mark) and t=ot_coverage_index(b,info.targets,target)
in if not(m.found) orelse not(t.found) then missing() else slots(b,info,marks,targets,m.index,t.index) end
implement gpos_mark_matrix_dispose(table) = let val+ ~GposMarkMatrix(domain,info,marks,targets)=table
  val ()=ot_anchor_cache_dispose(marks)
in ot_anchor_cache_dispose(targets) end
implement gpos_mark_matrix_glyphs(table) = let val+ GposMarkMatrix(domain,info,marks,targets)=table in info.glyphs end
implement gpos_mark_matrix_target(b,table,glyph) = let
  val+ GposMarkMatrix(domain,info,marks,targets)=table
  val index=ot_coverage_index(b,info.targets,glyph)
in index.found end
