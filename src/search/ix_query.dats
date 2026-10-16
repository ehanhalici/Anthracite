#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef IX_QUERY_PARSE_OMAP_INITIAL_BYTES = 64


staload "mem.sats"
staload "os/fs.sats"
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
  val idx = idiv(len, WORD32_BYTES)
  val need = iadd(len, WORD32_BYTES)
  val () = if buf_cap(b) < need then buf_resize(b, imax(imul(need, 2), 64)) else ()
  val () = buf_set_len(b, need)
  val () = buf_set32(b, idx, v)
in
end

fun skip_ws_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), q: !Buf, p: int, n: int): int =
  if recfuel > 0 then (
    if ilt(p, n) andalso ile(buf_get(q, p), CHAR_SPACE) then
      skip_ws_with_fuel(recfuel - 1, q, iadd(p, 1), n)
    else p
  ) else p

fun scan_quote_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), q: !Buf, p: int, n: int): int =
  if recfuel > 0 then (
    if ilt(p, n) andalso ine(buf_get(q, p), CHAR_QUOTE) then
      scan_quote_with_fuel(recfuel - 1, q, iadd(p, 1), n)
    else p
  ) else p

fun scan_word_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), q: !Buf, p: int, n: int): int =
  if recfuel > 0 then (
    if ilt(p, n) andalso igt(buf_get(q, p), CHAR_SPACE) then
      scan_word_with_fuel(recfuel - 1, q, iadd(p, 1), n)
    else p
  ) else p

fun matches_ascii_tail{remaining:nat} .<remaining>. (
  remaining: int(remaining),q: !Buf,position: int,text: string,index: int
): bool =
  if remaining > 0 then
    ieq(buf_get(q,position),c_str_byte(text,index)) andalso
      matches_ascii_tail(remaining-1,q,iadd(position,1),text,iadd(index,1))
  else true

fun matches_ascii(q: !Buf,position: int,limit: int,text: string): bool = let
  val size=c_strlen(text)
in if ilt(position,0) orelse igt(size,isub(limit,position)) then false
  else matches_ascii_tail(airlock_nat(size),q,position,text,0) end

fun detect_query_operator(q: !Buf,p: int,n: int,skip: &int >> _): QOp =
  if matches_ascii(q,p,n,"#") then (skip := c_strlen("#"); QTag())
  else if matches_ascii(q,p,n,"[[") then (skip := c_strlen("[["); QWiki())
  else if matches_ascii(q,p,n,"h:") then (skip := c_strlen("h:"); QHeading())
  else if matches_ascii(q,p,n,"file:") then (skip := c_strlen("file:"); QFile())
  else if matches_ascii(q,p,n,"task:") then (skip := c_strlen("task:"); QTask())
  else if matches_ascii(q,p,n,"code:") then (skip := c_strlen("code:"); QCode())
  else (skip := 0; QPlain())

fun task_status_code(pool: !Buf,offset: int,size: int): int =
  if ieq(size,c_strlen("todo")) andalso matches_ascii(pool,offset,iadd(offset,size),"todo") then 1
  else if ieq(size,c_strlen("done")) andalso matches_ascii(pool,offset,iadd(offset,size),"done") then 2
  else 0

fun is_qop_task(qop: QOp): bool = case+ qop of
  | QTask() => true
  | QPlain() => false
  | QTag() => false
  | QWiki() => false
  | QHeading() => false
  | QFile() => false
  | QCode() => false

fun append_query_term(
  q: !Buf,start: int,finish: int,operator: QOp,pool: &Buf >> _,terms: &Buf >> _,omap: &Buf >> _
): void =
  if ilt(start,finish) then let
    val offset=buf_len(pool)
    val ()=fold_range_buf(q,start,finish,pool,omap)
    val size=isub(buf_len(pool),offset)
    val auxiliary=if is_qop_task(operator) then task_status_code(pool,offset,size) else 0
    val ()=buf_push32(terms,qop_code(operator))
    val ()=buf_push32(terms,offset)
    val ()=buf_push32(terms,size)
  in buf_push32(terms,auxiliary) end else ()

fun parse_quoted_term(q: !Buf,p: int,n: int,pool: &Buf >> _,terms: &Buf >> _,omap: &Buf >> _): int = let
  val start=iadd(p,1)
  val finish=scan_quote_with_fuel(airlock_nat(MAX_REC_FUEL),q,start,n)
  val ()=append_query_term(q,start,finish,QPlain(),pool,terms,omap)
in if ilt(finish,n) then iadd(finish,1) else finish end

fun parse_unquoted_term(q: !Buf,p: int,n: int,pool: &Buf >> _,terms: &Buf >> _,omap: &Buf >> _): int = let
  var skip: int=0
  val operator=detect_query_operator(q,p,n,skip)
  val start=iadd(p,skip)
  val finish=scan_word_with_fuel(airlock_nat(MAX_REC_FUEL),q,start,n)
  val ()=append_query_term(q,start,finish,operator,pool,terms,omap)
in finish end

fun parse_term(q: !Buf,p: int,n: int,pool: &Buf >> _,terms: &Buf >> _,omap: &Buf >> _): int =
  if ieq(buf_get(q,p),CHAR_QUOTE) then parse_quoted_term(q,p,n,pool,terms,omap)
  else parse_unquoted_term(q,p,n,pool,terms,omap)

fun parse_loop_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), q: !Buf, p: int, n: int, cnt: int, pool: &Buf >> _, terms: &Buf >> _, omap: &Buf >> _): int =
  if recfuel > 0 then (
    if ige(cnt, MAX_QUERY_TERMS) orelse ige(p, n) then cnt
    else let
      val p0 = skip_ws_with_fuel(airlock_nat(MAX_REC_FUEL), q, p, n)
    in
      if ige(p0, n) then cnt
      else let
        val cur_terms = buf_len(terms)
        val p1 = parse_term(q, p0, n, pool, terms, omap)
        val added = (if igt(buf_len(terms), cur_terms) then 1 else 0) : int
      in
        parse_loop_with_fuel(recfuel - 1, q, p1, n, iadd(cnt, added), pool, terms, omap)
      end
    end
  ) else cnt

implement ix_query_parse(q, pool, terms) = let
  val n = buf_len(q)
  val () = buf_set_len(pool, 0)
  val () = buf_set_len(terms, 0)
  var omap = buf_make(IX_QUERY_PARSE_OMAP_INITIAL_BYTES)
  val cnt = parse_loop_with_fuel(airlock_nat(MAX_REC_FUEL), q, 0, n, 0, pool, terms, omap)
  val () = buf_free(omap)
in
  cnt
end
