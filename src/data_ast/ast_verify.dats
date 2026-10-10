#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/ast.sats"
staload "data_ast/doc.sats"
staload "data_ast/ast_verify.sats"

extern fun v_i1_exh(d: !Doc, i: int, n: int): bool = "mac#anth_die_int"

fun v_i1_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int): bool =
  if recfuel > 0 then (
    if i >= n then true
    else let
      val st = doc_node_start(d, i)
      val prev_ok = if i > 0 then st >= doc_node_start(d, isub(i, 1)) else true
      val p = doc_node_parent(d, i)
      val p_ok = if p >= 0 then p < i else true
    in
      if prev_ok andalso p_ok then v_i1_m(recfuel - 1, d, iadd(i, 1), n)
      else false
    end
  ) else v_i1_exh(d, i, n)

fun verify_i1(d: !Doc, n: int): bool = v_i1_m(airlock_nat(MAX_REC_FUEL), d, 0, n)

extern fun v_i2_exh(d: !Doc, i: int, n: int): bool = "mac#anth_die_int"

fun v_i2_node(d: !Doc, i: int, n: int): bool = let
  val p = doc_node_parent(d, i)
  val sub = doc_node_subend(d, i)
  val fc = doc_node_first_child(d, i)
  val sib = doc_node_next_sib(d, i)
  val p_ok = p < i andalso p >= ~1
  val sub_ok = sub > i andalso sub <= n
  val fc_ok = if sub = iadd(i, 1) then fc = ~1 else fc = iadd(i, 1)
  val sib_ok = if sib >= 0 then sib = sub andalso doc_node_parent(d, sib) = p else true
in
  p_ok andalso sub_ok andalso fc_ok andalso sib_ok
end

fun v_i2_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int): bool =
  if recfuel > 0 then (
    if i >= n then true
    else if v_i2_node(d, i, n) then v_i2_m(recfuel - 1, d, iadd(i, 1), n)
    else false
  ) else v_i2_exh(d, i, n)

fun verify_i2(d: !Doc, n: int): bool = v_i2_m(airlock_nat(MAX_REC_FUEL), d, 0, n)

extern fun v_i3_child_exh(d: !Doc, c: int, st: int, en: int, n: int): bool = "mac#anth_die_int"

fun v_i3_child_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, c: int, st: int, en: int, n: int
): bool =
  if recfuel > 0 then (
    if c < 0 orelse c >= n then true
    else let
      val c_st = doc_node_start(d, c)
      val c_en = doc_node_end(d, c)
      val in_bounds = c_st >= st andalso c_en <= en
      val next_c = doc_node_next_sib(d, c)
      val ord_ok = if next_c >= 0 andalso next_c < n then c_en <= doc_node_start(d, next_c) else true
    in
      if in_bounds andalso ord_ok then v_i3_child_m(recfuel - 1, d, next_c, st, en, n)
      else false
    end
  ) else v_i3_child_exh(d, c, st, en, n)

extern fun v_i3_exh(d: !Doc, i: int, n: int): bool = "mac#anth_die_int"

fun v_i3_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int): bool =
  if recfuel > 0 then (
    if i >= n then true
    else let
      val fc = doc_node_first_child(d, i)
      val st = doc_node_start(d, i)
      val en = doc_node_end(d, i)
      val c_ok = if fc >= 0 then v_i3_child_m(recfuel - 1, d, fc, st, en, n) else true
    in
      if c_ok then v_i3_m(recfuel - 1, d, iadd(i, 1), n)
      else false
    end
  ) else v_i3_exh(d, i, n)

fun verify_i3(d: !Doc, n: int): bool = v_i3_m(airlock_nat(MAX_REC_FUEL), d, 0, n)

extern fun v_i4_exh(d: !Doc, i: int, n: int, len: int): bool = "mac#anth_die_int"

fun v_i4_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int, len: int): bool =
  if recfuel > 0 then (
    if i >= n then true
    else let
      val st = doc_node_start(d, i)
      val en = doc_node_end(d, i)
    in
      if st >= 0 andalso st < en andalso en <= len then v_i4_m(recfuel - 1, d, iadd(i, 1), n, len)
      else false
    end
  ) else v_i4_exh(d, i, n, len)

fun verify_i4(d: !Doc, n: int, len: int): bool = v_i4_m(airlock_nat(MAX_REC_FUEL), d, 0, n, len)

fun is_gutter_byte(b: int): bool =
  b = 32 orelse b = 9 orelse b = 10 orelse b = 13 orelse b = 62

extern fun v_gap_exh(d: !Doc, p: int, end_p: int): bool = "mac#anth_die_int"

fun v_gap_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, end_p: int): bool =
  if recfuel > 0 then (
    if p >= end_p then true
    else if is_gutter_byte(doc_byte(d, p)) then v_gap_m(recfuel - 1, d, iadd(p, 1), end_p)
    else false
  ) else v_gap_exh(d, p, end_p)

extern fun v_i5_exh(d: !Doc, i: int, n: int): bool = "mac#anth_die_int"

fun v_i5_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int): bool =
  if recfuel > 0 then (
    if i >= n then true
    else let
      val sib = doc_node_next_sib(d, i)
      val gap_ok =
        if sib >= 0 andalso sib < n then
          v_gap_m(recfuel - 1, d, doc_node_end(d, i), doc_node_start(d, sib))
        else true
    in
      if gap_ok then v_i5_m(recfuel - 1, d, iadd(i, 1), n)
      else false
    end
  ) else v_i5_exh(d, i, n)

fun verify_i5(d: !Doc, n: int): bool = v_i5_m(airlock_nat(MAX_REC_FUEL), d, 0, n)

extern fun v_i6_exh(d: !Doc, i: int, n: int): bool = "mac#anth_die_int"

fun v_i6_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int): bool =
  if recfuel > 0 then (
    if i >= n then true
    else let
      val dp = doc_node_depth(d, i)
      val p = doc_node_parent(d, i)
      val dp_ok = if p < 0 then dp = 0 else dp = iadd(doc_node_depth(d, p), 1)
    in
      if dp_ok then v_i6_m(recfuel - 1, d, iadd(i, 1), n)
      else false
    end
  ) else v_i6_exh(d, i, n)

fun verify_i6(d: !Doc, n: int): bool = v_i6_m(airlock_nat(MAX_REC_FUEL), d, 0, n)

extern fun v_i7_exh(d: !Doc, i: int, n: int, max_dp: int): bool = "mac#anth_die_int"

fun v_i7_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int, max_dp: int): bool =
  if recfuel > 0 then (
    if i >= n then true
    else if doc_node_depth(d, i) <= max_dp then v_i7_m(recfuel - 1, d, iadd(i, 1), n, max_dp)
    else false
  ) else v_i7_exh(d, i, n, max_dp)

fun verify_i7(d: !Doc, n: int): bool =
  if n > MAX_NODES then false
  else v_i7_m(airlock_nat(MAX_REC_FUEL), d, 0, n, MAX_BLOCK_DEPTH + MAX_INLINE_DEPTH + 2)

fun h_level(k: NodeKind): int = case+ k of
  | KH1() => 1 | KH2() => 2 | KH3() => 3 | KH4() => 4 | KH5() => 5 | KH6() => 6
  | _ => 0

fun v_i8_check(d: !Doc, i: int): bool = let
  val k = doc_node_kind(d, i)
  val aux = doc_node_aux(d, i)
in
  if is_heading(k) then aux = h_level(k)
  else if is_kind(k, KCode) then aux >= 0
  else true
end

extern fun v_i8_exh(d: !Doc, i: int, n: int): bool = "mac#anth_die_int"

fun v_i8_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int): bool =
  if recfuel > 0 then (
    if i >= n then true
    else if v_i8_check(d, i) then v_i8_m(recfuel - 1, d, iadd(i, 1), n)
    else false
  ) else v_i8_exh(d, i, n)

fun verify_i8(d: !Doc, n: int): bool = v_i8_m(airlock_nat(MAX_REC_FUEL), d, 0, n)

implement ast_verify(d) = let
  val n = doc_nnodes(d)
  val len = doc_len(d)
in
  if n = 0 then 0
  else if not(verify_i1(d, n)) then 1
  else if not(verify_i2(d, n)) then 2
  else if not(verify_i3(d, n)) then 3
  else if not(verify_i4(d, n, len)) then 4
  else if not(verify_i5(d, n)) then 5
  else if not(verify_i6(d, n)) then 6
  else if not(verify_i7(d, n)) then 7
  else if not(verify_i8(d, n)) then 8
  else 0
end
