#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_text/word_types.sats"
staload "data_text/word_predicates.sats"

implement word_is_missing(k) = case+ k of
  | WMissing() => true | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_cr(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => true | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_lf(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => true
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_newline(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => true | WLF() => true
  | WNewline() => true | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_ignored(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => true | WZWJ() => true | WRegional() => false
  | WFormat() => true | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_zwj(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => true | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_space(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => true

implement word_is_letter(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => true | WLetter() => true
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_hebrew(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => true | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_numeric(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => true | WExtendNum() => false | WSpace() => false

implement word_is_katakana(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => true | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_extendnum(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => true | WSpace() => false

implement word_is_extensible(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => true | WHebrew() => true | WLetter() => true
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => true | WExtendNum() => true | WSpace() => false

implement word_is_regional(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => true
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_single(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => true | WDouble() => false | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_double(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => false | WDouble() => true | WMidNumLet() => false | WMidLetter() => false
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_letter_bridge(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => true | WDouble() => false | WMidNumLet() => true | WMidLetter() => true
  | WMidNum() => false | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_is_number_bridge(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => true | WDouble() => false | WMidNumLet() => true | WMidLetter() => false
  | WMidNum() => true | WNumeric() => false | WExtendNum() => false | WSpace() => false

implement word_needs_future(k) = case+ k of
  | WMissing() => false | WOther() => false | WCR() => false | WLF() => false
  | WNewline() => false | WExtend() => false | WZWJ() => false | WRegional() => false
  | WFormat() => false | WKatakana() => false | WHebrew() => false | WLetter() => false
  | WSingle() => true | WDouble() => true | WMidNumLet() => true | WMidLetter() => true
  | WMidNum() => true | WNumeric() => false | WExtendNum() => false | WSpace() => false
