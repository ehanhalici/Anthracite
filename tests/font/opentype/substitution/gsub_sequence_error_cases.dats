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

fun reject{kind:int}(b: !Buf,s: OtSpan,glyphs: int,domain: GsubSequenceDomain(kind)): int =
  case+ gsub_sequences_parse(b,s,glyphs,domain) of
  | ~SequencesRejected(e) => 0 | ~SequencesAccepted(t) => let val ()=gsub_sequences_dispose(t) in 1 end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,length: int): int =
  if n = 0 then 0 else reject(b,@{offset=8,length=length},8,GsubMultiple())+
    reject(b,@{offset=8,length=length},8,GsubAlternate())+cuts(n-1,b,iadd(length,1))
fun change(at: int,value: int): int = let
  val b=sequence_fixture()
  val ()=ot_fixture_put16(b,at,value)
  val errors=reject(b,ot_fixture_span(b),8,GsubMultiple())
  val ()=buf_free(b)
in errors end
fun empty_multiple(): int = let
  val b=ot_fixture_words("0001 0008 0001 000E 0001 0001 0000 0000")
  val errors=reject(b,ot_fixture_span(b),1,GsubMultiple())
  val ()=buf_free(b)
in errors end
implement sequence_test_errors() = let
  val b=sequence_fixture()
  val errors=cuts(airlock_nat(isub(buf_len(b),8)),b,0)+
    reject(b,ot_fixture_span(b),0,GsubMultiple())+reject(b,ot_fixture_span(b),WORD16_MODULUS,GsubMultiple())+
    reject(b,@{offset= ~1,length=30},8,GsubMultiple())+
    reject(b,@{offset=8,length=SIGNED_INT_MAX_VALUE},8,GsubMultiple())
  val ()=buf_free(b)
in errors+empty_multiple()+change(0,2)+change(2,0)+change(2,9)+change(4,3)+
  change(6,0)+change(6,9)+change(6,WORD16_MAX_VALUE)+change(12,3)+change(18,WORD16_MAX_VALUE)+change(20,8) end
