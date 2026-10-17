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
  val b=buf_make(24)
  val ()=buf_set32(b,0,1) and ()=buf_set32(b,1,2) and ()=buf_set32(b,2,5)
  val ()=buf_set32(b,3,6) and ()=buf_set32(b,4,7) and ()=buf_set32(b,5,8)
in b end
fun actions{kind:int}(b: !Buf,r: OtContextMatch(kind)): int =
  if not(r.matched) orelse ine(r.inputCount,2) orelse ine(r.actionCount,2) then 1 else let
    val first=ot_context_action(b,r,0)
    val second=ot_context_action(b,r,1)
  in if ieq(first.position,1) andalso ieq(first.lookup,2) andalso
    ieq(second.position,0) andalso ieq(second.lookup,1) then 0 else 1 end
fun bounded{kind:int}(b: !Buf,p: !OtContextProgram(kind),v: !Buf,which: ContextFixture): int = let
  val short=ot_context_match_bounded(b,p,v,6,2,1)
  val exact=ot_context_match_bounded(b,p,v,6,2,2)
  val negative=ot_context_match_bounded(b,p,v,6,2,~1)
  val beyond=ot_context_match_bounded(b,p,v,6,2,5)
  val limits=ot_context_limits(b,p)
  val context: int=case+ context_fixture_mode(which) of | ContextPlain() => 0 | ContextChained() => 2
  val valid=not(short.matched) andalso not(negative.matched) andalso not(beyond.matched)
    andalso ieq(limits.input,2) andalso ieq(limits.back,context) andalso ieq(limits.look,context)
in iadd(actions(b,exact),if valid then 0 else 1) end
fun queried{kind:int}(b: !Buf,p: !OtContextProgram(kind),which: ContextFixture): int = let
  val v=input()
  val bounded_errors=bounded(b,p,v,which)
  val r=ot_context_match(b,p,v,6,2)
  val boundary=ot_context_match(b,p,v,7,2)
  val before=ot_context_match(b,p,v,6,~1)
  val miss=ot_context_match(b,p,v,6,0)
  val ()=buf_set32(v,3,9)
  val changed=ot_context_match(b,p,v,6,2)
  val expected=context_fixture_classes(which)
  val ()=buf_free(v)
in iadd(bounded_errors,iadd(actions(b,r),if not(boundary.matched) andalso not(before.matched) andalso not(miss.matched)
  andalso (changed.matched = expected) then 0 else 1)) end
fun parsed{kind:int}(b: !Buf,which: ContextFixture,domain: OtLayoutDomain(kind)): int =
  case+ ot_context_parse(b,ot_fixture_span(b),10,3,domain,context_fixture_mode(which)) of
  | ~ContextRejected(e) => 1 | ~ContextAccepted(p) => let
    val errors=queried(b,p,which) val ()=ot_context_dispose(p)
  in errors end
fun check(which: ContextFixture): int = let
  val b=context_fixture(which)
  val errors=parsed(b,which,OtSubstitution())+parsed(b,which,OtPositioning())
  val ()=buf_free(b)
in errors end
implement context_test_match() = check(PlainGlyph())+check(PlainClass())+check(PlainCoverage())+
  check(ChainGlyph())+check(ChainClass())+check(ChainCoverage())
