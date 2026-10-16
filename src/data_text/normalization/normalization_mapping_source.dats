#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_draft.sats"
staload "data_text/normalization/normalization_source.sats"

fun known_tag(source: !Buf, start: int, finish: int): bool =
  text_token_is(source,start,finish,"font") orelse text_token_is(source,start,finish,"noBreak")
  orelse text_token_is(source,start,finish,"initial") orelse text_token_is(source,start,finish,"medial")
  orelse text_token_is(source,start,finish,"final") orelse text_token_is(source,start,finish,"isolated")
  orelse text_token_is(source,start,finish,"circle") orelse text_token_is(source,start,finish,"super")
  orelse text_token_is(source,start,finish,"sub") orelse text_token_is(source,start,finish,"vertical")
  orelse text_token_is(source,start,finish,"wide") orelse text_token_is(source,start,finish,"narrow")
  orelse text_token_is(source,start,finish,"small") orelse text_token_is(source,start,finish,"square")
  orelse text_token_is(source,start,finish,"fraction") orelse text_token_is(source,start,finish,"compat")

implement normalization_mapping_header(source,start,finish) =
  if ieq(start,finish) then @{kind=NoMapping(),start=start,valid=true}
  else if ine(buf_get(source,start),CHAR_LT) then @{kind=CanonicalMapping(),start=start,valid=true}
  else let
    val closing = text_find_byte(source,iadd(start,1),finish,62)
    val valid = ilt(closing,finish) andalso known_tag(source,iadd(start,1),closing)
    val mapped = text_skip_space(source,iadd(closing,1),finish)
  in @{kind=CompatibilityMapping(),start=mapped,valid=valid andalso ilt(mapped,finish)} end
