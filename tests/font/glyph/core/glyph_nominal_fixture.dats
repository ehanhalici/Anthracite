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
extern fun nominal_decode_failed(): ScalarText = "mac#anth_die_box"
extern fun nominal_run_failed(): GlyphRun(0) = "mac#anth_die_box"
fun copy{n:nat} .<n>. (left: int(n),source: string,b: !Buf,i: int): void = if left = 0 then () else let
  val ()=buf_set(b,i,c_str_byte(source,i))
in copy(left-1,source,b,iadd(i,1)) end
implement nominal_test_bytes(source) = let val length=c_strlen(source) val b=buf_make(length)
  val ()=copy(airlock_nat(length),source,b,0) val ()=buf_set_len(b,length)
in b end
implement nominal_test_decode(b) = case+ text_decode(b,buf_len(b)) of
  | ~InvalidTextSpan() => nominal_decode_failed() | ~DecodedText(text) => text
implement nominal_test_run(face,db,text) = case+ glyph_nominal_read(face,db,text,3,2147483663u) of
  | ~GlyphRunRejected(status) => nominal_run_failed() | ~GlyphRunCreated(run) => run
