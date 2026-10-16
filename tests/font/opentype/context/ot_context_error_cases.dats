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

fun reject(b: !Buf,s: OtSpan,mode: OtContextMode,glyphs: int,lookups: int): int =
  case+ ot_context_parse(b,s,glyphs,lookups,OtSubstitution(),mode) of
  | ~ContextRejected(e) => 0 | ~ContextAccepted(program) => let val ()=ot_context_dispose(program) in 1 end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,mode: OtContextMode,length: int): int =
  if n = 0 then 0 else reject(b,@{offset=8,length=length},mode,10,3)+cuts(n-1,b,mode,iadd(length,1))
fun truncated(which: ContextFixture): int = let
  val b=context_fixture(which)
  val errors=cuts(airlock_nat(isub(buf_len(b),8)),b,context_fixture_mode(which),0)
  val ()=buf_free(b)
in errors end
fun change(which: ContextFixture,at: int,value: int): int = let
  val b=context_fixture(which)
  val ()=ot_fixture_put16(b,at,value)
  val errors=reject(b,ot_fixture_span(b),context_fixture_mode(which),10,3)
  val ()=buf_free(b)
in errors end
fun domains(): int = let
  val b=context_fixture(PlainGlyph())
  val s=ot_fixture_span(b)
  val errors=reject(b,s,ContextPlain(),0,3)+reject(b,s,ContextPlain(),WORD16_MODULUS,3)+
    reject(b,s,ContextPlain(),10,~1)+reject(b,s,ContextPlain(),10,WORD16_MODULUS)+
    reject(b,@{offset= ~1,length=30},ContextPlain(),10,3)+
    reject(b,@{offset=8,length=SIGNED_INT_MAX_VALUE},ContextPlain(),10,3)
  val ()=buf_free(b)
in errors end
fun expanded_position(): int = let
  val b=context_fixture(PlainCoverage())
  val ()=ot_fixture_put16(b,10,2)
  val substitution=case+ ot_context_parse(b,ot_fixture_span(b),10,3,OtSubstitution(),ContextPlain()) of
    | ~ContextRejected(e) => 1 | ~ContextAccepted(p) => let val ()=ot_context_dispose(p) in 0 end
  val positioning=case+ ot_context_parse(b,ot_fixture_span(b),10,3,OtPositioning(),ContextPlain()) of
    | ~ContextRejected(e) => 0 | ~ContextAccepted(p) => let val ()=ot_context_dispose(p) in 1 end
  val ()=buf_free(b)
in iadd(substitution,positioning) end
implement context_test_errors() = domains()+expanded_position()+
  truncated(PlainGlyph())+truncated(PlainClass())+truncated(PlainCoverage())+
  truncated(ChainGlyph())+truncated(ChainClass())+truncated(ChainCoverage())+
  change(PlainGlyph(),0,4)+change(PlainGlyph(),2,0)+change(PlainGlyph(),6,7)+
  change(PlainCoverage(),2,0)+change(PlainCoverage(),6,0)+
  change(PlainCoverage(),12,3)+change(PlainClass(),4,0)+
  change(ChainClass(),4,0)+change(ChainClass(),6,0)+change(ChainClass(),8,0)+
  change(ChainCoverage(),2,WORD16_MAX_VALUE)
