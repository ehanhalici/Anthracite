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

(* LB4-LB8a. LB9-LB10 are implemented by the token builder. *)
implement line_rules_hard(c) = let val l=c.left.kind and r=c.right.kind in
  if line_is_bk(l) then LineMandatory()
  else if line_is_cr(l) andalso line_is_lf(r) then LineForbidden()
  else if line_is_hard(l) then LineMandatory()
  else if line_is_hard(r) then LineForbidden()
  else if line_is_sp(r) orelse line_is_zw(r) then LineForbidden()
  else if line_is_zw(c.anchor.kind) then LineOptional()
  else if c.left.zwj then LineForbidden()
  else LinePending() end

(* LB11-LB12a. *)
implement line_rules_glue(c) = let val l=c.left.kind and r=c.right.kind in
  if line_is_wj(l) orelse line_is_wj(r) orelse line_is_gl(l) then LineForbidden()
  else if line_is_gl(r) andalso not(line_is_sp(l) orelse line_is_hyphen(l)) then LineForbidden()
  else LinePending() end
