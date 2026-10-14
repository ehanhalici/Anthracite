#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/gdef_header.sats"
staload "data_font/gdef_marks.sats"
staload "opentype_fixture.sats"
staload "gdef_contracts.sats"

fun fixture(): Buf = ot_fixture_words("0001 0002 0000 0000 0000 0000 000E 0001 0002 0000 000C 0000 0016 0001 0003 0001 0003 0005 0002 0001 0003 0006 0000")
fun expected(index: int,gid: int): bool =
  if ieq(index,0) then ieq(gid,1) orelse ieq(gid,3) orelse ieq(gid,5)
  else if ieq(index,1) then ige(gid,3) andalso ile(gid,6) else false

fun compare {n:nat} .<n>. (n: int(n),b: !Buf,sets: !GdefMarkSets,gid: int,errors: int): int =
  if n = 0 then errors else let
    val a=gdef_mark_contains(b,sets,0,gid)=expected(0,gid)
    val c=gdef_mark_contains(b,sets,1,gid)=expected(1,gid)
    val d=not(gdef_mark_contains(b,sets,~1,gid) orelse gdef_mark_contains(b,sets,2,gid))
  in compare(n-1,b,sets,iadd(gid,1),iadd(errors,if a andalso c andalso d then 0 else 1)) end

fun parsed(b: !Buf,h: GdefHeaderInfo): int = case+ gdef_marks_parse(b,h,16) of
  | ~GdefMarksRejected(e) => 1
  | ~GdefMarksAccepted(sets) => let
    val count=gdef_mark_set_count(sets)
    val errors=compare(18,b,sets,~1,0)
    val ()=gdef_marks_dispose(sets)
  in iadd(errors,if ieq(count,2) then 0 else 1) end

fun valid(): int = let
  val b=fixture()
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 1 | ~GdefHeaderAccepted(h) => parsed(b,h)
  val ()=buf_free(b)
in errors end

fun rejected(b: !Buf): int = case+ gdef_header_parse(b,ot_fixture_span(b)) of
  | ~GdefHeaderRejected(e) => 0 | ~GdefHeaderAccepted(h) => case+ gdef_marks_parse(b,h,16) of
    | ~GdefMarksRejected(e) => 0
    | ~GdefMarksAccepted(sets) => let val ()=gdef_marks_dispose(sets) in 1 end

fun truncated {n:nat} .<n>. (n: int(n),b: !Buf,length: int,errors: int): int =
  if n = 0 then errors else let
    val ()=buf_set_len(b,iadd(8,length))
    val next=rejected(b)
  in truncated(n-1,b,iadd(length,1),iadd(errors,next)) end

fun prefixes(): int = let
  val b=fixture()
  val errors=truncated(46,b,0,0)
  val ()=buf_free(b)
in errors end

fun invalid(at: int,value: int): int = let
  val b=fixture()
  val ()=ot_fixture_put16(b,at,value)
  val errors=rejected(b)
  val ()=buf_free(b)
in errors end

fun empty(): int = let
  val b=ot_fixture_words("0001 0000 0000 0000 0000 0000")
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 1 | ~GdefHeaderAccepted(h) => case+ gdef_marks_parse(b,h,16) of
      | ~GdefMarksRejected(e) => 1 | ~GdefMarksAccepted(sets) => let
        val equal=ieq(gdef_mark_set_count(sets),0) andalso not(gdef_mark_contains(b,sets,0,1))
        val ()=gdef_marks_dispose(sets)
      in if equal then 0 else 1 end
  val ()=buf_free(b)
in errors end

implement gdef_test_marks() =
  valid()+empty()+prefixes()+invalid(14,2)+invalid(20,0)+invalid(20,8)+invalid(18,32768)+
  invalid(24,65535)+invalid(32,1)+invalid(42,16)+invalid(44,1)
