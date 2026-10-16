#include "font/glyph/core/glyph_unicode_test.hats"
extern fun unicode_glyph_test_failed(): GlyphMetadata = "mac#anth_die_box"
fun scalar_of(index: int): int = case+ index of
  | 0 => 97 | 1 => 768 | 2 => 2307 | 3 => 8413 | 4 => 847 | 5 => 8205 | 6 => 1564 | 7 => 1614 | _ => 0
fun append{n:nat} .<n>. (left: int(n),r: GlyphRun(0),index: int,errors: &int >> int): GlyphRun(0) =
  if left = 0 then r else let
    val seed: GlyphSeed= @{glyph=0,scalar=scalar_of(index),sourceStart=imul(index,4),sourceEnd=imul(iadd(index,1),4),cluster=index,mask=1u}
    val next=run_test_take(glyph_run_append(r,seed),run_test_updated,errors)
  in append(left-1,next,iadd(index,1),errors) end
implement unicode_glyph_test_run(category,ignored,errors) =
  glyph_unicode_prepare(category,ignored,append(8,run_test_nominal(12,0,errors),0,errors))
implement unicode_glyph_test_metadata(b) =
  case+ glyph_metadata_parse(b,@{kind=ChildMissing(),span= @{offset=0,length=0}},3,128) of
  | ~GlyphMetadataRejected(e) => unicode_glyph_test_failed() | ~GlyphMetadataAccepted(m) => glyph_metadata_unicode(m)
