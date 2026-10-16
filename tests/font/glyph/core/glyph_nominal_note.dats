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
staload "data_text/source/text_source.sats"
fun rows{n:nat} .<n>. (left: int(n),run: !GlyphRun(0),text: !ScalarText,i: int,
  missing: &int >> _,clusters: &int >> _): int = if left = 0 then 0 else let
    val v=glyph_run_query(run,i)
    val ()=if ieq(v.core.glyph,0) then missing := missing+1 else ()
    val ()=if ieq(v.core.cluster,v.core.sourceStart) then clusters := clusters+1 else ()
    val ok=ieq(v.core.scalar,scalar_value(text,i)) andalso ieq(v.core.sourceStart,scalar_start(text,i))
      andalso ieq(v.core.sourceEnd,scalar_end(text,i)) andalso g0uint_eq_uint(v.core.mask,2147483663u)
  in iadd(if ok then 0 else 1,rows(left-1,run,text,iadd(i,1),missing,clusters)) end
fun inspect(face: !SfntFace,db: !UnicodeDb,text: !ScalarText,length: int): int = let
  val run=nominal_test_run(face,db,text) val count=scalar_count(text)
  var missing: int=0 and clusters: int=0
  val source_errors=rows(airlock_nat(count),run,text,0,missing,clusters)
  val malformed=scalar_errors(text)
  val meta=glyph_run_meta(run)
  val ok=ieq(meta.live,count) andalso ieq(meta.used,count) andalso ieq(meta.sourceLength,length)
  val ()=println!("event=glyph_nominal_note scalars=",count," malformed=",malformed,
    " grapheme_clusters=",clusters," nominal_notdef=",missing," glyph_domain=",meta.glyphs," source_errors=",source_errors)
  val ()=glyph_run_dispose(run)
in iadd(source_errors+malformed,if ok then 0 else 1) end
implement nominal_test_file(face,db,path) = case+ text_file_read(path) of
  | ~TextFileError(code) => let val ()=println!("event=glyph_nominal_note io_status=",code) in 1 end
  | ~TextFile(b) => let
    val text=nominal_test_decode(b)
    val errors=inspect(face,db,text,buf_len(b))
    val ()=scalar_dispose(text) and ()=buf_free(b)
  in errors end
