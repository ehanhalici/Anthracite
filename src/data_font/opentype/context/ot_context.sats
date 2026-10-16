staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
fun ot_context_parse{kind:int}(b: !Buf,span: OtSpan,glyphs: int,lookups: int,
  domain: OtLayoutDomain(kind),mode: OtContextMode): OtContextRead(kind)
(* Logical uint32 glyph IDs in the same font domain, with context flags already
   applied by the caller. The current glyph is not filtered out. *)
fun ot_context_match{kind:int}(b: !Buf,program: !OtContextProgram(kind),
  input: !Buf,count: int,start: int): OtContextMatch(kind)
(* inputLimit is the selected input prefix; backtrack/lookahead still see
   their real glyphs. A blocked long rule must allow a later shorter rule,
   without encoding unselected nodes as fabricated/invalid glyph IDs. *)
fun ot_context_match_bounded{kind:int}(b: !Buf,program: !OtContextProgram(kind),
  input: !Buf,count: int,start: int,inputLimit: int): OtContextMatch(kind)
(* Query once at ingestion to size a reusable context window. *)
fun ot_context_limits{kind:int}(b: !Buf,program: !OtContextProgram(kind)): OtContextLimits
fun ot_context_action{kind:int}(b: !Buf,result: OtContextMatch(kind),index: int): OtContextAction(kind)
fun ot_context_dispose{kind:int}(program: OtContextProgram(kind)): void
