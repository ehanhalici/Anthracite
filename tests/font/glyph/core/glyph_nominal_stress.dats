#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/core/glyph_nominal.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/core/glyph_nominal_contracts.sats"
fun bytes{n:nat} .<n>. (left: int(n),b: !Buf,i: int): void = if left = 0 then () else let
  val at=imul(i,2)
  val ()=buf_set(b,at,if ieq(imod(i,2),0) then 216 else 217)
  val ()=buf_set(b,iadd(at,1),if ieq(imod(i,2),0) then 168 else 142)
in bytes(left-1,b,iadd(i,1)) end
fun rows{n:nat} .<n>. (left: int(n),face: !SfntFace,run: !GlyphRun(0),i: int,acc: int): int =
  if left = 0 then acc else let val v=glyph_run_query(run,i)
    val cp=if ieq(imod(i,2),0) then 1576 else 1614
    val ok=ieq(v.core.scalar,cp) andalso ieq(v.core.glyph,sfnt_glyph(face,cp))
      andalso ieq(v.core.sourceStart,imul(i,2)) andalso ieq(v.core.sourceEnd,imul(iadd(i,1),2))
      andalso ieq(v.core.cluster,imul(idiv(i,2),4)) andalso g0uint_eq_uint(v.core.mask,2147483663u)
  in rows(left-1,face,run,iadd(i,1),iadd(acc,if ok then 0 else 1)) end
implement nominal_test_stress(face,db) = let val b=buf_make(WORD16_MODULUS)
  val ()=bytes(WORD16_SIGN_BIT,b,0) and ()=buf_set_len(b,WORD16_MODULUS)
  val text=nominal_test_decode(b) val run=nominal_test_run(face,db,text)
  val errors=rows(WORD16_SIGN_BIT,face,run,0,0)
  val meta=glyph_run_meta(run)
  val ok=ieq(meta.live,WORD16_SIGN_BIT) andalso ieq(meta.used,WORD16_SIGN_BIT) andalso ieq(meta.sourceLength,WORD16_MODULUS)
  val ()=glyph_run_dispose(run) and ()=scalar_dispose(text) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
