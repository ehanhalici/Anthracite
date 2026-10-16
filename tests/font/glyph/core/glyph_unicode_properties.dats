#include "font/glyph/core/glyph_unicode_test.hats"
fun kind_code_of(k: GdefGlyphKind): int = case+ k of | GlyphBase() => 1 | GlyphMark() => 2
  | GlyphLigature() => 3 | GlyphUnclassified() => 0 | GlyphComponent() => 4
fun expected_of(index: int): int = if ieq(index,1) orelse ieq(index,7) then 2 else 1
fun rows{n:nat} .<n>. (left: int(n),b: !Buf,m: !GlyphMetadata,r: !GlyphRun(0),index: int,errors: int): int =
  if left = 0 then errors else let val row=glyph_run_query(r,index) val p=glyph_metadata_core_property(m,row.core)
    val expected=expected_of(index) val control=ige(index,4) andalso ile(index,6)
    val flags= @{rtl=false,ignoreBase=false,ignoreLigature=false,ignoreMarks=true,useMarkSet=false,attachment=0}
    val allowed=glyph_metadata_allows_core(b,m,flags,0,row.core)
    val ok=p.found andalso ieq(kind_code_of(p.property.kind),expected) andalso ieq(row.core.glyph,0)
      andalso (row.core.ignorable = control) andalso (allowed = ine(expected,2))
  in rows(left-1,b,m,r,iadd(index,1),iadd(errors,if ok then 0 else 1)) end
fun priority(category: !PropertyMap(6),ignored: !PropertyMap(8)): int = let
  val b=ligation_test_metadata_bytes() val m=glyph_metadata_unicode(ligation_test_metadata(b))
  var errors: int=0 val r=unicode_glyph_test_run(category,ignored,errors)
  val row=glyph_run_query(r,1) var core: GlyphCore=row.core val ()=core.glyph := 5
  val raw=glyph_metadata_property(m,5) and hinted=glyph_metadata_core_property(m,core)
  val ok=ieq(kind_code_of(raw.property.kind),kind_code_of(hinted.property.kind)) andalso ine(kind_code_of(hinted.property.kind),2)
  val ()=glyph_run_dispose(r) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
implement unicode_glyph_test_properties(category,ignored) = let val b=buf_make(1) val m=unicode_glyph_test_metadata(b)
  var errors: int=0 val r=unicode_glyph_test_run(category,ignored,errors)
  val errors=iadd(errors,rows(8,b,m,r,0,0)) val ready=glyph_metadata_run_ready(m,glyph_run_meta(r))
  val classes=glyph_metadata_has_classes(m)
  val ()=glyph_run_dispose(r) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,iadd(priority(category,ignored),if ready andalso classes then 0 else 1)) end
