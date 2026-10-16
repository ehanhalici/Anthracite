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

(* LB19a needs both neighbors of each quote, not paragraph-wide heuristics. *)
fun east_quotes(c: LineContext): bool =
  (line_is_qu(c.right.kind) andalso not(c.left.facts.east andalso c.next.facts.east))
  orelse (line_is_qu(c.left.kind) andalso not(c.before.facts.east andalso c.right.facts.east))

(* LB19-LB20. CB remains an external object's optional break opportunity. *)
implement line_rules_quotes(c) = let val l=c.left.kind and r=c.right.kind in
  if line_is_qu(r) andalso not(c.right.facts.initial) then LineForbidden()
  else if line_is_qu(l) andalso not(c.left.facts.final) then LineForbidden()
  else if east_quotes(c) then LineForbidden()
  else if line_is_cb(l) orelse line_is_cb(r) then LineOptional()
  else LinePending() end
