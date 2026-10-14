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

fun initial_quote(c: LineContext): bool =
  line_is_qu(c.anchor.kind) andalso c.anchor.facts.initial
  andalso line_is_initial_context(c.beforeAnchor.kind)

fun final_quote(c: LineContext): bool =
  line_is_qu(c.right.kind) andalso c.right.facts.final
  andalso line_is_final_context(c.next.kind)

(* LB13-LB18, in normative order, including decimal exception LB15c. *)
implement line_rules_punctuation(c) = let val l=c.left.kind and r=c.right.kind in
  if line_is_close(r) orelse line_is_ex(r) orelse line_is_sy(r) then LineForbidden()
  else if line_is_op(c.anchor.kind) then LineForbidden()
  else if initial_quote(c) orelse final_quote(c) then LineForbidden()
  else if line_is_sp(l) andalso line_is_is(r) andalso line_is_nu(c.next.kind) then LineOptional()
  else if line_is_is(r) then LineForbidden()
  else if line_is_close(c.anchor.kind) andalso line_is_ns(r) then LineForbidden()
  else if line_is_b2(c.anchor.kind) andalso line_is_b2(r) then LineForbidden()
  else if line_is_sp(l) then LineOptional()
  else LinePending() end
