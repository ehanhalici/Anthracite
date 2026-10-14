#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_types.sats"
staload "data_text/line_predicates.sats"
staload "data_text/line_groups.sats"
staload "data_text/line_rules.sats"

fun hyphen_join(c: LineContext): bool =
  (line_is_word_start(c.before.kind) andalso line_is_hyphen(c.left.kind)
    andalso line_is_letter(c.right.kind))
  orelse (line_is_hl(c.before.kind) andalso line_is_hyphen(c.left.kind)
    andalso not(line_is_hl(c.right.kind)))

fun alphanumeric(l: LineClass,r: LineClass): bool =
  (line_is_letter(l) andalso line_is_nu(r)) orelse (line_is_nu(l) andalso line_is_letter(r))

fun affixed(l: LineClass,r: LineClass): bool =
  (line_is_pr(l) andalso line_is_ideograph(r))
  orelse (line_is_ideograph(l) andalso line_is_po(r))
  orelse (line_is_prefix(l) andalso line_is_letter(r))
  orelse (line_is_letter(l) andalso line_is_prefix(r))

(* LB20a-LB24. *)
implement line_rules_words(c) = let val l=c.left.kind and r=c.right.kind in
  if hyphen_join(c) then LineForbidden()
  else if line_is_ba(r) orelse line_is_hyphen(r) orelse line_is_ns(r) orelse line_is_bb(l) then LineForbidden()
  else if line_is_sy(l) andalso line_is_hl(r) then LineForbidden()
  else if line_is_in(r) then LineForbidden()
  else if alphanumeric(l,r) orelse affixed(l,r) then LineForbidden()
  else LinePending() end
