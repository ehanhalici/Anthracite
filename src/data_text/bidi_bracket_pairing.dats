#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "data_text/utf8.sats"
staload "data_text/bidi_sequence.sats"
staload "data_text/bidi_predicates.sats"
staload "data_text/bidi_bracket_data.sats"
staload "data_text/bidi_bracket_pairs.sats"

typedef PairState = @{depth=int, valid=bool}
extern fun pairing_exhausted(): int = "mac#anth_die_int"

fun init_pairs {n:nat} .<n>. (n: int(n), pairs: !Buf, i: int): void =
  if n = 0 then () else let
    val () = buf_set32(pairs,i,~1)
  in init_pairs(n-1,pairs,iadd(i,1)) end

fun find_close {n:nat} .<n>. (n: int(n), stack: !Buf, cp: int, top: int): int =
  if ilt(top,0) then ~1 else if n = 0 then pairing_exhausted()
  else if ieq(buf_get32(stack,imul(top,2)),cp) then top else find_close(n-1,stack,cp,isub(top,1))

fun push_open(stack: !Buf, info: BracketInfo, i: int, depth: int): PairState =
  if ieq(depth,63) then @{depth=depth,valid=false} else let
    val at = imul(depth,2)
    val () = buf_set32(stack,at,bidi_bracket_canonical(info.paired))
    val () = buf_set32(stack,iadd(at,1),i)
  in @{depth=iadd(depth,1),valid=true} end

fun close_pair(stack: !Buf, pairs: !Buf, cp: int, i: int, depth: int): PairState = let
  val at = find_close(airlock_nat(iadd(depth,1)),stack,bidi_bracket_canonical(cp),isub(depth,1))
in if ilt(at,0) then @{depth=depth,valid=true} else let
    val opening = buf_get32(stack,iadd(imul(at,2),1))
    val () = buf_set32(pairs,opening,i)
  in @{depth=at,valid=true} end end

fun step(stack: !Buf, pairs: !Buf, info: BracketInfo, cp: int, i: int, depth: int): PairState =
  case+ info.kind of
  | NoBracket() => @{depth=depth,valid=true}
  | OpenBracket() => push_open(stack,info,i,depth)
  | CloseBracket() => close_pair(stack,pairs,cp,i,depth)

fun pair_one(
  data: !BidiBrackets, text: !ScalarText, work: !BidiWork, seq: !BidiSequence,
  stack: !Buf, pairs: !Buf, i: int, depth: int
): PairState = if not(bidi_is_other(bidi_sequence_class(work,seq,i))) then @{depth=depth,valid=true}
  else let
    val cp = scalar_value(text,bidi_source_index(work,bidi_sequence_index(seq,i)))
    val info = bidi_bracket_info(data,cp)
  in step(stack,pairs,info,cp,i,depth) end

fun scan {n:nat} .<n>. (
  n: int(n), data: !BidiBrackets, text: !ScalarText, work: !BidiWork,
  seq: !BidiSequence, stack: !Buf, pairs: !Buf, i: int, depth: int
): int = if n = 0 then 1 else let
  val state = pair_one(data,text,work,seq,stack,pairs,i,depth)
in if not(state.valid) then 0 else scan(n-1,data,text,work,seq,stack,pairs,iadd(i,1),state.depth) end

implement bidi_bracket_pairs(data,text,work,seq) = let
  val n = airlock_nat(bidi_sequence_count(seq))
  val pairs = buf_make(imul(n,4))
  val stack = buf_make(504)
  val () = init_pairs(n,pairs,0)
  val valid = scan(n,data,text,work,seq,stack,pairs,0,0)
  val () = buf_free(stack)
  val () = if ieq(valid,0) then init_pairs(n,pairs,0) else ()
in pairs end
