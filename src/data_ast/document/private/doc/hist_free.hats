extern fun hist_free_fuel_exhausted(h: Hist): void = "mac#anth_die_void"

fun hist_free_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), h: Hist): void =
  if recursion_fuel_available(recfuel) then (
    case+ h of
    | ~HNil() => ()
    | ~HCons(b, _, rest) => let
        val () = buf_free(b)
      in
        hist_free_with_fuel(recfuel - 1, rest)
      end
  ) else hist_free_fuel_exhausted(h)

fun hist_free(h: Hist): void = hist_free_with_fuel(airlock_nat(MAX_REC_FUEL), h)

extern fun hist_drop_oldest_fuel_exhausted(h: Hist): Hist = "mac#anth_die_box"

fun hist_drop_oldest_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), h: Hist): Hist =
  if recursion_fuel_available(recfuel) then (
    case+ h of
    | ~HNil() => HNil()
    | ~HCons(b, c, rest) =>
        case+ rest of
        | HNil() => let
            val () = buf_free(b)
            val () = hist_free(rest)
          in
            HNil()
          end
        | ~HCons(b2, c2, rest2) => HCons(b, c, hist_drop_oldest_with_fuel(recfuel - 1, HCons(b2, c2, rest2)))
  ) else hist_drop_oldest_fuel_exhausted(h)

fun hist_drop_oldest(h: Hist): Hist = hist_drop_oldest_with_fuel(airlock_nat(MAX_REC_FUEL), h)

extern fun hist_len_fuel_exhausted(h: !Hist): int = "mac#anth_die_int"

fun hist_len_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), h: !Hist): int =
  if recursion_fuel_available(recfuel) then (
    case+ h of
    | HNil() => 0
    | HCons(_, _, rest) => iadd(1, hist_len_with_fuel(recfuel - 1, rest))
  ) else hist_len_fuel_exhausted(h)

fun hist_len(h: !Hist): int = hist_len_with_fuel(airlock_nat(MAX_REC_FUEL), h)

fun hist_trim(h: Hist): Hist =
  case+ ige(hist_len(h), 35) of
  | true => hist_drop_oldest(h)
  | false => h

datatype EditOp = OpNone | OpChar | OpBreak

fun op_code(k: EditOp): int = case+ k of
  | OpNone() => 0
  | OpChar() => 1
  | OpBreak() => 2

fun is_op(a: EditOp, b: EditOp): bool = ieq(op_code(a), op_code(b))

datavtype Doc_ = DOC of @{
  gap= Buf, lines= Buf, nodes= Buf, lay= Buf, visual= Option_vt(VisualRows), media= Buf
, uhist= Hist, rhist= Hist
, lo= int, hi= int, len= int
, caret= int, anchor= int
, nlines= int, nnodes= int, span= int
, last_op= EditOp, typing_cnt= int, is_md= Toggle
, ver= int, folds= Buf
, flash_line= int, flash_time= lint, embed_level= int
, regions= Buf, hidden= Buf
}
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Doc = Doc_
#include "data_ast/layout/private/doc_visual_owner.hats"
#include "data_ast/layout/private/doc_visual_index_impl.hats"

implement doc_open() = DOC(@{
  gap= buf_make(DOC_OPEN_GAP_INITIAL_BYTES), lines= buf_make(64 * 4), nodes= buf_make(64 * AST_NODE_WORDS * 4), lay= layout_open(), visual= None_vt(), media= buf_make(0)
, uhist= HNil(), rhist= HNil()
, lo= 0, hi= 256, len= 0
, caret= 0, anchor= 0
, nlines= 1, nnodes= 0, span= 0
, last_op= OpNone, typing_cnt= 0, is_md= On
, ver= 0, folds= buf_make(64 * 4)
, flash_line= ~1, flash_time= 0L, embed_level= 0
, regions= buf_make(64 * 16), hidden= buf_make(DOC_OPEN_HIDDEN_INITIAL_BYTES)
})

implement doc_set_flash(d, line, until) =
  case+ d of
  | @DOC(s) => let
      val () = s.flash_line := line
      val () = s.flash_time := until
    in
      fold@(d)
    end

implement doc_get_flash(d, now) =
  case+ d of
  | @DOC(s) => let
      val res = (if ige(s.flash_line, 0) andalso now < s.flash_time then s.flash_line else ~1)
    in
      fold@(d); res
    end

implement doc_is_md(d) =
  case+ d of
  | @DOC(s) => let
      val v = s.is_md
    in
      fold@(d); v
    end

implement doc_set_md(d, v) =
  case+ d of
  | @DOC(s) => let
      val () = s.is_md := v
    in
      fold@(d)
    end

implement doc_embed_level(d) =
  case+ d of
  | @DOC(s) => let
      val level = s.embed_level
    in
      fold@(d); level
    end

implement doc_set_embed_level(d, level) =
  case+ d of
  | @DOC(s) => let
      val () = s.embed_level := level
    in
      fold@(d)
    end

implement doc_free(d) = let
  val+~DOC(s) = d
  val () = visual_release(s.visual)
  val () = buf_free(s.media)
  val () = buf_free(s.gap)
  val () = buf_free(s.lines)
  val () = layout_dispose(s.lay)
  val () = buf_free(s.nodes)
  val () = buf_free(s.folds)
  val () = buf_free(s.regions)
  val () = buf_free(s.hidden)
  val () = hist_free(s.uhist)
in
  hist_free(s.rhist)
end

fun d_ver(d: !Doc): int =
  case+ d of
  | @DOC(s) => let
      val v = s.ver
    in
      fold@(d); v
    end

fun d_bump_ver(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val () = s.ver := iadd(s.ver, 1)
    in
      fold@(d)
    end

implement doc_bump_ver(d) = d_bump_ver(d)

implement fold_count(d) =
  case+ d of
  | @DOC(s) => let
      val n = idiv(buf_len(s.folds), 4)
    in
      fold@(d); n
    end

fun fold_get(d: !Doc, idx: int): int =
  case+ d of
  | @DOC(s) => let
      val v = buf_get32(s.folds, iadd(imul(idx, 4), 0))
    in
      fold@(d); v
    end

fun fold_set(d: !Doc, idx: int, v: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_set32(s.folds, iadd(imul(idx, 4), 0), v)
    in
      fold@(d)
    end

extern fun fold_has_fuel_exhausted(d: !Doc, off: int, i: int, n: int): bool = "mac#anth_die_int"

fun fold_has_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, off: int, i: int, n: int
): bool =
  if recursion_fuel_available(recfuel) then (
    if i >= n then false
    else if ieq(fold_get(d, i), off) then true
    else fold_has_with_fuel(recfuel - 1, d, off, iadd(i, 1), n)
  ) else fold_has_fuel_exhausted(d, off, i, n)
