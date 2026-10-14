#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "data_text/word_types.sats"
staload "data_text/word_predicates.sats"
staload "data_text/word_rules.sats"

implement word_groups_join(state,k) = let val p = state.previous in
  (word_is_letter(p) andalso word_is_letter(k))
  orelse (word_is_numeric(p) andalso word_is_numeric(k))
  orelse (word_is_letter(p) andalso word_is_numeric(k))
  orelse (word_is_numeric(p) andalso word_is_letter(k))
  orelse (word_is_katakana(p) andalso word_is_katakana(k))
  orelse (word_is_extensible(p) andalso word_is_extendnum(k))
  orelse (word_is_extendnum(p) andalso word_is_extensible(k))
  orelse (word_is_hebrew(p) andalso word_is_single(k))
  orelse (word_is_regional(p) andalso word_is_regional(k) andalso ieq(imod(state.regional,2),1))
end

implement word_bridges_join(state,k,next) = let
  val p = state.previous
  val b = state.before
in (word_is_letter(p) andalso word_is_letter_bridge(k) andalso word_is_letter(next))
  orelse (word_is_letter(b) andalso word_is_letter_bridge(p) andalso word_is_letter(k))
  orelse (word_is_numeric(p) andalso word_is_number_bridge(k) andalso word_is_numeric(next))
  orelse (word_is_numeric(b) andalso word_is_number_bridge(p) andalso word_is_numeric(k))
  orelse (word_is_hebrew(p) andalso word_is_double(k) andalso word_is_hebrew(next))
  orelse (word_is_hebrew(b) andalso word_is_double(p) andalso word_is_hebrew(k)) end
