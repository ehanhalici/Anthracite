staload "mem.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_substitution_graph_types.sats"
(* All referenced GSUB lookup IDs are certified against one complete immutable
   font topology. Context source bytes must outlive this linear cache owner. *)
fun ot_substitution_graph_parse(b: !Buf,table: !OtLayoutTable(1,0),font: int,glyphs: int): OtSubstitutionGraphRead
fun ot_substitution_graph_dispose(graph: OtSubstitutionGraph): void
