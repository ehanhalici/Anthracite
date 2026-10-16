#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/line_break/line_predicates.sats"
staload "data_text/line_break/line_groups.sats"
staload "data_text/line_break/line_rules.sats"

fun prefixed_number(c: LineContext): bool =
  line_is_prefix(c.left.kind) andalso
    (line_is_nu(c.right.kind) orelse (line_is_op(c.right.kind) andalso
      (line_is_nu(c.next.kind) orelse (line_is_is(c.next.kind) andalso line_is_nu(c.next2.kind)))))

fun continued_number(c: LineContext): bool =
  (c.state.numeric andalso (line_is_prefix(c.right.kind) orelse line_is_nu(c.right.kind)))
  orelse (line_is_close(c.left.kind) andalso c.state.beforeNumeric andalso line_is_prefix(c.right.kind))
  orelse ((line_is_hy(c.left.kind) orelse line_is_is(c.left.kind)) andalso line_is_nu(c.right.kind))

fun korean_join(l: LineClass,r: LineClass): bool =
  (line_is_jl(l) andalso (line_is_jl(r) orelse line_is_jv(r) orelse line_is_h2(r) orelse line_is_h3(r)))
  orelse ((line_is_jv(l) orelse line_is_h2(l)) andalso (line_is_jv(r) orelse line_is_jt(r)))
  orelse ((line_is_jt(l) orelse line_is_h3(l)) andalso line_is_jt(r))
  orelse (line_is_hangul(l) andalso line_is_po(r))
  orelse (line_is_pr(l) andalso line_is_hangul(r))

(* LB25-LB28. Numeric prefix context is carried in O(1) FSM state. *)
implement line_rules_numbers(c) = let val l=c.left.kind and r=c.right.kind in
  if prefixed_number(c) orelse continued_number(c) then LineForbidden()
  else if korean_join(l,r) then LineForbidden()
  else if line_is_letter(l) andalso line_is_letter(r) then LineForbidden()
  else LinePending() end
