#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_load.sats"
staload "data_text/normalization/normalization_data.sats"
staload "data_text/normalization/normalization_engine.sats"
staload "font/glyph/core/glyph_nominal_contracts.sats"
staload "font/glyph/position/glyph_position_contracts.sats"
staload "font/opentype/tables/opentype_fixture.sats"
fun rows{n:nat} .<n>. (left: int(n),r: !GlyphRun(0),oracle: !Buf,i: int): int =
  if left = 0 then 0 else let val at=imul(i,8) and v=glyph_run_query(r,i)
    val ok=ieq(v.core.scalar,ot_fixture_read16(oracle,at)) andalso ieq(v.core.sourceStart,ot_fixture_read16(oracle,at+2))
      andalso ieq(v.core.sourceEnd,ot_fixture_read16(oracle,at+4)) andalso ieq(v.core.cluster,ot_fixture_read16(oracle,at+6))
  in iadd(if ok then 0 else 1,rows(left-1,r,oracle,iadd(i,1))) end
fun normalized(face: !SfntFace,db: !UnicodeDb,data: !NormalizationData,source: string,want: string,limit: int): int = let
  val b=nominal_test_bytes(source) val text=nominal_test_decode(b)
  val errors: int=case+ normalization_apply(data,text,NFC()) of | ~CannotNormalize(e) => 1
    | ~NormalizedText(view) => let
      val r=nominal_test_run(face,db,view) and oracle=ot_fixture_words(want)
      val count=idiv(isub(buf_len(oracle),8),8) and meta=glyph_run_meta(r)
      val e=iadd(rows(airlock_nat(count),r,oracle,0),if ieq(meta.live,count) andalso ieq(meta.sourceLength,limit) then 0 else 1)
      val ()=glyph_run_dispose(r) and ()=buf_free(oracle) and ()=scalar_dispose(view)
    in e end
  val ()=scalar_dispose(text) and ()=buf_free(b)
in errors end
fun face(path: string,db: !UnicodeDb,data: !NormalizationData): int = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let
    val e=normalized(f,db,data,"Ş İ","015E 0000 0003 0000 0020 0003 0004 0003 0130 0004 0007 0004",7)
      +normalized(f,db,data,"بَّ","0628 0000 0002 0000 064E 0004 0006 0000 0651 0002 0004 0000",6)
    val ()=sfnt_dispose(f)
  in e end
fun data(latin: string,arabic: string,db: !UnicodeDb,path: string): int = case+ normalization_load(path) of
  | ~NormalizationRejected(e) => 1 | ~NormalizationLoaded(n) => let
    val e=face(latin,db,n)+face(arabic,db,n) val ()=normalization_dispose(n)
  in e end
implement position_test_normalized(latin,arabic,unicode,normalization) = case+ unicode_load(unicode) of
  | ~UnicodeDataError() => 1 | ~UnicodeLoaded(db) => let val e=data(latin,arabic,db,normalization) val ()=unicode_dispose(db) in e end
