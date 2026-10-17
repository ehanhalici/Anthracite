#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/word_break/word_types.sats"
staload "data_text/word_break/word_predicates.sats"
staload "data_text/word_break/word_rules.sats"

extern fun word_invalid_code(): WordKind = "mac#anth_die_box"

implement word_kind_of(code) = case+ code of
  | 0 => WOther() | 1 => WCR() | 2 => WLF() | 3 => WNewline()
  | 4 => WExtend() | 5 => WZWJ() | 6 => WRegional() | 7 => WFormat()
  | 8 => WKatakana() | 9 => WHebrew() | 10 => WLetter() | 11 => WSingle()
  | 12 => WDouble() | 13 => WMidNumLet() | 14 => WMidLetter() | 15 => WMidNum()
  | 16 => WNumeric() | 17 => WExtendNum() | 18 => WSpace()
  | _ => word_invalid_code()

implement word_initial() = @{raw=WMissing(),previous=WMissing(),before=WMissing(),regional=0}

fun boundary(db: !UnicodeDb, state: WordState, cp: int, k: WordKind, next: WordKind): bool =
  if word_is_missing(state.raw) then true
  else if word_is_cr(state.raw) andalso word_is_lf(k) then false
  else if word_is_newline(state.raw) orelse word_is_newline(k) then true
  else if word_is_zwj(state.raw) andalso unicode_pictographic(db,cp) then false
  else if word_is_space(state.raw) andalso word_is_space(k) then false
  else if word_is_ignored(k) then false
  else not(word_groups_join(state,k) orelse word_bridges_join(state,k,next))

fun advance(state: WordState, k: WordKind): WordState =
  if word_is_ignored(k) then
    @{raw=k,previous=state.previous,before=state.before,regional=state.regional}
  else @{raw=k,previous=k,before=state.previous,
    regional=if word_is_regional(k) then iadd(state.regional,1) else 0}

implement word_step(map,db,state,cp,next) = let
  val k = word_kind_of(property_value(map,cp))
  val stop = boundary(db,state,cp,k,next)
in @{boundary=stop,state=advance(state,k)} end
