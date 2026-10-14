#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_property.sats"
staload "data_text/arabic_join_types.sats"
staload "data_text/arabic_join.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "glyph_run_contracts.sats"
staload "arabic_join_contracts.sats"
extern fun nominal_failed(): GlyphRun(0) = "mac#anth_die_box"
extern fun plan_failed(): ArabicMaskPlan = "mac#anth_die_box"
fun copy{n:nat} .<n>. (n: int(n),source: string,b: !Buf,i: int): void =
  if n = 0 then () else let val ()=buf_set(b,i,c_str_byte(source,i)) in copy(n-1,source,b,iadd(i,1)) end
implement arabic_test_bytes(source) = let
  val size=c_strlen(source) val b=buf_make(size)
  val ()=copy(airlock_nat(size),source,b,0) val ()=buf_set_len(b,size)
in b end
fun append{n:nat} .<n>. (n: int(n),text: !ScalarText,run: GlyphRun(0),i: int,errors: &int >> _): GlyphRun(0) =
  if n = 0 then run else let
    val seed: GlyphSeed= @{glyph=iadd(10,imod(i,16)),scalar=scalar_value(text,i),
      sourceStart=scalar_start(text,i),sourceEnd=scalar_end(text,i),cluster=i,mask=2147483663u}
    val next=run_test_take(glyph_run_append(run,seed),run_test_updated,errors)
  in append(n-1,text,next,iadd(i,1),errors) end
implement arabic_test_nominal(text) = let
  val count=scalar_count(text)
  val length=if ieq(count,0) then 0 else scalar_end(text,isub(count,1))
in case+ glyph_run_make(3,128,length,count) of
  | ~GlyphRunRejected(status) => nominal_failed() | ~GlyphRunCreated(run) => let
    var errors: int=0 val next=append(airlock_nat(count),text,run,0,errors)
  in if ieq(errors,0) then next else let val ()=glyph_run_dispose(next) in nominal_failed() end end end
implement arabic_test_plan() = case+ arabic_mask_plan(@{initial=1u,medial=2u,final=4u,isolated=8u}) of
  | ~ArabicMaskRejected(e) => plan_failed() | ~ArabicMaskAccepted(plan) => plan
