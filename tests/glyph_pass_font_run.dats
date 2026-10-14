#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_single.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_single.sats"
staload "glyph_run_contracts.sats"
staload "glyph_pass_contracts.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/ot_single_lookup_types.sats"
staload "data_font/glyph_pass_lookup.sats"
extern fun font_run_failed(): GlyphRun(1) = "mac#anth_die_box"
fun nominal(glyphs: int,input: int,errors: &int >> _): GlyphRun(1) =
  case+ glyph_run_make(3,glyphs,4,2) of
  | ~GlyphRunRejected(status) => font_run_failed()
  | ~GlyphRunCreated(run) => let
    val first=run_test_take(glyph_run_append(run,@{glyph=input,scalar=1576,
      sourceStart=0,sourceEnd=2,cluster=0,mask=1u}),run_test_updated,errors)
    val second=run_test_take(glyph_run_append(first,@{glyph=input,scalar=305,
      sourceStart=2,sourceEnd=4,cluster=1,mask=2u}),run_test_updated,errors)
  in glyph_run_substitute(second) end
fun inspect(run: !GlyphRun(1),first: int,second: int): int = let
  val a=glyph_run_query(run,0) and b=glyph_run_query(run,1)
  val ok=ieq(a.core.glyph,first) andalso ieq(b.core.glyph,second)
    andalso ieq(a.core.scalar,1576) andalso ieq(b.core.scalar,305)
    andalso ieq(a.core.sourceStart,0) andalso ieq(a.core.sourceEnd,2)
    andalso ieq(b.core.sourceStart,2) andalso ieq(b.core.sourceEnd,4) andalso ieq(b.core.cluster,1)
in if ok then 0 else 1 end
implement pass_font_run(b,t,glyphs,input,output) = let
  var errors: int=0
  val all=pass_test_take(glyph_pass_single(b,t,nominal(glyphs,input,errors),@{kind=GlyphAll(),mask=0u}),2,2,errors)
  val ()=errors := iadd(errors,inspect(all,output,output))
  val ()=glyph_run_dispose(all)
  val masked=pass_test_take(glyph_pass_single(b,t,nominal(glyphs,input,errors),@{kind=GlyphMasked(),mask=1u}),2,1,errors)
  val ()=errors := iadd(errors,inspect(masked,output,input))
  val ()=glyph_run_dispose(masked)
in errors end
implement pass_font_lookup(b,t,metadata,glyphs,input,output) = let
  var errors: int=0
  val all=pass_test_take(glyph_pass_lookup(b,t,metadata,nominal(glyphs,input,errors),@{kind=GlyphAll(),mask=0u}),2,2,errors)
  val ()=errors := iadd(errors,inspect(all,output,output))
  val ()=glyph_run_dispose(all)
  val masked=pass_test_take(glyph_pass_lookup(b,t,metadata,nominal(glyphs,input,errors),@{kind=GlyphMasked(),mask=1u}),2,1,errors)
  val ()=errors := iadd(errors,inspect(masked,output,input))
  val ()=glyph_run_dispose(masked)
in errors end
