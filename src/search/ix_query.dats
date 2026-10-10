#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "search/ix_fold.sats"
staload "search/ix_query.sats"

implement qop_code(qop) = case+ qop of
  | QPlain() => 0
  | QTag() => 1
  | QWiki() => 2
  | QHeading() => 3
  | QFile() => 4
  | QTask() => 5
  | QCode() => 6

implement qop_of(code) =
  if code = 1 then QTag()
  else if code = 2 then QWiki()
  else if code = 3 then QHeading()
  else if code = 4 then QFile()
  else if code = 5 then QTask()
  else if code = 6 then QCode()
  else QPlain()

fun buf_push32(b: &Buf >> _, v: int): void = let
  val len = buf_len(b)
  val idx = idiv(len, 4)
  val need = iadd(len, 4)
  val () = if buf_cap(b) < need then buf_resize(b, imax(imul(need, 2), 64)) else ()
  val () = buf_set_len(b, need)
  val () = buf_set32(b, idx, v)
in
end

fun skip_ws_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), q: !Buf, p: int, n: int): int =
  if recfuel > 0 then (
    if ilt(p, n) andalso ile(buf_get(q, p), 32) then
      skip_ws_m(recfuel - 1, q, iadd(p, 1), n)
    else p
  ) else p

fun scan_quote_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), q: !Buf, p: int, n: int): int =
  if recfuel > 0 then (
    if ilt(p, n) andalso ine(buf_get(q, p), 34) then
      scan_quote_m(recfuel - 1, q, iadd(p, 1), n)
    else p
  ) else p

fun scan_word_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), q: !Buf, p: int, n: int): int =
  if recfuel > 0 then (
    if ilt(p, n) andalso igt(buf_get(q, p), 32) then
      scan_word_m(recfuel - 1, q, iadd(p, 1), n)
    else p
  ) else p

fun detect_op(q: !Buf, p: int, n: int, skip: &int >> _): QOp =
  if ilt(p, n) andalso ieq(buf_get(q, p), 35) then (skip := 1; QTag())
  else if ilt(iadd(p, 1), n) andalso ieq(buf_get(q, p), 91) andalso ieq(buf_get(q, iadd(p, 1)), 91) then (skip := 2; QWiki())
  else if ilt(iadd(p, 1), n) andalso ieq(buf_get(q, p), 104) andalso ieq(buf_get(q, iadd(p, 1)), 58) then (skip := 2; QHeading())
  else if ilt(iadd(p, 4), n) andalso ieq(buf_get(q, p), 102) andalso ieq(buf_get(q, iadd(p, 1)), 105) andalso ieq(buf_get(q, iadd(p, 2)), 108) andalso ieq(buf_get(q, iadd(p, 3)), 101) andalso ieq(buf_get(q, iadd(p, 4)), 58) then (skip := 5; QFile())
  else if ilt(iadd(p, 4), n) andalso ieq(buf_get(q, p), 116) andalso ieq(buf_get(q, iadd(p, 1)), 97) andalso ieq(buf_get(q, iadd(p, 2)), 115) andalso ieq(buf_get(q, iadd(p, 3)), 107) andalso ieq(buf_get(q, iadd(p, 4)), 58) then (skip := 5; QTask())
  else if ilt(iadd(p, 4), n) andalso ieq(buf_get(q, p), 99) andalso ieq(buf_get(q, iadd(p, 1)), 111) andalso ieq(buf_get(q, iadd(p, 2)), 100) andalso ieq(buf_get(q, iadd(p, 3)), 101) andalso ieq(buf_get(q, iadd(p, 4)), 58) then (skip := 5; QCode())
  else (skip := 0; QPlain())

fun task_aux(pool: !Buf, toff: int, tlen: int): int =
  if ieq(tlen, 4) andalso ieq(buf_get(pool, toff), 116) andalso ieq(buf_get(pool, iadd(toff, 1)), 111) andalso ieq(buf_get(pool, iadd(toff, 2)), 100) andalso ieq(buf_get(pool, iadd(toff, 3)), 111) then 1
  else if ieq(tlen, 4) andalso ieq(buf_get(pool, toff), 100) andalso ieq(buf_get(pool, iadd(toff, 1)), 111) andalso ieq(buf_get(pool, iadd(toff, 2)), 110) andalso ieq(buf_get(pool, iadd(toff, 3)), 101) then 2
  else 0

fun is_qop_task(qop: QOp): bool = case+ qop of
  | QTask() => true
  | QPlain() => false
  | QTag() => false
  | QWiki() => false
  | QHeading() => false
  | QFile() => false
  | QCode() => false

fun parse_term(q: !Buf, p: int, n: int, pool: &Buf >> _, terms: &Buf >> _, omap: &Buf >> _): int = let
  val is_q = ieq(buf_get(q, p), 34)
in
  if is_q then let
    val st = iadd(p, 1)
    val en = scan_quote_m(airlock_nat(MAX_REC_FUEL), q, st, n)
    val next_p = if ilt(en, n) then iadd(en, 1) else en
  in
    if ilt(st, en) then let
      val toff = buf_len(pool)
      val () = fold_range_buf(q, st, en, pool, omap)
      val tlen = isub(buf_len(pool), toff)
      val () = buf_push32(terms, 0)
      val () = buf_push32(terms, toff)
      val () = buf_push32(terms, tlen)
      val () = buf_push32(terms, 0)
    in
      next_p
    end else next_p
  end else let
    var skip: int = 0
    val qop = detect_op(q, p, n, skip)
    val st = iadd(p, skip)
    val en = scan_word_m(airlock_nat(MAX_REC_FUEL), q, st, n)
  in
    if ilt(st, en) then let
      val toff = buf_len(pool)
      val () = fold_range_buf(q, st, en, pool, omap)
      val tlen = isub(buf_len(pool), toff)
      val is_task = is_qop_task(qop)
      val aux = if is_task then task_aux(pool, toff, tlen) else 0
      val () = buf_push32(terms, qop_code(qop))
      val () = buf_push32(terms, toff)
      val () = buf_push32(terms, tlen)
      val () = buf_push32(terms, aux)
    in
      en
    end else en
  end
end

fun parse_loop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), q: !Buf, p: int, n: int, cnt: int, pool: &Buf >> _, terms: &Buf >> _, omap: &Buf >> _): int =
  if recfuel > 0 then (
    if ige(cnt, MAX_QUERY_TERMS) orelse ige(p, n) then cnt
    else let
      val p0 = skip_ws_m(airlock_nat(MAX_REC_FUEL), q, p, n)
    in
      if ige(p0, n) then cnt
      else let
        val cur_terms = buf_len(terms)
        val p1 = parse_term(q, p0, n, pool, terms, omap)
        val added = (if igt(buf_len(terms), cur_terms) then 1 else 0) : int
      in
        parse_loop_m(recfuel - 1, q, p1, n, iadd(cnt, added), pool, terms, omap)
      end
    end
  ) else cnt

implement ix_query_parse(q, pool, terms) = let
  val n = buf_len(q)
  val () = buf_set_len(pool, 0)
  val () = buf_set_len(terms, 0)
  var omap = buf_make(64)
  val cnt = parse_loop_m(airlock_nat(MAX_REC_FUEL), q, 0, n, 0, pool, terms, omap)
  val () = buf_free(omap)
in
  cnt
end
