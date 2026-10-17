#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/utf8/utf8_work.sats"
fun decode_owned(source: !Buf,length: int,m: Utf8Measure): ScalarText = let
  val size=imul(m.count,4)
  val values=buf_make(size)
  val starts=buf_make(size)
  val ends=buf_make(size)
  val ()=utf8_store(source,length,values,starts,ends,m.count)
in ScalarText(values,starts,ends,m.count,m.errors) end
implement text_decode(source,length) =
  if ilt(length,0) orelse igt(length,buf_cap(source)) orelse igt(length,MAX_REC_FUEL)
  then InvalidTextSpan()
  else DecodedText(decode_owned(source,length,utf8_measure(source,length)))
