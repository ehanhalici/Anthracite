#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "data_ast/document/doc.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/tabs/ui_tab_history.sats"

fun th_clone_buf(src: !Buf): Buf = let
  val n = buf_len(src)
  var dst = buf_make(imax(4, iadd(n, 4)))
  val () = buffer_append_range(dst, src, 0, n)
in
  dst
end

extern fun he_free_exhausted(es: HistEntryList): void = "mac#anth_die_void"
extern fun th_free_exhausted(hl: TabHistList): void = "mac#anth_die_void"

fun he_free_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), es: HistEntryList): void =
  if recursion_fuel_available(recfuel) then (
    case+ es of
    | ~HENil() => ()
    | ~HECons(p, _, _, rest) => (buf_free(p); he_free_m(recfuel - 1, rest))
  ) else he_free_exhausted(es)

fun he_free(es: HistEntryList): void = he_free_m(airlock_nat(MAX_REC_FUEL), es)

fun th_free_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hl: TabHistList): void =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | ~THNil() => ()
    | ~THCons(es, _, rest) => (he_free(es); th_free_m(recfuel - 1, rest))
  ) else th_free_exhausted(hl)

implement tab_hist_free(hl) = th_free_m(airlock_nat(MAX_REC_FUEL), hl)

extern fun he_len_exhausted(es: !HistEntryList): int = "mac#anth_die_int"
extern fun th_len_exhausted(hl: !TabHistList): int = "mac#anth_die_int"
extern fun he_clone_exhausted(es: !HistEntryList): HistEntryList = "mac#anth_die_box"
extern fun he_append_exhausted(es: HistEntryList, p: Buf): HistEntryList = "mac#anth_die_box"
extern fun he_trunc_after_exhausted(es: HistEntryList): HistEntryList = "mac#anth_die_box"
extern fun he_update_at_exhausted(es: HistEntryList, p: !Buf): HistEntryList = "mac#anth_die_box"
extern fun he_get_at_exhausted(es: !HistEntryList): bool = "mac#anth_die_int"
extern fun th_append_exhausted(hl: TabHistList, es: HistEntryList): TabHistList = "mac#anth_die_box"
extern fun th_drop_exhausted(hl: TabHistList): TabHistList = "mac#anth_die_box"

fun he_len_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), es: !HistEntryList): int =
  if recursion_fuel_available(recfuel) then (
    case+ es of
    | HENil() => 0
    | HECons(_, _, _, rest) => iadd(1, he_len_m(recfuel - 1, rest))
  ) else he_len_exhausted(es)

fun he_len(es: !HistEntryList): int = he_len_m(airlock_nat(MAX_REC_FUEL), es)

fun th_len_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hl: !TabHistList): int =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | THNil() => 0
    | THCons(_, _, rest) => iadd(1, th_len_m(recfuel - 1, rest))
  ) else th_len_exhausted(hl)

implement tab_hist_len(hl) = th_len_m(airlock_nat(MAX_REC_FUEL), hl)

fun he_clone_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), es: !HistEntryList): HistEntryList =
  if recursion_fuel_available(recfuel) then (
    case+ es of
    | HENil() => HENil()
    | HECons(p, sc, c, rest) => HECons(th_clone_buf(p), sc, c, he_clone_m(recfuel - 1, rest))
  ) else he_clone_exhausted(es)

fun he_append_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), es: HistEntryList, p: Buf, sc: int, c: int
): HistEntryList =
  if recursion_fuel_available(recfuel) then (
    case+ es of
    | ~HENil() => HECons(p, sc, c, HENil())
    | ~HECons(ep, esc, ec, rest) => HECons(ep, esc, ec, he_append_m(recfuel - 1, rest, p, sc, c))
  ) else he_append_exhausted(es, p)

fun he_trunc_after_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), es: HistEntryList, keep_idx: int
): HistEntryList =
  if recursion_fuel_available(recfuel) then (
    case+ es of
    | ~HENil() => HENil()
    | ~HECons(p, sc, c, rest) =>
        if ile(keep_idx, 0) then (he_free(rest); HECons(p, sc, c, HENil()))
        else HECons(p, sc, c, he_trunc_after_m(recfuel - 1, rest, isub(keep_idx, 1)))
  ) else he_trunc_after_exhausted(es)

fun he_update_at_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), es: HistEntryList, i: int, p: !Buf, sc: int, c: int
): HistEntryList =
  if recursion_fuel_available(recfuel) then (
    case+ es of
    | ~HENil() => HENil()
    | ~HECons(ep, esc, ec, rest) =>
        if ieq(i, 0) then let
          val () = seen_int(esc); val () = seen_int(ec)
        in
          if igt(buf_len(p), 0) then (buf_free(ep); HECons(th_clone_buf(p), sc, c, rest))
          else HECons(ep, sc, c, rest)
        end else HECons(ep, esc, ec, he_update_at_m(recfuel - 1, rest, isub(i, 1), p, sc, c))
  ) else he_update_at_exhausted(es, p)

fun he_get_at_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), es: !HistEntryList, i: int,
  out_p: &Buf >> _, out_sc: &int >> _, out_c: &int >> _
): bool =
  if recursion_fuel_available(recfuel) then (
    case+ es of
    | HENil() => false
    | HECons(ep, esc, ec, rest) =>
        if ieq(i, 0) then (
          buffer_clear(out_p);
          buffer_append_all(out_p, ep);
          out_sc := esc; out_c := ec; true
        ) else he_get_at_m(recfuel - 1, rest, isub(i, 1), out_p, out_sc, out_c)
  ) else he_get_at_exhausted(es)

fun th_append_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), hl: TabHistList, es: HistEntryList, cur: int
): TabHistList =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | ~THNil() => THCons(es, cur, THNil())
    | ~THCons(e, c, rest) => THCons(e, c, th_append_m(recfuel - 1, rest, es, cur))
  ) else th_append_exhausted(hl, es)

implement tab_hist_add(hl, path, sc, caret) = let
  val es = HECons(th_clone_buf(path), sc, caret, HENil())
in
  th_append_m(airlock_nat(MAX_REC_FUEL), hl, es, 0)
end

fun th_drop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hl: TabHistList, idx: int): TabHistList =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | ~THNil() => THNil()
    | ~THCons(es, c, rest) =>
        if ieq(idx, 0) then (he_free(es); rest)
        else THCons(es, c, th_drop_m(recfuel - 1, rest, isub(idx, 1)))
  ) else th_drop_exhausted(hl)

implement tab_hist_drop(hl, idx) = th_drop_m(airlock_nat(MAX_REC_FUEL), hl, idx)

datavtype THPair = THPAIR of (TabHistList, TabHistList)

extern fun th_detach_exhausted(hl: TabHistList): THPair = "mac#anth_die_box"
extern fun th_insert_exhausted(hl: TabHistList, one: TabHistList): TabHistList = "mac#anth_die_box"
extern fun th_clone_exhausted(hl: TabHistList): TabHistList = "mac#anth_die_box"
extern fun th_sync_exhausted(hl: TabHistList): TabHistList = "mac#anth_die_box"
extern fun th_can_back_exhausted(hl: !TabHistList): bool = "mac#anth_die_int"
extern fun th_can_fwd_exhausted(hl: !TabHistList): bool = "mac#anth_die_int"

fun th_detach_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hl: TabHistList, i: int): THPair =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | ~THNil() => THPAIR(THNil(), THNil())
    | ~THCons(es, c, rest) =>
        if ieq(i, 0) then THPAIR(THCons(es, c, THNil()), rest)
        else let
          val+ ~THPAIR(one, tail) = th_detach_m(recfuel - 1, rest, isub(i, 1))
        in
          THPAIR(one, THCons(es, c, tail))
        end
  ) else th_detach_exhausted(hl)

fun th_link(one: TabHistList, hl: TabHistList): TabHistList =
  case+ one of
  | ~THNil() => hl
  | ~THCons(es, c, rest) => (tab_hist_free(rest); THCons(es, c, hl))

fun th_insert_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), hl: TabHistList, i: int, one: TabHistList
): TabHistList =
  if recursion_fuel_available(recfuel) then (
    if ieq(i, 0) then th_link(one, hl)
    else case+ hl of
      | ~THNil() => one
      | ~THCons(es, c, rest) => THCons(es, c, th_insert_m(recfuel - 1, rest, isub(i, 1), one))
  ) else th_insert_exhausted(hl, one)

implement tab_hist_move(hl, from_i, to_i) =
  if ieq(from_i, to_i) then hl
  else let val n = tab_hist_len(hl) in
    if ige(from_i, 0) andalso ilt(from_i, n) andalso ige(to_i, 0) andalso ilt(to_i, n) then let
      val+ ~THPAIR(one, rest) = th_detach_m(airlock_nat(MAX_REC_FUEL), hl, from_i)
    in
      th_insert_m(airlock_nat(MAX_REC_FUEL), rest, to_i, one)
    end else hl
  end

fun th_clone_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), hl: TabHistList, idx: int
): TabHistList =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | ~THNil() => THNil()
    | ~THCons(es, c, rest) =>
        if ieq(idx, 0) then let
          val es2 = he_clone_m(airlock_nat(MAX_REC_FUEL), es)
          val rest2 = th_append_m(airlock_nat(MAX_REC_FUEL), rest, es2, c)
        in
          THCons(es, c, rest2)
        end else THCons(es, c, th_clone_m(recfuel - 1, rest, isub(idx, 1)))
  ) else th_clone_exhausted(hl)

implement tab_hist_clone(hl, idx) = th_clone_m(airlock_nat(MAX_REC_FUEL), hl, idx)

fun th_sync_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), hl: TabHistList, ts: !Tabs
): TabHistList =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => (tab_hist_free(hl); THNil())
    | TCons(doc, path, _, sc, trest) => (
        case+ hl of
        | ~THNil() => let
            val es = HECons(th_clone_buf(path), sc, doc_caret(doc), HENil())
          in
            THCons(es, 0, th_sync_m(recfuel - 1, THNil(), trest))
          end
        | ~THCons(es, c, hrest) =>
            THCons(es, c, th_sync_m(recfuel - 1, hrest, trest))
      )
  ) else th_sync_exhausted(hl)

implement tab_hist_sync(hl, ts) = th_sync_m(airlock_nat(MAX_REC_FUEL), hl, ts)

fun th_can_back_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hl: !TabHistList, idx: int): bool =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | THNil() => false
    | THCons(_, c, rest) =>
        if ieq(idx, 0) then igt(c, 0) else th_can_back_m(recfuel - 1, rest, isub(idx, 1))
  ) else th_can_back_exhausted(hl)

implement tab_hist_can_back(hl, idx) = th_can_back_m(airlock_nat(MAX_REC_FUEL), hl, idx)

fun th_can_fwd_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hl: !TabHistList, idx: int): bool =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | THNil() => false
    | THCons(es, c, rest) =>
        if ieq(idx, 0) then ilt(iadd(c, 1), he_len(es))
        else th_can_fwd_m(recfuel - 1, rest, isub(idx, 1))
  ) else th_can_fwd_exhausted(hl)

implement tab_hist_can_forward(hl, idx) = th_can_fwd_m(airlock_nat(MAX_REC_FUEL), hl, idx)

fun he_trim_oldest(es: HistEntryList, cur: &int >> _): HistEntryList =
  if ile(he_len(es), MAX_TAB_HISTORY_ENTRIES) then es
  else case+ es of
    | ~HENil() => HENil()
    | ~HECons(p, _, _, rest) => (buf_free(p); cur := imax(0, isub(cur, 1)); rest)

fun he_push_step(
  es: HistEntryList, cur: &int >> _,
  cur_p: !Buf, cur_sc: int, cur_c: int,
  next_p: !Buf, next_sc: int, next_c: int
): HistEntryList =
  if ieq(cur, 0) andalso ieq(buf_len(cur_p), 0) then let
    val () = he_free(es)
  in
    HECons(th_clone_buf(next_p), next_sc, next_c, HENil())
  end else let
    val e1 = he_update_at_m(airlock_nat(MAX_REC_FUEL), es, cur, cur_p, cur_sc, cur_c)
    val e2 = he_trunc_after_m(airlock_nat(MAX_REC_FUEL), e1, cur)
    val e3 = he_append_m(airlock_nat(MAX_REC_FUEL), e2, th_clone_buf(next_p), next_sc, next_c)
    var nc: int = iadd(cur, 1)
    val e4 = he_trim_oldest(e3, nc)
    val () = cur := nc
  in
    e4
  end

extern fun th_push_exhausted(hl: TabHistList): TabHistList = "mac#anth_die_box"
extern fun th_step_exhausted(hl: TabHistList): TabHistList = "mac#anth_die_box"

fun th_push_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), hl: TabHistList, idx: int,
  cp: !Buf, csc: int, cc: int, np: !Buf, nsc: int, nc: int
): TabHistList =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | ~THNil() => THNil()
    | ~THCons(es, c, rest) =>
        if ieq(idx, 0) then let
          var cur: int = c
          val es2 = he_push_step(es, cur, cp, csc, cc, np, nsc, nc)
        in
          THCons(es2, cur, rest)
        end else THCons(es, c, th_push_m(recfuel - 1, rest, isub(idx, 1), cp, csc, cc, np, nsc, nc))
  ) else th_push_exhausted(hl)

implement tab_hist_push(hl, idx, cp, csc, cc, np, nsc, nc) =
  th_push_m(airlock_nat(MAX_REC_FUEL), hl, idx, cp, csc, cc, np, nsc, nc)

fun th_step_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), hl: TabHistList, idx: int, dir: int,
  cp: !Buf, csc: int, cc: int,
  out_p: &Buf >> _, out_sc: &int >> _, out_c: &int >> _, ok: &bool >> _
): TabHistList =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | ~THNil() => (ok := false; THNil())
    | ~THCons(es, c, rest) =>
        if ieq(idx, 0) then let
          val target = iadd(c, dir)
          val total = he_len(es)
        in
          if ige(target, 0) andalso ilt(target, total) then let
            val es2 = he_update_at_m(airlock_nat(MAX_REC_FUEL), es, c, cp, csc, cc)
            val () = ok := he_get_at_m(airlock_nat(MAX_REC_FUEL), es2, target, out_p, out_sc, out_c)
          in
            THCons(es2, target, rest)
          end else (ok := false; THCons(es, c, rest))
        end else THCons(es, c, th_step_m(recfuel - 1, rest, isub(idx, 1), dir, cp, csc, cc, out_p, out_sc, out_c, ok))
  ) else (ok := false; th_step_exhausted(hl))

implement tab_hist_back(hl, idx, cp, csc, cc, out_p, out_sc, out_c) = let
  var ok: bool = false
  val hl2 = th_step_m(airlock_nat(MAX_REC_FUEL), hl, idx, ~1, cp, csc, cc, out_p, out_sc, out_c, ok)
in
  @(hl2, ok)
end

implement tab_hist_forward(hl, idx, cp, csc, cc, out_p, out_sc, out_c) = let
  var ok: bool = false
  val hl2 = th_step_m(airlock_nat(MAX_REC_FUEL), hl, idx, 1, cp, csc, cc, out_p, out_sc, out_c, ok)
in
  @(hl2, ok)
end

fun th_prefix_eq_m {rem:nat} .<rem>. (p: !Buf, pfx: !Buf, i: int, rem: int(rem)): bool =
  if rem = 0 then true
  else if ieq(buf_get(p, i), buf_get(pfx, i)) then th_prefix_eq_m(p, pfx, iadd(i, 1), rem - 1)
  else false

fun th_has_prefix(p: !Buf, pfx: !Buf): bool = let
  val plen = buf_len(p)
  val xlen = buf_len(pfx)
in
  if ilt(plen, xlen) orelse ile(xlen, 0) then false
  else if ieq(plen, xlen) then th_prefix_eq_m(p, pfx, 0, airlock_nat(xlen))
  else ieq(buf_get(p, xlen), CHAR_SLASH) andalso th_prefix_eq_m(p, pfx, 0, airlock_nat(xlen))
end

fun th_append_suffix(np: &Buf >> _, p: !Buf, olen: int, plen: int): void =
  if igt(plen, olen) then buffer_append_range(np, p, olen, plen) else ()

fun he_rename_one(p: Buf, old_p: !Buf, new_p: !Buf): Buf =
  if not(th_has_prefix(p, old_p)) then p
  else let
    val plen = buf_len(p)
    val olen = buf_len(old_p)
    var np = buf_make(imax(4, iadd(buf_len(new_p), isub(plen, olen))))
    val () = buffer_append_all(np, new_p)
    val () = th_append_suffix(np, p, olen, plen)
    val () = buf_free(p)
  in
    np
  end

extern fun he_rename_exhausted(es: HistEntryList): HistEntryList = "mac#anth_die_box"
extern fun th_rename_exhausted(hl: TabHistList): TabHistList = "mac#anth_die_box"

fun he_rename_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), es: HistEntryList, old_p: !Buf, new_p: !Buf
): HistEntryList =
  if recursion_fuel_available(recfuel) then (
    case+ es of
    | ~HENil() => HENil()
    | ~HECons(p, sc, c, rest) => HECons(he_rename_one(p, old_p, new_p), sc, c, he_rename_m(recfuel - 1, rest, old_p, new_p))
  ) else he_rename_exhausted(es)

fun th_rename_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), hl: TabHistList, old_p: !Buf, new_p: !Buf
): TabHistList =
  if recursion_fuel_available(recfuel) then (
    case+ hl of
    | ~THNil() => THNil()
    | ~THCons(es, c, rest) => THCons(he_rename_m(airlock_nat(MAX_REC_FUEL), es, old_p, new_p), c, th_rename_m(recfuel - 1, rest, old_p, new_p))
  ) else th_rename_exhausted(hl)

implement tab_hist_rename_prefix(hl, old_p, new_p) =
  th_rename_m(airlock_nat(MAX_REC_FUEL), hl, old_p, new_p)
