#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_text/source/text_source.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/property_symbols.sats"
staload "data_text/line_break/line_property_symbols.sats"

fun word_of(b: !Buf, p: int, en: int): int =
  if text_token_is(b,p,en,"Other") then 0
  else if text_token_is(b,p,en,"CR") then 1 else if text_token_is(b,p,en,"LF") then 2
  else if text_token_is(b,p,en,"Newline") then 3 else if text_token_is(b,p,en,"Extend") then 4
  else if text_token_is(b,p,en,"ZWJ") then 5 else if text_token_is(b,p,en,"Regional_Indicator") then 6
  else if text_token_is(b,p,en,"Format") then 7 else if text_token_is(b,p,en,"Katakana") then 8
  else if text_token_is(b,p,en,"Hebrew_Letter") then 9 else if text_token_is(b,p,en,"ALetter") then 10
  else if text_token_is(b,p,en,"Single_Quote") then 11 else if text_token_is(b,p,en,"Double_Quote") then 12
  else if text_token_is(b,p,en,"MidNumLet") then 13 else if text_token_is(b,p,en,"MidLetter") then 14
  else if text_token_is(b,p,en,"MidNum") then 15 else if text_token_is(b,p,en,"Numeric") then 16
  else if text_token_is(b,p,en,"ExtendNumLet") then 17 else if text_token_is(b,p,en,"WSegSpace") then 18
  else ~1

fun bidi_controls_of(b: !Buf, p: int, en: int): int =
  if text_token_is(b,p,en,"LRE") then 12 else if text_token_is(b,p,en,"LRO") then 13
  else if text_token_is(b,p,en,"RLE") then 14 else if text_token_is(b,p,en,"RLO") then 15
  else if text_token_is(b,p,en,"PDF") then 16 else if text_token_is(b,p,en,"NSM") then 17
  else if text_token_is(b,p,en,"BN") then 18 else if text_token_is(b,p,en,"FSI") then 19
  else if text_token_is(b,p,en,"LRI") then 20 else if text_token_is(b,p,en,"RLI") then 21
  else if text_token_is(b,p,en,"PDI") then 22 else ~1

fun bidi_of(b: !Buf, p: int, en: int): int =
  if text_token_is(b,p,en,"L") orelse text_token_is(b,p,en,"Left_To_Right") then 0
  else if text_token_is(b,p,en,"R") orelse text_token_is(b,p,en,"Right_To_Left") then 1
  else if text_token_is(b,p,en,"AL") orelse text_token_is(b,p,en,"Arabic_Letter") then 2
  else if text_token_is(b,p,en,"EN") then 3 else if text_token_is(b,p,en,"ES") then 4
  else if text_token_is(b,p,en,"ET") orelse text_token_is(b,p,en,"European_Terminator") then 5
  else if text_token_is(b,p,en,"AN") then 6 else if text_token_is(b,p,en,"CS") then 7
  else if text_token_is(b,p,en,"B") then 8 else if text_token_is(b,p,en,"S") then 9
  else if text_token_is(b,p,en,"WS") then 10 else if text_token_is(b,p,en,"ON") then 11
  else bidi_controls_of(b,p,en)

fun joining_of(b: !Buf, p: int, en: int): int =
  if text_token_is(b,p,en,"U") orelse text_token_is(b,p,en,"Non_Joining") then 0
  else if text_token_is(b,p,en,"R") then 1 else if text_token_is(b,p,en,"L") then 2
  else if text_token_is(b,p,en,"D") then 3 else if text_token_is(b,p,en,"C") then 4
  else if text_token_is(b,p,en,"T") then 5 else ~1

implement property_symbol_of(domain,b,p,en) = case+ domain of
  | WordProperty() => word_of(b,p,en) | BidiProperty() => bidi_of(b,p,en)
  | JoiningProperty() => joining_of(b,p,en)
  | LineProperty() => line_symbol_of(b,p,en)
  | EastAsianProperty() => east_asian_symbol_of(b,p,en)
  | CategoryProperty() => category_symbol_of(b,p,en)
  | ScriptProperty() => ~1
  | IgnorableProperty() => if text_token_is(b,p,en,"Default_Ignorable_Code_Point") then 1 else ~1
  | ModifierMarkProperty() => if text_token_is(b,p,en,"Modifier_Combining_Mark") then 1 else ~1
