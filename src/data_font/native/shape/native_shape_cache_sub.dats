#include "data_font/native/shape/native_shape_internal.hats"
fun graph(b: !Buf,t: OtLayoutTable(1,0),font: int,glyphs: int): NativeSubRead =
  case+ ot_substitution_graph_parse(b,t,font,glyphs) of
    | ~SubstitutionGraphAccepted(g) => NativeSubAccepted(NativeSubTables(t,g))
    | ~SubstitutionGraphRejected(e) => let val ()=ot_layout_dispose(t) in NativeSubRejected(e) end
implement native_shape_sub_cache(b,info,m,font) = case+ sfnt_table(b,info.tables,TableGsub()) of
  | NoSfntTable() => NativeSubAccepted(NativeSubMissing())
  | HasSfntTable(span) => (case+ ot_layout_parse(b,span,OtSubstitution(),glyph_metadata_capabilities(m)) of
    | ~LayoutRejected(e) => NativeSubRejected(e) | ~LayoutAccepted(t) => graph(b,t,font,info.glyphs))
implement native_shape_sub_dispose(t) = case+ t of | ~NativeSubMissing() => ()
  | ~NativeSubTables(table,g) => let val ()=ot_substitution_graph_dispose(g) in ot_layout_dispose(table) end
