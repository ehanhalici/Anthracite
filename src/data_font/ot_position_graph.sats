staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_graph_types.sats"
(* Parse every lookup within one immutable, validated GPOS topology. Context
   action references are certified against that topology's full lookup count.
   Parent font bytes must outlive the resulting graph. *)
fun ot_position_graph_parse(b: !Buf,table: !OtLayoutTable(2,0),font: int,glyphs: int): OtPositionGraphRead
fun ot_position_graph_dispose(graph: OtPositionGraph): void
