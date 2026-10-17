#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_engine.sats"
staload "text/utf8/scalar_fixture.sats"
staload "text/normalization/normalization_fixture.sats"

implement normalization_fixture_columns(source,start,finish) = let
  val c1 = scalar_fixture_column(source,start,finish,0)
  val c2 = scalar_fixture_column(source,start,finish,1)
  val c3 = scalar_fixture_column(source,start,finish,2)
  val c4 = scalar_fixture_column(source,start,finish,3)
  val c5 = scalar_fixture_column(source,start,finish,4)
in NormalizationColumns(c1,c2,c3,c4,c5) end

implement normalization_fixture_dispose(columns) = let
  val+ ~NormalizationColumns(c1,c2,c3,c4,c5) = columns
  val () = scalar_dispose(c1)
  val () = scalar_dispose(c2)
  val () = scalar_dispose(c3)
  val () = scalar_dispose(c4)
in scalar_dispose(c5) end

fun check(data: !NormalizationData, input: !ScalarText, expected: !ScalarText, form: NormalizationForm): int =
  case+ normalization_apply(data,input,form) of
  | ~CannotNormalize(error) => 1
  | ~NormalizedText(actual) => let
      val errors = scalar_fixture_differences(actual,expected)
      val () = scalar_dispose(actual)
    in errors end

fun check_same(data: !NormalizationData, input: !ScalarText, form: NormalizationForm): int =
  case+ normalization_apply(data,input,form) of
  | ~CannotNormalize(error) => 1
  | ~NormalizedText(actual) => let
      val errors = scalar_fixture_differences(actual,input)
      val () = scalar_dispose(actual)
    in errors end

fun nfc(data: !NormalizationData, columns: !NormalizationColumns): int = let
  val+ NormalizationColumns(c1,c2,c3,c4,c5) = columns
in check(data,c1,c2,NFC()) + check_same(data,c2,NFC()) + check(data,c3,c2,NFC())
  + check_same(data,c4,NFC()) + check(data,c5,c4,NFC()) end

fun nfd(data: !NormalizationData, columns: !NormalizationColumns): int = let
  val+ NormalizationColumns(c1,c2,c3,c4,c5) = columns
in check(data,c1,c3,NFD()) + check(data,c2,c3,NFD()) + check_same(data,c3,NFD())
  + check(data,c4,c5,NFD()) + check_same(data,c5,NFD()) end

fun nfkc(data: !NormalizationData, columns: !NormalizationColumns): int = let
  val+ NormalizationColumns(c1,c2,c3,c4,c5) = columns
in check(data,c1,c4,NFKC()) + check(data,c2,c4,NFKC()) + check(data,c3,c4,NFKC())
  + check_same(data,c4,NFKC()) + check(data,c5,c4,NFKC()) end

fun nfkd(data: !NormalizationData, columns: !NormalizationColumns): int = let
  val+ NormalizationColumns(c1,c2,c3,c4,c5) = columns
in check(data,c1,c5,NFKD()) + check(data,c2,c5,NFKD()) + check(data,c3,c5,NFKD())
  + check(data,c4,c5,NFKD()) + check_same(data,c5,NFKD()) end

implement normalization_fixture_test(data,columns) =
  nfc(data,columns) + nfd(data,columns) + nfkc(data,columns) + nfkd(data,columns)

fun mark_character(columns: !NormalizationColumns, mask: !Buf): void = let
  val+ NormalizationColumns(c1,c2,c3,c4,c5) = columns
in buf_set(mask,scalar_value(c1,0),1) end

implement normalization_fixture_mark(columns,mask,part) = case+ part of
  | CharacterPart() => mark_character(columns,mask)
  | SpecificPart() => () | CanonicalPart() => () | CompatibilityPart() => ()
  | ClosurePart() => () | CompositePart() => ()
