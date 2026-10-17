#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/substitution/gsub_sequences.sats"
staload "data_font/opentype/substitution/gsub_sequence_work.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_extension.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/substitution/gsub_sequence_contracts.sats"

implement sequence_fixture() = ot_fixture_words("0001 000A 0002 0012 001A 0001 0002 0002 0005 0003 0007 0000 0007 0001 0004")
fun view(b: !Buf,v: GsubSequenceView,input: int): int =
  if ieq(input,2) then
    if not(v.matched) orelse ine(v.count,3) then 1
    else if ine(gsub_sequence_glyph(b,v,0),7) orelse ine(gsub_sequence_glyph(b,v,1),0) orelse
      ine(gsub_sequence_glyph(b,v,2),7) then 1 else 0
  else if ieq(input,5) then
    if not(v.matched) orelse ine(v.count,1) then 1
    else if ine(gsub_sequence_glyph(b,v,0),4) then 1 else 0
  else if v.matched orelse ine(v.count,0) then 1 else 0
fun queries {n:nat}{kind:int} .<n>. (n: int(n),b: !Buf,t: !GsubSequences(kind),input: int,total: int): int =
  if n = 0 then total else let val v=gsub_sequences_query(b,t,input) in
    queries(n-1,b,t,iadd(input,1),iadd(total,view(b,v,input))) end
fun select(b: !Buf,t: !GsubSequences(3),input: int,choice: int,expected: int): int = let
  val r=gsub_alternate_select(b,t,input,choice)
  val matched=ieq(input,2) andalso ige(choice,1) andalso ile(choice,3)
in if ieq(r.glyph,expected) andalso (r.matched = matched) then 0 else 1 end
fun alternatives(b: !Buf): int = case+ gsub_sequences_parse(b,ot_fixture_span(b),8,GsubAlternate()) of
  | ~SequencesRejected(e) => 1 | ~SequencesAccepted(t) => let
    val errors=queries(65538,b,t,~1,0)+select(b,t,2,1,7)+select(b,t,2,2,0)+select(b,t,2,3,7)+
      select(b,t,2,0,2)+select(b,t,2,~1,2)+select(b,t,2,4,2)+select(b,t,3,1,3)
    val ()=gsub_sequences_dispose(t)
  in errors end
fun multiple(b: !Buf): int = case+ gsub_sequences_parse(b,ot_fixture_span(b),8,GsubMultiple()) of
  | ~SequencesRejected(e) => 1 | ~SequencesAccepted(t) => let
    val errors=queries(65538,b,t,~1,0)
    val ()=gsub_sequences_dispose(t)
  in errors end
fun empty_set(): int = let
  val b=ot_fixture_words("0001 0008 0001 000E 0001 0001 0000 0000")
  val errors: int=case+ gsub_sequences_parse(b,ot_fixture_span(b),1,GsubAlternate()) of
    | ~SequencesRejected(e) => 1 | ~SequencesAccepted(t) => let
      val v=gsub_sequences_query(b,t,0)
      val r=gsub_alternate_select(b,t,0,1)
      val ok=v.matched andalso ieq(v.count,0) andalso not(r.matched) andalso ieq(r.glyph,0)
      val ()=gsub_sequences_dispose(t)
    in if ok then 0 else 1 end
  val ()=buf_free(b)
in errors end
implement sequence_test_formats() = let
  val b=sequence_fixture()
  val errors=multiple(b)+alternatives(b)+empty_set()
  val ()=buf_free(b)
  val r=ot_fixture_words("0001 000A 0002 001A 0022 0002 0002 0002 0002 0000 0005 0005 0001 0003 0007 0000 0007 0001 0004")
  val ranges=multiple(r)+alternatives(r)
  val ()=buf_free(r)
in errors+ranges end
