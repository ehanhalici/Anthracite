#include "font/native/text/native_pipeline_test.hats"
staload "font/resources/font_fixture.sats"
staload "data_font/native/text/native_text_coverage.sats"
fun selected(preferred: !SfntFace,alternative: !SfntFace,ignored: !PropertyMap(8),source: !ScalarText): NativeClusterFace = let
  val+ SfntFace(pb,pi)=preferred val+ SfntFace(ab,ai)=alternative
in native_text_cluster_face(pb,pi,ab,ai,ignored,source,0,scalar_count(source)) end
fun matches(actual: NativeClusterFace,expected: NativeClusterFace): bool = case+ actual of
  | ClusterPreferred() => (case+ expected of | ClusterPreferred() => true | ClusterAlternative() => false | ClusterMissing() => false)
  | ClusterAlternative() => (case+ expected of | ClusterPreferred() => false | ClusterAlternative() => true | ClusterMissing() => false)
  | ClusterMissing() => (case+ expected of | ClusterPreferred() => false | ClusterAlternative() => false | ClusterMissing() => true)
fun check(preferred: !SfntFace,alternative: !SfntFace,ignored: !PropertyMap(8),source: string,expected: NativeClusterFace): int = let
  val bytes=pipeline_bytes(source)
  val errors=case+ text_decode(bytes,buf_len(bytes)) of | ~InvalidTextSpan() => 1
    | ~DecodedText(text) => let val ok=matches(selected(preferred,alternative,ignored,text),expected)
      val ()=scalar_dispose(text) in if ok then 0 else 1 end
  val ()=buf_free(bytes)
in errors end
fun cases(preferred: !SfntFace,alternative: !SfntFace,ignored: !PropertyMap(8)): int =
  check(preferred,alternative,ignored,"A",ClusterPreferred())
  +check(preferred,alternative,ignored,"A̕",ClusterAlternative())
  +check(preferred,alternative,ignored,"😀̕",ClusterMissing())
  +check(preferred,alternative,ignored,"A‍",ClusterPreferred())
fun alternative(preferred: !SfntFace,ignored: !PropertyMap(8)): int = let val bytes=fixture_font(Fixture12())
  val ()=fixture_put32(bytes,164,789) and ()=fixture_put32(bytes,168,789)
in case+ sfnt_parse(bytes) of | InvalidSfnt(e) => let val ()=buf_free(bytes) in 1 end
  | ValidSfnt(info) => let val face=SfntFace(bytes,info) val errors=cases(preferred,face,ignored)
    val ()=sfnt_dispose(face) in errors end end
implement pipeline_coverage_cases(assets) = let
  val+ NativeTextAssets(aux,w,l,e)=assets val+ NativeTextAux(base,s,b,br,m)=aux
  val+ NativeTextBase(data,n,mcm)=base val+ NativeShapeData(db,category,ignored,joining)=data
  val bytes=fixture_font(Fixture12())
in case+ sfnt_parse(bytes) of | InvalidSfnt(e) => let val ()=buf_free(bytes) in 1 end
  | ValidSfnt(info) => let val face=SfntFace(bytes,info) val errors=alternative(face,ignored)
    val ()=sfnt_dispose(face) in errors end end
