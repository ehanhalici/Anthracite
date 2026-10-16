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

fun capacity(b: !Buf,t: !GsubSequences(2)): int = let
  val+ GsubSequences(info)=t
  var remaining: int=2
in case+ gsub_sequences_validate(b,info,GsubMultiple(),remaining) of
  | ~None_vt() => 1 | ~Some_vt(e) => case+ e.reason of
    | OtCapacity() => 0 | OtBounds() => 1 | OtFormat() => 1 | OtGlyphDomain() => 1
    | OtOrder() => 1 | OtCoverageIndex() => 1 | OtPadding() => 1 | OtReference() => 1 | OtUnsupported() => 1 end
fun glyphs {n:nat} .<n>. (n: int(n),b: !Buf,v: GsubSequenceView,i: int): int =
  if n = 0 then 0 else let val g=gsub_sequence_glyph(b,v,i) in
    iadd(if ieq(g,0) then 0 else 1,glyphs(n-1,b,v,iadd(i,1))) end
fun multiple(b: !Buf): int = case+ gsub_sequences_parse(b,ot_fixture_span(b),1,GsubMultiple()) of
  | ~SequencesRejected(e) => 1 | ~SequencesAccepted(t) => let
    val v=gsub_sequences_query(b,t,0)
    val errors: int=if not(v.matched) orelse ine(v.count,WORD16_MAX_VALUE) then 1 else glyphs(WORD16_MAX_VALUE,b,v,0)
    val work=capacity(b,t)
    val ()=gsub_sequences_dispose(t)
  in iadd(errors,work) end
fun alternate(b: !Buf): int = case+ gsub_sequences_parse(b,ot_fixture_span(b),1,GsubAlternate()) of
  | ~SequencesRejected(e) => 1 | ~SequencesAccepted(t) => let
    val r=gsub_alternate_select(b,t,0,WORD16_MAX_VALUE)
    val bad=gsub_alternate_select(b,t,0,WORD16_MODULUS)
    val ok=r.matched andalso ieq(r.glyph,0) andalso not(bad.matched)
    val ()=gsub_sequences_dispose(t)
  in if ok then 0 else 1 end
implement sequence_test_stress() = let
  var b=ot_fixture_words("0001 0008 0001 000E 0001 0001 0000 FFFF")
  val ()=buf_resize(b,131094)
  val ()=buf_set_len(b,131094)
  val errors=multiple(b)+alternate(b)
  val ()=buf_free(b)
in errors end
