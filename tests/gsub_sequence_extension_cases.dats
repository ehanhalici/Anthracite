#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/gsub_sequences.sats"
staload "data_font/gsub_sequence_work.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_extension.sats"
staload "opentype_fixture.sats"
staload "font_fixture.sats"
staload "gsub_sequence_contracts.sats"
staload "data_font/gsub_single.sats"
fun target {kind:int}(b: !Buf,domain: OtLayoutDomain(kind),expected: int): int =
  case+ ot_extension_parse(b,ot_fixture_span(b),domain) of
  | ~ExtensionRejected(e) => 1 | ~ExtensionAccepted(v) =>
    if ieq(v.span.offset,expected) then 0 else 1
fun reject {kind:int}(b: !Buf,domain: OtLayoutDomain(kind)): int =
  case+ ot_extension_parse(b,ot_fixture_span(b),domain) of
  | ~ExtensionRejected(e) => 0 | ~ExtensionAccepted(v) => 1
fun change(at: int,value: int): int = let
  val b=ot_fixture_words("0001 0001 0000 0008 0001")
  val ()=ot_fixture_put16(b,at,value)
  val errors=reject(b,OtSubstitution())
  val ()=buf_free(b)
in errors end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,length: int): int =
  if n = 0 then 0 else let
    val s= @{offset=8,length=length}
    val error: int=case+ ot_extension_parse(b,s,OtSubstitution()) of
      | ~ExtensionRejected(e) => 0 | ~ExtensionAccepted(v) => 1
  in iadd(error,cuts(n-1,b,iadd(length,1))) end
fun extended_single(b: !Buf): int = case+ ot_extension_parse(b,ot_fixture_span(b),OtSubstitution()) of
  | ~ExtensionRejected(e) => 1 | ~ExtensionAccepted(v) => case+ gsub_single_parse(b,v.span,2) of
    | ~SingleRejected(e) => 1 | ~SingleAccepted(t) => let
      val r=gsub_single_query(b,t,0)
      val ok=r.matched andalso ieq(r.glyph,1)
      val ()=gsub_single_dispose(t)
    in if ok then 0 else 1 end
fun large(): int = let
  var b=ot_fixture_words("0001 0001 0001 0000")
  val ()=buf_resize(b,65556)
  val ()=fixture_put16(b,65544,1) and ()=fixture_put16(b,65546,6)
  val ()=fixture_put16(b,65548,1) and ()=fixture_put16(b,65550,1)
  val ()=fixture_put16(b,65552,1) and ()=fixture_put16(b,65554,0)
  val ()=buf_set_len(b,65556)
  val errors=target(b,OtSubstitution(),65544)+extended_single(b)
  val ()=buf_free(b)
in errors end
implement sequence_test_extension() = let
  val b=ot_fixture_words("0001 0001 0000 0008 0001")
  val errors=target(b,OtSubstitution(),16)+target(b,OtPositioning(),16)+cuts(10,b,0)
  val ()=ot_fixture_put16(b,2,9)
  val rejected=reject(b,OtPositioning())
  val ()=buf_free(b)
in errors+rejected+large()+change(0,2)+change(2,0)+change(2,7)+change(2,9)+
  change(4,32768)+change(6,0)+change(6,7)+change(6,9)+change(6,65535) end
