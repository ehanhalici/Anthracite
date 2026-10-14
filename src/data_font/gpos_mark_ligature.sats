staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_ligature_types.sats"
fun gpos_mark_ligature_parse(b: !Buf,span: OtSpan,glyphs: int): GposMarkLigatureRead
(* component is zero-based and in logical order, even for RTL text. Source-run
   GSUB associations select it; this reader never guesses a last component. *)
fun gpos_mark_ligature_query(b: !Buf,table: !GposMarkLigature,mark: int,target: int,component: int): GposMarkLigatureView
fun gpos_mark_ligature_dispose(table: GposMarkLigature): void
fun gpos_mark_ligature_glyphs(table: !GposMarkLigature): int
fun gpos_mark_ligature_components(b: !Buf,table: !GposMarkLigature,target: int): int
