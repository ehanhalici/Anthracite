#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "glyph_run_contracts.sats"
extern fun run_test_failed(): GlyphRun(0) = "mac#anth_die_box"
implement run_test_updated(s) = case+ s of | GlyphUpdated() => true | GlyphUnchanged() => false
  | GlyphCapacity() => false | GlyphNode() => false | GlyphDomain() => false | GlyphSource() => false
  | GlyphOrder() => false | GlyphAssociationError() => false | GlyphOverflow() => false
implement run_test_unchanged(s) = case+ s of | GlyphUpdated() => false | GlyphUnchanged() => true
  | GlyphCapacity() => false | GlyphNode() => false | GlyphDomain() => false | GlyphSource() => false
  | GlyphOrder() => false | GlyphAssociationError() => false | GlyphOverflow() => false
implement run_test_rejected(s) = case+ s of | GlyphUpdated() => false | GlyphUnchanged() => false
  | GlyphCapacity() => true | GlyphNode() => true | GlyphDomain() => true | GlyphSource() => true
  | GlyphOrder() => true | GlyphAssociationError() => true | GlyphOverflow() => true
implement run_test_take(edit,expected,errors) = let val+ ~GlyphRunEdited(run,status,node)=edit
  val ()=if expected(status) then () else errors := iadd(errors,1)
in run end
fun append {n:nat} .<n>. (n: int(n),run: GlyphRun(0),index: int,errors: &int >> _): GlyphRun(0) =
  if n = 0 then run else let
    val seed: GlyphSeed= @{glyph=iadd(10,imod(index,16)),scalar=1576,sourceStart=imul(index,2),
      sourceEnd=imul(iadd(index,1),2),cluster=index,mask=3u}
    val next=run_test_take(glyph_run_append(run,seed),run_test_updated,errors)
  in append(n-1,next,iadd(index,1),errors) end
implement run_test_nominal(capacity,count,errors) = case+ glyph_run_make(3,128,imax(64,imul(count,2)),capacity) of
  | ~GlyphRunRejected(status) => run_test_failed()
  | ~GlyphRunCreated(run) => append(airlock_nat(count),run,0,errors)
implement run_test_indices(a,b) = let val rows=buf_make(8)
  val ()=buf_set32(rows,0,a) and ()=buf_set32(rows,1,b)
in rows end
