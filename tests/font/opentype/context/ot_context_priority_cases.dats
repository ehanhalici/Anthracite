#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "os/fs.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/context/ot_context.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/context/ot_context_contracts.sats"

fun input(): Buf = let
  val b=buf_make(16)
  val ()=buf_set32(b,0,5) and ()=buf_set32(b,1,6) and ()=buf_set32(b,2,7)
in b end
fun noop(b: !Buf,mode: OtContextMode): int =
  case+ ot_context_parse(b,ot_fixture_span(b),10,3,OtSubstitution(),mode) of
  | ~ContextRejected(e) => 1 | ~ContextAccepted(program) => let
    val v=input()
    val r=ot_context_match(b,program,v,3,0)
    val ok=r.matched andalso ieq(r.inputCount,2) andalso ieq(r.actionCount,0)
    val ()=buf_free(v) and ()=ot_context_dispose(program)
  in if ok then 0 else 1 end
fun empty_set(): int = let
  val b=context_fixture(PlainGlyph())
  val ()=ot_fixture_put16(b,6,0)
  val errors: int=case+ ot_context_parse(b,ot_fixture_span(b),10,3,OtSubstitution(),ContextPlain()) of
    | ~ContextRejected(e) => 1 | ~ContextAccepted(program) => let
      val v=input()
      val r=ot_context_match(b,program,v,3,0)
      val ()=buf_free(v) and ()=ot_context_dispose(program)
    in if r.matched then 1 else 0 end
  val ()=buf_free(b)
in errors end
fun ignored_extra(): int = let
  val b=ot_fixture_words("0001 0008 0001 0010 0001 0002 0005 0006 0001 0004 0002 0000 0006")
  val errors: int=case+ ot_context_parse(b,ot_fixture_span(b),10,0,OtSubstitution(),ContextPlain()) of
    | ~ContextRejected(e) => 1 | ~ContextAccepted(program) => let
      val v=input()
      val r=ot_context_match(b,program,v,3,1)
      val ()=buf_free(v) and ()=ot_context_dispose(program)
    in if r.matched then 1 else 0 end
  val ()=buf_free(b)
in errors end
fun priority(b: !Buf,expected: int,lookup: int): int =
  case+ ot_context_parse(b,ot_fixture_span(b),10,3,OtSubstitution(),ContextPlain()) of
  | ~ContextRejected(e) => 1 | ~ContextAccepted(program) => let
    val v=input()
    val r=ot_context_match(b,program,v,3,0)
    val error: int=if not(r.matched) orelse ine(r.inputCount,expected) orelse ine(r.actionCount,1) then 1 else let
      val action=ot_context_action(b,r,0)
    in if ieq(action.lookup,lookup) then 0 else 1 end
    val ()=buf_free(v) and ()=ot_context_dispose(program)
  in error end
fun limited_priority(): int = let
  val b=ot_fixture_words("0001 0008 0001 000E 0001 0001 0005 0002 0006 0010 0002 0001 0006 0000 0001 0001 0001 0000 0002")
  val errors: int=case+ ot_context_parse(b,ot_fixture_span(b),10,3,OtSubstitution(),ContextPlain()) of
    | ~ContextRejected(e) => 1 | ~ContextAccepted(p) => let
      val v=input()
      val r=ot_context_match_bounded(b,p,v,3,0,1)
      val limits=ot_context_limits(b,p)
      val action=ot_context_action(b,r,0)
      val ok=r.matched andalso ieq(r.inputCount,1) andalso ieq(r.actionCount,1)
        andalso ieq(action.lookup,2) andalso ieq(limits.input,2)
      val ()=buf_free(v) and ()=ot_context_dispose(p)
    in if ok then 0 else 1 end
  val ()=buf_free(b)
in errors end
implement context_test_priority() = let
  val n=context_fixture(PlainCoverage())
  val ()=ot_fixture_put16(n,4,0)
  val no_actions=noop(n,ContextPlain())
  val ()=buf_free(n)
  val b=ot_fixture_words("0001 0008 0001 000E 0001 0001 0005 0002 0006 0010 0002 0001 0006 0000 0001 0003 0001 0006 0007 0001 0002")
  val first=priority(b,2,1)
  val ()=ot_fixture_put16(b,16,16) and ()=ot_fixture_put16(b,18,6)
  val second=priority(b,3,2)
  val ()=buf_free(b)
in no_actions+first+second+empty_set()+ignored_extra()+limited_priority() end
