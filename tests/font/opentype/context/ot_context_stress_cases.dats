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

fun parsed(b: !Buf): int = case+ ot_context_parse(b,ot_fixture_span(b),2,0,OtSubstitution(),ContextPlain()) of
  | ~ContextRejected(e) => 1 | ~ContextAccepted(program) => let
    val v=buf_make(262140)
    val r=ot_context_match(b,program,v,WORD16_MAX_VALUE,0)
    val short=ot_context_match(b,program,v,65534,0)
    val ()=buf_set32(v,65534,1)
    val bad=ot_context_match(b,program,v,WORD16_MAX_VALUE,0)
    val ok=r.matched andalso ieq(r.inputCount,WORD16_MAX_VALUE) andalso ieq(r.actionCount,0)
      andalso not(short.matched) andalso not(bad.matched)
    val ()=buf_free(v) and ()=ot_context_dispose(program)
  in if ok then 0 else 1 end
implement context_test_stress() = let
  var b=ot_fixture_words("0001 0008 0001 000E 0001 0001 0000 0001 0004 FFFF 0000")
  val ()=buf_resize(b,131098)
  val ()=buf_set_len(b,131098)
  val errors=parsed(b)
  val ()=buf_free(b)
in errors end
