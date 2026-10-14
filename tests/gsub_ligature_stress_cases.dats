#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligatures.sats"
staload "opentype_fixture.sats"
staload "font_fixture.sats"
staload "gsub_ligature_contracts.sats"
staload "data_font/gsub_ligature_work.sats"
fun work(b: !Buf,t: !GsubLigatures): int = let
  val+ GsubLigatures(info)=t
  var remaining: int=1
in case+ gsub_ligatures_validate(b,info,remaining) of
  | ~None_vt() => 1 | ~Some_vt(e) => case+ e.reason of
    | OtCapacity() => 0 | OtBounds() => 1 | OtFormat() => 1 | OtGlyphDomain() => 1
    | OtOrder() => 1 | OtCoverageIndex() => 1 | OtPadding() => 1 | OtReference() => 1 | OtUnsupported() => 1 end
fun matched(b: !Buf,t: !GsubLigatures,input: !Buf): int = let
  val r=gsub_ligatures_match(b,t,input,65535,0)
  val short=gsub_ligatures_match(b,t,input,65534,0)
  val offset=gsub_ligatures_match(b,t,input,65535,1)
in if r.matched andalso ieq(r.glyph,1) andalso ieq(r.components,65535)
  andalso not(short.matched) andalso not(offset.matched) then 0 else 1 end
fun budget(b: !Buf,t: !GsubLigatures,input: !Buf): int = let
  var remaining: int=1
  val r=gsub_ligatures_query(b,t,input,65535,0,remaining)
  val exhausted=case+ r.status of | LigatureBudget() => true | LigatureHit() => false | LigatureMiss() => false
  val+ GsubLigatures(info)=t
in if exhausted andalso not(r.result.matched) andalso ieq(remaining,0) andalso ieq(info.maximum,65535) then 0 else 1 end
fun parsed(b: !Buf): int = case+ gsub_ligatures_parse(b,ot_fixture_span(b),2) of
  | ~LigaturesRejected(e) => 1 | ~LigaturesAccepted(t) => let
    val input=buf_make(262140)
    val errors=matched(b,t,input)+work(b,t)+budget(b,t,input)
    val ()=buf_set32(input,65534,1)
    val bad=gsub_ligatures_match(b,t,input,65535,0)
    val ()=buf_free(input) and ()=gsub_ligatures_dispose(t)
  in iadd(errors,if bad.matched then 1 else 0) end
implement ligature_test_stress() = let
  var b=ot_fixture_words("0001 0008 0001 000E 0001 0001 0000 0001 0004 0001 FFFF")
  val ()=buf_resize(b,131098)
  val ()=buf_set_len(b,131098)
  val errors=parsed(b)
  val ()=buf_free(b)
in errors end
