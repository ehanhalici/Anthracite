#include "data_font/native_shape_internal.hats"
fun graph(b: !Buf,t: OtLayoutTable(2,0),font: int,glyphs: int): NativePosRead =
  case+ ot_position_graph_parse(b,t,font,glyphs) of
    | ~PositionGraphAccepted(g) => NativePosAccepted(NativePosTables(t,g))
    | ~PositionGraphRejected(e) => let val ()=ot_layout_dispose(t) in NativePosRejected(e) end
implement native_shape_pos_cache(b,info,m,font) = case+ sfnt_table(b,info.tables,TableGpos()) of
  | NoSfntTable() => NativePosAccepted(NativePosMissing())
  | HasSfntTable(span) => (case+ ot_layout_parse(b,span,OtPositioning(),glyph_metadata_capabilities(m)) of
    | ~LayoutRejected(e) => NativePosRejected(e) | ~LayoutAccepted(t) => graph(b,t,font,info.glyphs))
implement native_shape_pos_dispose(t) = case+ t of | ~NativePosMissing() => ()
  | ~NativePosTables(table,g) => let val ()=ot_position_graph_dispose(g) in ot_layout_dispose(table) end

