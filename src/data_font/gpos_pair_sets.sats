staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_pair_types.sats"
fun gpos_pair_sets_make{n:nat}(count: int(n)): GposPairSets(n,0)
fun gpos_pair_sets_count{n,i:nat}(sets: !GposPairSets(n,i)): int(n)
fun gpos_pair_sets_filled{n,i:nat}(sets: !GposPairSets(n,i)): int(i)
fun gpos_pair_sets_append{n,i:nat | i < n}(sets: GposPairSets(n,i),value: GposPairSet): GposPairSets(n,i+1)
fun gpos_pair_sets_get{n:nat}(sets: !GposPairSets(n,n),index: int): GposPairSet
fun gpos_pair_sets_dispose{n,i:nat}(sets: GposPairSets(n,i)): void
fun gpos_pair_sets_read(b: !Buf,s: OtSpan,count: int,formats: GposPairFormat,glyphs: int): GposPairSetRead
