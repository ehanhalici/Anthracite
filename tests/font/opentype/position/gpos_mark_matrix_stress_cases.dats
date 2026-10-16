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
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_mark_matrix_contracts.sats"
fun fixture(): Buf = let
  var b=ot_fixture_words("0001 000C 0012 FFFF 0018 0024 0001 0001 0007 0001 0001 0005 0001 FFFE 0006 0001 0001 0002 0001")
  val ()=buf_resize(b,131116) and ()=buf_set_len(b,131116)
in b end
implement mark_matrix_test_stress() = let val b=fixture()
  val errors=case+ gpos_mark_matrix_parse(b,ot_fixture_span(b),10,MarkToBase()) of
    | ~MarkMatrixRejected(e) => 1 | ~MarkMatrixAccepted(t) => let
      val r=gpos_mark_matrix_query(b,t,7,5)
      val ()=gpos_mark_matrix_dispose(t)
    in if not(r.matched) andalso ieq(r.markClass,65534) andalso ieq(r.mark.anchor.x,1)
      andalso ieq(r.mark.anchor.y,2) then 0 else 1 end
  val ()=buf_free(b)
in errors end
