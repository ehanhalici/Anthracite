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
fun rows{n:nat} .<n>. (left: int(n),face: !SfntFace,run: !GlyphRun(0),expected: !Buf,i: int): int =
  if left = 0 then 0 else let
    val v=glyph_run_query(run,i) and at=imul(i,8)
    val cp=ot_fixture_read16(expected,at) and start=ot_fixture_read16(expected,at+2)
    val finish=ot_fixture_read16(expected,at+4) and cluster=ot_fixture_read16(expected,at+6)
    val found=case+ v.kind of | GlyphPresent() => true | GlyphMissing() => false
    val ok=found andalso ieq(v.core.scalar,cp) andalso ieq(v.core.glyph,sfnt_glyph(face,cp))
      andalso ieq(v.core.sourceStart,start) andalso ieq(v.core.sourceEnd,finish) andalso ieq(v.core.cluster,cluster)
      andalso g0uint_eq_uint(v.core.mask,2147483663u) andalso ieq(v.links.previous,isub(i,1))
      andalso ieq(v.links.next,if left = 1 then ~1 else iadd(i,1))
  in iadd(if ok then 0 else 1,rows(left-1,face,run,expected,iadd(i,1))) end
fun empty(face: !SfntFace,db: !UnicodeDb): int = let val b=nominal_test_bytes("")
  val text=nominal_test_decode(b) val run=nominal_test_run(face,db,text) val meta=glyph_run_meta(run)
  val ok=ieq(meta.used,0) andalso ieq(meta.live,0) andalso ieq(meta.sourceLength,0)
    andalso ieq(meta.head,~1) andalso ieq(meta.tail,~1) andalso ieq(glyph_run_capacity(run),0)
  val ()=glyph_run_dispose(run) and ()=scalar_dispose(text) and ()=buf_free(b)
in if ok then 0 else 1 end
implement nominal_test_mixed(face,db) = let
  val b=nominal_test_bytes("ıi̇ğشَّبَ") val text=nominal_test_decode(b) val run=nominal_test_run(face,db,text)
  val expected=ot_fixture_words("0131 0000 0002 0000 0069 0002 0003 0002 0307 0003 0005 0002 011F 0005 0007 0005 0634 0007 0009 0007 0651 0009 000B 0007 064E 000B 000D 0007 0628 000D 000F 000D 064E 000F 0011 000D")
  val errors=rows(9,face,run,expected,0)
  val meta=glyph_run_meta(run)
  val ok=ieq(meta.font,3) andalso ieq(meta.used,9) andalso ieq(meta.live,9) andalso ieq(meta.sourceLength,17)
    andalso ieq(meta.head,0) andalso ieq(meta.tail,8)
  val ()=glyph_run_dispose(run) and ()=scalar_dispose(text) and ()=buf_free(b) and ()=buf_free(expected)
in iadd(errors+empty(face,db),if ok then 0 else 1) end
