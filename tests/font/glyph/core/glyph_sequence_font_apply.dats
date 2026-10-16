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
fun outputs{n:nat} .<n>. (left: int(n),b: !Buf,run: !GlyphRun(1),oracle: !Buf,at: int,node: int,i: int): int =
  if left = 0 then (if ieq(node,~1) then 0 else 1) else let
    val v=glyph_run_query(run,node)
    val expected=ot_fixture_read16(oracle,iadd(at,imul(i,2)))
    val errors=seq_test_core(run,node,expected,0)
  in errors+outputs(left-1,b,run,oracle,at,v.links.next,iadd(i,1)) end
implement seq_font_multiple(b,t,m,glyphs,input,oracle,at,count) = let var errors: int=0
  val view=ot_multiple_lookup_query(b,t,input)
  val run=pass_test_take(glyph_pass_multiple(b,t,m,seq_test_nominal(glyphs,input,1,errors),
    @{kind=GlyphAll(),mask=0u}),1,1,errors)
  val ()=errors := errors+outputs(airlock_nat(count),b,run,oracle,at,0,0)
  val meta=glyph_run_meta(run)
  val ()=if view.matched andalso ieq(view.count,count) andalso ieq(meta.live,count) then () else errors := errors+1
  val ()=glyph_run_dispose(run)
in errors end
fun alternate(b: !Buf,t: !OtSequenceLookup(3),m: !GlyphMetadata,glyphs: int,input: int,choice: int,expected: int): int = let
  var errors: int=0
  val r=ot_alternate_lookup_query(b,t,input,choice)
  val run=pass_test_take(glyph_pass_alternate(b,t,m,seq_test_nominal(glyphs,input,1,errors),
    @{kind=GlyphAll(),mask=0u},choice),1,1,errors)
  val ()=errors := errors+seq_test_core(run,0,expected,0)
  val ()=if r.matched andalso ieq(r.glyph,expected) then () else errors := errors+1
  val ()=glyph_run_dispose(run)
in errors end
fun choices{n:nat} .<n>. (left: int(n),b: !Buf,t: !OtSequenceLookup(3),m: !GlyphMetadata,
  glyphs: int,input: int,oracle: !Buf,at: int,i: int): int = if left = 0 then 0 else
  alternate(b,t,m,glyphs,input,iadd(i,1),ot_fixture_read16(oracle,iadd(at,imul(i,2))))
    +choices(left-1,b,t,m,glyphs,input,oracle,at,iadd(i,1))
implement seq_font_alternate(b,t,m,glyphs,input,oracle,at,count) =
  choices(airlock_nat(count),b,t,m,glyphs,input,oracle,at,0)
