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
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_value_contracts.sats"
fun anchor(words: string): int = let val b=ot_fixture_words(words) in
  case+ ot_anchor_parse(b,ot_fixture_span(b)) of | ~AnchorRejected(e) => let val ()=buf_free(b) in 0 end
  | ~AnchorAccepted(a) => let val ()=buf_free(b) in 1 end end
fun value(offset: int,length: int,at: int,floor: int): int = let
  val b=ot_fixture_words("0001 0000 0000 0000")
  val errors=case+ ot_value_format(16) of | ~ValueFormatRejected() => 1
    | ~ValueFormatAccepted(f) => case+ ot_value_parse(b,@{offset=offset,length=length},at,f,floor) of
      | ~ValueRejected(e) => 0 | ~ValueAccepted(v) => 1
  val ()=buf_free(b)
in errors end
implement gpos_test_errors() = anchor("")+anchor("0001 0000")+anchor("0002 0000 0000")+
  anchor("0004 0000 0000")+anchor("0003 0000 0000 0000")+
  anchor("0003 0000 0000 0008 0000")+anchor("0003 0000 0000 0010 0000")+
  anchor("0003 0000 0000 000A 0000 0005 0006 0004")+
  value(~1,8,0,2)+value(8,SIGNED_INT_MAX_VALUE,0,2)+value(8,8,~1,2)+
  value(8,8,8,8)+value(8,8,0,1)+value(8,8,0,9)
