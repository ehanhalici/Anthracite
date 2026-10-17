#include "font/glyph/core/glyph_unicode_test.hats"
fun table(): Buf = substitution_engine_fixture("0001 0008 0001 0008 0001 0006 0001 0001 0001 0000","0001 0000 0000","0001 0000 0000")
fun rows{n:nat} .<n>. (left: int(n),r: !GlyphRun(1),index: int,errors: int): int =
  if left = 0 then errors else let val row=glyph_run_query(r,index)
    val expected=if ieq(index,1) orelse ieq(index,7) then 0 else 1
    val ok=ieq(row.core.glyph,expected) andalso ieq(row.core.sourceStart,imul(index,4)) andalso ieq(row.core.sourceEnd,imul(iadd(index,1),4))
  in rows(left-1,r,iadd(index,1),iadd(errors,if ok then 0 else 1)) end
fun applied(category: !PropertyMap(6),ignored: !PropertyMap(8)): int = let
  val b=table() val g=substitution_engine_parse(b) val m=unicode_glyph_test_metadata(b)
  var errors: int=0 val source=glyph_run_substitute(unicode_glyph_test_run(category,ignored,errors))
  val r=substitution_engine_take(glyph_substitution_lookup(b,g,m,source,0,@{selection= @{kind=GlyphAll(),mask=0u},alternate=1}),6,errors)
  val errors=iadd(errors,rows(8,r,0,0))
  val ()=glyph_run_dispose(r) and ()=glyph_metadata_dispose(m) and ()=ot_substitution_graph_dispose(g) and ()=buf_free(b)
in errors end
fun unprepared(): int = let
  val b=table() val g=substitution_engine_parse(b) val m=unicode_glyph_test_metadata(b)
  var errors: int=0 val source=glyph_run_substitute(run_test_nominal(2,1,errors))
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_substitution_lookup(b,g,m,source,0,@{selection= @{kind=GlyphAll(),mask=0u},alternate=1})
  val rejected=case+ status of | GlyphPassReference() => true | GlyphPassApplied() => false | GlyphPassDomain() => false | GlyphPassCapacity() => false
  val ok=rejected andalso ieq(visited,0) andalso ieq(matches,0)
  val ()=glyph_run_dispose(r) and ()=glyph_metadata_dispose(m) and ()=ot_substitution_graph_dispose(g) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
fun ligature(category: !PropertyMap(6),ignored: !PropertyMap(8)): int = let
  val b=buf_make(1) val m=unicode_glyph_test_metadata(b) var errors: int=0
  val source=glyph_run_substitute(unicode_glyph_test_run(category,ignored,errors)) val nodes=run_test_indices(0,2)
  val r=run_test_take(glyph_run_ligate(source,nodes,2,5),run_test_updated,errors) val row=glyph_run_query(r,0)
  val p=glyph_metadata_core_property(m,row.core)
  val kind=case+ p.property.kind of | GlyphLigature() => true | GlyphUnclassified() => false
    | GlyphBase() => false | GlyphMark() => false | GlyphComponent() => false
  val ok=kind andalso not(row.core.ignorable) andalso glyph_metadata_run_ready(m,glyph_run_meta(r))
  val ()=glyph_run_dispose(r) and ()=buf_free(nodes) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
fun kind_code(kind: GdefGlyphKind): int = case+ kind of | GlyphUnclassified() => 0 | GlyphBase() => 1
  | GlyphLigature() => 2 | GlyphMark() => 3 | GlyphComponent() => 4
fun expanded(r: !GlyphRun(1),node: int,expected: GdefGlyphKind,ignored: bool): bool = let
  val row=glyph_run_query(r,node)
  val kind=ieq(kind_code(expected),kind_code(row.core.unicodeKind))
in kind andalso (row.core.ignorable = ignored) end
fun multiple(category: !PropertyMap(6),ignored: !PropertyMap(8)): int = let
  var errors: int=0 val output=run_test_indices(7,8)
  val r=glyph_run_substitute(unicode_glyph_test_run(category,ignored,errors))
  val r=run_test_take(glyph_run_multiple(r,1,output,2),run_test_updated,errors)
  val marks=expanded(r,1,GlyphMark(),false) andalso expanded(r,8,GlyphMark(),false)
  val r=run_test_take(glyph_run_multiple(r,5,output,2),run_test_updated,errors)
  val controls=expanded(r,5,GlyphBase(),true) andalso expanded(r,9,GlyphBase(),true)
  val ()=glyph_run_dispose(r) and ()=buf_free(output)
in iadd(errors,if marks andalso controls then 0 else 1) end
fun split_ligature(category: !PropertyMap(6),ignored: !PropertyMap(8)): int = let
  var errors: int=0 val output=run_test_indices(7,8) val nodes=run_test_indices(0,2)
  val r=glyph_run_substitute(unicode_glyph_test_run(category,ignored,errors))
  val r=run_test_take(glyph_run_ligate(r,nodes,2,5),run_test_updated,errors)
  val r=run_test_take(glyph_run_multiple(r,0,output,2),run_test_updated,errors)
  val ok=expanded(r,0,GlyphBase(),false) andalso expanded(r,8,GlyphBase(),false)
  val ()=glyph_run_dispose(r) and ()=buf_free(output) and ()=buf_free(nodes)
in iadd(errors,if ok then 0 else 1) end
implement unicode_glyph_test_substitution(category,ignored) = applied(category,ignored)+unprepared()
  +ligature(category,ignored)+multiple(category,ignored)+split_ligature(category,ignored)
