#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_engine.sats"
staload "normalization_contracts.sats"
extern fun provenance_invalid_fixture(): ScalarText = "mac#anth_die_box"

fun fixture(value: string): ScalarText = let
  val size = c_strlen(value)
  var bytes = buf_make(iadd(size,1))
  val () = buf_append(bytes,c_str_ptr(value),size)
  val result = text_decode(bytes,size)
  val () = buf_free(bytes)
in case+ result of
  | ~DecodedText(text) => text | ~InvalidTextSpan() => provenance_invalid_fixture() end

fun value_span(text: !ScalarText, i: int, cp: int, start: int, finish: int): bool =
  ieq(scalar_value(text,i),cp) andalso ieq(scalar_start(text,i),start) andalso ieq(scalar_end(text,i),finish)

fun turkish_values(text: !ScalarText): bool =
  ieq(scalar_count(text),3) andalso value_span(text,0,350,0,3)
  andalso value_span(text,1,32,3,4) andalso value_span(text,2,304,4,7)

fun arabic_values(text: !ScalarText): bool =
  ieq(scalar_count(text),3) andalso value_span(text,0,1576,0,2)
  andalso value_span(text,1,1614,4,6) andalso value_span(text,2,1617,2,4)

fun turkish(data: !NormalizationData): int = let
  val source = fixture("Ş İ")
  val result = normalization_apply(data,source,NFC())
  val unchanged = ieq(scalar_count(source),5) andalso value_span(source,0,83,0,1)
  val () = scalar_dispose(source)
in case+ result of
  | ~CannotNormalize(error) => 1
  | ~NormalizedText(text) => let
      val valid = unchanged andalso turkish_values(text)
      val () = scalar_dispose(text)
    in if valid then 0 else 1 end end

fun arabic(data: !NormalizationData): int = let
  val source = fixture("بَّ")
  val result = normalization_apply(data,source,NFC())
  val () = scalar_dispose(source)
in case+ result of
  | ~CannotNormalize(error) => 1
  | ~NormalizedText(text) => let val valid = arabic_values(text) val () = scalar_dispose(text) in if valid then 0 else 1 end end

fun hangul(data: !NormalizationData): int = let
  val source = fixture("각")
  val result = normalization_apply(data,source,NFC())
  val () = scalar_dispose(source)
in case+ result of
  | ~CannotNormalize(error) => 1
  | ~NormalizedText(text) => let
      val valid = ieq(scalar_count(text),1) andalso value_span(text,0,44033,0,9)
      val () = scalar_dispose(text)
    in if valid then 0 else 1 end end

fun decomposed(data: !NormalizationData): int = let
  val source = fixture("Ş")
  val result = normalization_apply(data,source,NFD())
  val () = scalar_dispose(source)
in case+ result of
  | ~CannotNormalize(error) => 1
  | ~NormalizedText(text) => let
      val valid = ieq(scalar_count(text),2) andalso value_span(text,0,83,0,2) andalso value_span(text,1,807,0,2)
      val () = scalar_dispose(text)
    in if valid then 0 else 1 end end

fun long_bytes {n:nat} .<n>. (n: int(n), bytes: !Buf, i: int): void =
  if n = 0 then () else let
    val at = iadd(1,imul(i,2))
    val () = buf_set(bytes,at,204)
    val () = buf_set(bytes,iadd(at,1),if ieq(imod(i,2),0) then 149 else 128)
  in long_bytes(n-1,bytes,iadd(i,1)) end

fun long_fixture(): ScalarText = let
  val bytes = buf_make(65537)
  val () = buf_set(bytes,0,113)
  val () = long_bytes(32768,bytes,0)
  val result = text_decode(bytes,65537)
  val () = buf_free(bytes)
in case+ result of
  | ~DecodedText(text) => text | ~InvalidTextSpan() => provenance_invalid_fixture() end

fun long_values {n:nat} .<n>. (n: int(n), text: !ScalarText, i: int): int =
  if n = 0 then 0 else let
    val expected = if ile(i,16384) then 768 else 789
    val correct = ieq(scalar_value(text,i),expected)
  in iadd(if correct then 0 else 1,long_values(n-1,text,iadd(i,1))) end

fun long_marks(data: !NormalizationData): int = let
  val source = long_fixture()
  val result = normalization_apply(data,source,NFC())
  val () = scalar_dispose(source)
in case+ result of
  | ~CannotNormalize(error) => 1
  | ~NormalizedText(text) => let
      val valid = ieq(scalar_count(text),32769) andalso ieq(scalar_value(text,0),113)
      val errors = if valid then long_values(32768,text,1) else 1
      val () = scalar_dispose(text)
    in errors end end

implement normalization_provenance_contracts(data) =
  turkish(data) + arabic(data) + hangul(data) + decomposed(data) + long_marks(data)

