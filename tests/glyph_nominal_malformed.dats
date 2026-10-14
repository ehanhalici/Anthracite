#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_nominal.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_db.sats"
staload "opentype_fixture.sats"
staload "glyph_nominal_contracts.sats"
fun fixture(): Buf = let val b=buf_make(7)
  val ()=buf_set(b,0,224) and ()=buf_set(b,1,128) and ()=buf_set(b,2,65)
  val ()=buf_set(b,3,192) and ()=buf_set(b,4,175) and ()=buf_set(b,5,0) and ()=buf_set(b,6,255)
  val ()=buf_set_len(b,7)
in b end
fun rows{n:nat} .<n>. (left: int(n),face: !SfntFace,run: !GlyphRun(0),i: int): int =
  if left = 0 then 0 else let val v=glyph_run_query(run,i)
    val cp=if ieq(i,2) then 65 else if ieq(i,5) then 0 else 65533
    val ok=ieq(v.core.scalar,cp) andalso ieq(v.core.glyph,sfnt_glyph(face,cp))
      andalso ieq(v.core.sourceStart,i) andalso ieq(v.core.sourceEnd,iadd(i,1)) andalso ieq(v.core.cluster,i)
  in iadd(if ok then 0 else 1,rows(left-1,face,run,iadd(i,1))) end
implement nominal_test_malformed(face,db) = let val b=fixture() val text=nominal_test_decode(b)
  val run=nominal_test_run(face,db,text)
  val errors=rows(7,face,run,0)
  val ok=ieq(scalar_count(text),7) andalso ieq(scalar_errors(text),5)
  val ()=glyph_run_dispose(run) and ()=scalar_dispose(text) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
