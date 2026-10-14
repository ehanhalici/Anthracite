#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
staload "data_font/gpos_mark_shared_types.sats"
staload "data_font/gpos_mark_shared.sats"
staload "data_font/gpos_mark_ligature_types.sats"
staload "data_font/gpos_mark_ligature.sats"
staload "opentype_fixture.sats"
staload "gpos_mark_ligature_contracts.sats"
implement mark_ligature_fixture() = ot_fixture_words("0001 000C 0014 0002 001C 0032 0001 0002 0007 0008 0001 0002 0005 0006 0002 0000 000A 0001 0010 0001 000A 0014 0001 001E 0028 0002 0006 0022 0002 000A 0010 0000 0016 0001 0064 00C8 0001 012C 0190 0001 01F4 0258 0001 0006 0000 0001 02BC 0320")
fun sample(b: !Buf,t: !GposMarkLigature,mark: int,target: int,component: int,x: int,y: int): int = let
  val r=gpos_mark_ligature_query(b,t,mark,target,component)
in if r.matched andalso ieq(r.target.anchor.x,x) andalso ieq(r.target.anchor.y,y) then 0 else 1 end
fun missing(b: !Buf,t: !GposMarkLigature,mark: int,target: int,component: int): int = let
  val r=gpos_mark_ligature_query(b,t,mark,target,component)
in if r.matched then 1 else 0 end
fun parsed(b: !Buf): int = case+ gpos_mark_ligature_parse(b,ot_fixture_span(b),10) of
  | ~MarkLigatureRejected(e) => 1 | ~MarkLigatureAccepted(t) => let
    val errors=sample(b,t,7,5,0,100,200)+sample(b,t,8,5,0,300,400)+sample(b,t,8,5,1,500,600)+
      sample(b,t,7,6,0,700,800)+missing(b,t,7,5,1)+missing(b,t,8,6,0)+
      missing(b,t,7,5,~1)+missing(b,t,7,5,2)+missing(b,t,7,6,1)+missing(b,t,9,5,0)+missing(b,t,7,4,0)
    val ()=gpos_mark_ligature_dispose(t)
  in errors end
implement mark_ligature_test_matches() = let val b=mark_ligature_fixture()
  val errors=parsed(b) val ()=buf_free(b) in errors end
