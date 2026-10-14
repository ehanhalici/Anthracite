#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_validation.sats"

implement normalization_header_read(bytes) =
  @{rows=buf_get32(bytes,2),mappings=buf_get32(bytes,3),pairs=buf_get32(bytes,4),expansion=buf_get32(bytes,5),depth=buf_get32(bytes,6)}

fun sizes_valid(bytes: !Buf, h: NormalizationHeader): bool = let
  val words = idiv(buf_len(bytes),4)
  val payload = isub(words,NORMALIZATION_HEADER_WORDS)
in if ile(h.rows,0) orelse ilt(h.mappings,0) orelse ilt(h.pairs,0)
    orelse igt(h.rows,idiv(payload,NORMALIZATION_ROW_WORDS)) then false else let
    val after_rows = isub(payload,imul(h.rows,NORMALIZATION_ROW_WORDS))
  in if igt(h.mappings,after_rows) then false else let
      val pair_words = isub(after_rows,h.mappings)
    in ieq(imod(pair_words,3),0) andalso ieq(h.pairs,idiv(pair_words,3)) end end end

implement normalization_header_valid(bytes,h) =
  ige(buf_len(bytes),imul(NORMALIZATION_HEADER_WORDS,4)) andalso ieq(imod(buf_len(bytes),4),0)
  andalso ieq(buf_get32(bytes,0),NORMALIZATION_MAGIC) andalso ieq(buf_get32(bytes,1),NORMALIZATION_VERSION)
  andalso ieq(buf_get32(bytes,7),0) andalso sizes_valid(bytes,h)
  andalso ige(h.depth,1) andalso ile(h.depth,iadd(h.rows,1))
  andalso ige(h.expansion,3) andalso ile(h.expansion,idiv(MAX_REC_FUEL,iadd(h.depth,1)))
