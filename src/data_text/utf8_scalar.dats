#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"

implement scalar_count(text) = let val+ ScalarText(values,starts,ends,count,errors)=text in count end
implement scalar_errors(text) = let val+ ScalarText(values,starts,ends,count,errors)=text in errors end
implement scalar_value(text,index) = let val+ ScalarText(values,starts,ends,count,errors)=text in
  buf_get32(values,index) end
implement scalar_start(text,index) = let val+ ScalarText(values,starts,ends,count,errors)=text in
  buf_get32(starts,index) end
implement scalar_end(text,index) = let val+ ScalarText(values,starts,ends,count,errors)=text in
  buf_get32(ends,index) end
implement scalar_dispose(text) = let
  val+ ~ScalarText(values,starts,ends,count,errors)=text
  val ()=buf_free(values) and ()=buf_free(starts)
in buf_free(ends) end

