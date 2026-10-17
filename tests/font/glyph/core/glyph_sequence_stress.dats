#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/substitution/gsub_sequences.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_sequence.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/run/glyph_run_contracts.sats"
staload "font/glyph/pass/glyph_pass_contracts.sats"
staload "font/glyph/core/glyph_sequence_contracts.sats"
fun rows{n:nat} .<n>. (left: int(n),run: !GlyphRun(1),node: int,previous: int,i: int,acc: int): int =
  if left = 0 then iadd(acc,if ieq(node,~1) then 0 else 1) else let
    val v=glyph_run_query(run,node)
    val expected=if ieq(imod(i,3),1) then 0 else 11
    val errors=iadd(seq_test_core(run,node,expected,idiv(i,3)),if ieq(v.links.previous,previous) then 0 else 1)
  in rows(left-1,run,v.links.next,node,iadd(i,1),iadd(acc,errors)) end
fun expanded(): int = let val b=seq_test_fixture()
  val t=seq_test_table(b,GsubMultiple()) and m=seq_test_metadata(b,3,128)
  var errors: int=0
  val run=pass_test_take(glyph_pass_multiple(b,t,m,seq_test_nominal(128,10,WORD16_SIGN_BIT,errors),
    @{kind=GlyphAll(),mask=0u}),WORD16_SIGN_BIT,WORD16_SIGN_BIT,errors)
  val ()=errors := errors+rows(98304,run,0,~1,0,0)
  val meta=glyph_run_meta(run)
  val ()=if ieq(meta.live,98304) andalso ieq(meta.used,98304) then () else errors := errors+1
  val ()=glyph_run_dispose(run) and ()=ot_sequence_lookup_dispose(t) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
fun aliases{n:nat} .<n>. (left: int(n),b: !Buf,i: int): void = if left = 0 then () else let
  val ()=ot_fixture_put16(b,iadd(6,imul(i,2)),65534)
in aliases(left-1,b,iadd(i,1)) end
fun copy{n:nat} .<n>. (left: int(n),b: !Buf,source: !Buf,i: int): void = if left = 0 then () else let
  val ()=ot_fixture_put16(b,iadd(65534,imul(i,2)),ot_fixture_read16(source,iadd(10,imul(i,2))))
in copy(left-1,b,source,iadd(i,1)) end
fun alias_fixture(): Buf = let val source=seq_test_fixture()
  val b=buf_make(65564)
  val ()=buf_set_len(b,65564)
  val ()=ot_fixture_put16(b,0,2) and ()=ot_fixture_put16(b,4,32764)
  val ()=aliases(32764,b,0)
  val ()=copy(11,b,source,0)
  val ()=buf_free(source)
in b end
fun capacity(b: Buf,count: int): int = let
  val t=seq_test_table(b,GsubMultiple()) and m=seq_test_metadata(b,3,128)
  var errors: int=0
  val+ ~GlyphPassResult(run,status,visited,matches)=glyph_pass_multiple(b,t,m,
    seq_test_nominal(128,10,count,errors),@{kind=GlyphAll(),mask=0u})
  val denied=case+ status of | GlyphPassCapacity() => true | GlyphPassApplied() => false
    | GlyphPassDomain() => false | GlyphPassReference() => false
  val meta=glyph_run_meta(run)
  val ()=if denied andalso ieq(visited,0) andalso ieq(matches,0) andalso ieq(meta.live,count)
    andalso ieq(meta.used,count) andalso ieq(glyph_run_capacity(run),count) then () else errors := errors+1
  val ()=errors := errors+seq_test_core(run,0,10,0)+seq_test_core(run,isub(count,1),10,isub(count,1))
  val ()=glyph_run_dispose(run) and ()=ot_sequence_lookup_dispose(t) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
fun huge_fixture(): Buf = let val b=buf_make(131102)
  val ()=buf_set_len(b,131102)
  val ()=ot_fixture_put16(b,0,2) and ()=ot_fixture_put16(b,4,1) and ()=ot_fixture_put16(b,6,8)
  val ()=ot_fixture_put16(b,8,1) and ()=ot_fixture_put16(b,10,8) and ()=ot_fixture_put16(b,12,1)
  val ()=ot_fixture_put16(b,14,14) and ()=ot_fixture_put16(b,16,1) and ()=ot_fixture_put16(b,18,1)
  val ()=ot_fixture_put16(b,20,10) and ()=ot_fixture_put16(b,22,WORD16_MAX_VALUE)
in b end
implement seq_test_stress() = expanded()+capacity(alias_fixture(),WORD16_SIGN_BIT)+capacity(huge_fixture(),WORD16_SIGN_BIT)
