staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_cov_cache_types.sats"
datatype OtContextAtom = LiteralGlyph | LiteralClass
fun ot_context_missing{kind:int}(domain: OtLayoutDomain(kind)): OtContextMatch(kind)
fun ot_context_result{kind:int}(domain: OtLayoutDomain(kind),pattern: OtContextPattern,rule: int): OtContextMatch(kind)
fun ot_context_pattern_fits(pattern: OtContextPattern,count: int,start: int): bool
fun ot_context_pattern_fits_input(pattern: OtContextPattern,count: int,start: int,inputLimit: int): bool
fun ot_context_atoms_match(b: !Buf,info: OtContextInfo,p: OtContextPattern,input: !Buf,
  start: int,atom: OtContextAtom): bool
fun ot_context_direct_match{kind:int}{n:nat}(b: !Buf,info: OtContextInfo,domain: OtLayoutDomain(kind),
  cache: !OtCoverageCache(n,n),input: !Buf,count: int,start: int,inputLimit: int): OtContextMatch(kind)
fun ot_context_sets_match{kind:int}(b: !Buf,info: OtContextInfo,domain: OtLayoutDomain(kind),
  input: !Buf,count: int,start: int,inputLimit: int,index: int,atom: OtContextAtom): OtContextMatch(kind)
