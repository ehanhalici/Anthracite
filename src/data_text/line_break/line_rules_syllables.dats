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

fun brahmic_join(c: LineContext): bool =
  (line_is_ap(c.left.kind) andalso line_is_brahmic(c.right))
  orelse (line_is_brahmic(c.left) andalso (line_is_vf(c.right.kind) orelse line_is_vi(c.right.kind)))
  orelse (line_is_brahmic(c.before) andalso line_is_vi(c.left.kind) andalso line_is_brahmic_base(c.right))
  orelse (line_is_brahmic(c.left) andalso line_is_brahmic(c.right) andalso line_is_vf(c.next.kind))

fun ordinary_parentheses(c: LineContext): bool =
  ((line_is_letter(c.left.kind) orelse line_is_nu(c.left.kind)) andalso
    line_is_op(c.right.kind) andalso not(c.right.facts.east))
  orelse (line_is_cp(c.left.kind) andalso not(c.left.facts.east) andalso
    (line_is_letter(c.right.kind) orelse line_is_nu(c.right.kind)))

(* LB28a-LB30. Dotted circle participates independently of its AL class. *)
implement line_rules_syllables(c) =
  if brahmic_join(c) then LineForbidden()
  else if line_is_is(c.left.kind) andalso line_is_letter(c.right.kind) then LineForbidden()
  else if ordinary_parentheses(c) then LineForbidden()
  else LinePending()

(* LB30a-LB31. Combining marks do not count as extra regional indicators. *)
implement line_rules_final(c) =
  if line_is_ri(c.left.kind) andalso line_is_ri(c.right.kind)
    andalso ieq(imod(c.state.regional,2),1) then LineForbidden()
  else if (line_is_eb(c.left.kind) orelse c.left.facts.potential) andalso line_is_em(c.right.kind)
    then LineForbidden()
  else LineOptional()
