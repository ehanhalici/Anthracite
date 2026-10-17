#include "font/glyph/substitution/glyph_substitution_cache_test.hats"
fun graph(b: !Buf,t: !OtLayoutTable(1,0),glyphs: int): int =
  case+ ot_substitution_graph_parse(b,t,3,glyphs) of | ~SubstitutionGraphRejected(e) => let
    val ()=println!("event=substitution_font_cache reason=rejected offset=",e.offset)
  in 1 end | ~SubstitutionGraphAccepted(g) => let val ()=ot_substitution_graph_dispose(g) in 0 end
fun layout(b: !Buf,span: OtSpan,glyphs: int): int =
  case+ ot_layout_parse(b,span,OtSubstitution(),@{classes=true,attachments=true,markSets=WORD16_MAX_VALUE}) of
    | ~LayoutRejected(e) => 1 | ~LayoutAccepted(t) => let val error=graph(b,t,glyphs)
      val ()=ot_layout_dispose(t) in error end
fun face(f: !SfntFace): int = let val+ SfntFace(b,info)=f
in case+ sfnt_table(b,info.tables,TableGsub()) of
  | ~NoSfntTable() => 1 | ~HasSfntTable(span) => layout(b,span,info.glyphs) end
fun font(path: string): int = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let
    val error=face(f) val ()=sfnt_dispose(f)
  in error end
implement substitution_cache_fonts(latin,arabic) = font(latin)+font(arabic)
