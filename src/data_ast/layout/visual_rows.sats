staload "mem.sats"
staload "data_font/text/span/font_span_types.sats"
macdef VISUAL_ROW_WORDS = 5
macdef VISUAL_ROW_START = 0
macdef VISUAL_ROW_FINISH = 1
macdef VISUAL_ROW_WIDTH = 2
macdef VISUAL_ROW_LINE = 3
macdef VISUAL_ROW_ORDINAL = 4
macdef VISUAL_ROW_MAX_COUNT = 107374180
macdef VISUAL_ROW_SEARCH_FUEL = 32
datatype VisualProjection = VisualSource | VisualRendered
typedef VisualKey = @{version=int,width=int,px=int,height=int,ascent=int,primary=int,fallback=int,primaryGeneration=int,fallbackGeneration=int,projection=VisualProjection,sourceStart=int,sourceFinish=int}
typedef VisualRow = @{start=int,finish=int,width=int,line=int,ordinal=int}
datavtype VisualPlanSlot = VisualPlanEmpty | VisualPlanOwned of (int,FontSpanLayout,llint)
datavtype VisualPlans = {n:nat}{l:addr} VisualPlans of
  (array_v(VisualPlanSlot,l,n),mfree_gc_v(l) | ptr(l),int(n))
datavtype VisualRows = VisualRows of (Buf,Buf,Buf,Buf,int,VisualKey,VisualPlans)
fun visual_plans_make(count: int): VisualPlans
fun visual_plans_take(plans: !VisualPlans,row: int): Option_vt(FontSpanLayout)
fun visual_plans_put(plans: !VisualPlans,row: int,layout: FontSpanLayout): void
fun visual_plans_dispose(plans: VisualPlans): void
fun visual_plans_bytes(plans: !VisualPlans): llint
fun visual_rows_dispose(rows: VisualRows): void
fun visual_rows_matches(rows: !VisualRows,key: VisualKey): bool
fun visual_key_context_matches(a: VisualKey,b: VisualKey): bool
fun visual_rows_count(rows: !VisualRows,line: int): int
fun visual_rows_at(rows: !VisualRows,index: int): VisualRow
fun visual_rows_offset(rows: !VisualRows,source: int): int
fun visual_rows_find(rows: !VisualRows,offset: int): int
fun visual_rows_append(rows: &VisualRows >> VisualRows,row: VisualRow): void
