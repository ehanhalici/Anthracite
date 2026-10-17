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
implement mark_matrix_fixture() = ot_fixture_words(
  "0001 000C 0014 0002 001C 0032 0001 0002 0007 0008 0001 0002 0005 0006 0002 0000 000A 0001 0010 0001 000A 0014 0001 001E 0028 0002 000A 0010 0000 0016 0001 0064 00C8 0001 012C 0190 0001 01F4 0258")
fun sample {kind:int}(b: !Buf,t: !GposMarkMatrix(kind),mark: int,target: int,class: int,x: int,y: int): int = let
  val r=gpos_mark_matrix_query(b,t,mark,target)
in if r.matched andalso ieq(r.markClass,class) andalso ieq(r.target.anchor.x,x)
  andalso ieq(r.target.anchor.y,y) then 0 else 1 end
fun missing {kind:int}(b: !Buf,t: !GposMarkMatrix(kind),mark: int,target: int): int = let
  val r=gpos_mark_matrix_query(b,t,mark,target)
in if r.matched then 1 else 0 end
fun check {kind:int}(domain: GposMarkMatrixDomain(kind)): int = let val b=mark_matrix_fixture()
  val errors=case+ gpos_mark_matrix_parse(b,ot_fixture_span(b),10,domain) of
    | ~MarkMatrixRejected(e) => 1 | ~MarkMatrixAccepted(t) => let
      val errors=sample(b,t,7,5,0,100,200)+sample(b,t,8,5,1,300,400)+sample(b,t,8,6,1,500,600)+
        missing(b,t,7,6)+missing(b,t,9,5)+missing(b,t,7,4)
      val ()=gpos_mark_matrix_dispose(t)
    in errors end
  val ()=buf_free(b)
in errors end
implement mark_matrix_test_matches() = check(MarkToBase())+check(MarkToMark())
