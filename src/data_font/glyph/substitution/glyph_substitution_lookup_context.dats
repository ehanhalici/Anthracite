#include "data_font/glyph/substitution/glyph_substitution_lookup_internal.hats"
staload "data_font/opentype/context/ot_context.sats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph_work.sats"
staload "data_font/glyph/pass/glyph_pass_reverse_work.sats"
fun matched(run: !GlyphRun(1),w: !GlyphContextWindow,span: GlyphWindowSpan,result: OtContextMatch(1),
  arena: &GlyphContextArena >> GlyphContextArena,next: int,remaining: &int >> int): GlyphSubstitutionStep =
  if not(result.matched) then glyph_substitution_unchanged(next) else let
    val last=glyph_window_node(w,span,isub(result.inputCount,1))
    val row=glyph_run_query(run,last)
    val chain=glyph_context_arena_capture(arena,w,span,result.inputCount,remaining)
  in if not(ieq(last,~1)) then @{kind=SubstitutionNested(),status=chain.status,next=row.links.next,
    matched=true,context=result,chain=chain.chain,insertion= @{node= ~1,first=0,added=0}}
    else glyph_substitution_fault(GlyphPassReference()) end
fun query(b: !Buf,p: !OtSubstitutionContext,m: !GlyphMetadata,run: !GlyphRun(1),h: OtLookupInfo(1),
  o: GlyphSubstitutionOptions,node: int,w: !GlyphContextWindow,arena: &GlyphContextArena >> GlyphContextArena,
  remaining: &int >> int): GlyphSubstitutionStep = case+ p of
  | SubstitutionContextVacant() => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionContext(program,limits) => let val+ GlyphRun(phase,meta,s)=run
    val links=glyph_storage_links(s,node)
    val span=glyph_window_gather_limits(b,m,s,meta,@{flags=h.flags,set=h.markSet,selection=o.selection},node,w,limits,remaining)
  in case+ span.status of | WindowReady() => matched(run,w,span,glyph_window_match(b,program,w,span),arena,links.next,remaining)
    | WindowSkipped() => glyph_substitution_unchanged(links.next)
    | WindowDomain() => glyph_substitution_fault(GlyphPassDomain())
    | WindowReference() => glyph_substitution_fault(GlyphPassReference())
    | WindowCapacity() => glyph_substitution_fault(GlyphPassCapacity()) end
fun tables{n,i:nat | i <= n} .<n-i>. (index: int(i),b: !Buf,t: !OtSubstitutionContexts(n,n),
  m: !GlyphMetadata,run: !GlyphRun(1),h: OtLookupInfo(1),o: GlyphSubstitutionOptions,node: int,
  w: !GlyphContextWindow,arena: &GlyphContextArena >> GlyphContextArena,remaining: &int >> int): GlyphSubstitutionStep = let
  val+ OtSubstitutionContexts(pf,gc | rows,n,filled)=t
  val current=glyph_run_query(run,node)
in if index = n then glyph_substitution_unchanged(current.links.next)
  else if ile(remaining,0) then glyph_substitution_fault(GlyphPassCapacity()) else let
    val ()=remaining := isub(remaining,1)
    var loan: OtSubstitutionContext=SubstitutionContextVacant()
    val ()=array_exch_at<OtSubstitutionContext>(!rows,i2sz(index),loan)
    val result=query(b,loan,m,run,h,o,node,w,arena,remaining)
    val ()=array_exch_at<OtSubstitutionContext>(!rows,i2sz(index),loan)
    val ()=ot_substitution_context_dispose(loan)
  in case+ result.status of | GlyphPassDomain() => result | GlyphPassReference() => result | GlyphPassCapacity() => result
    | GlyphPassApplied() => if result.matched then result else tables(index+1,b,t,m,run,h,o,node,w,arena,remaining) end end
implement glyph_substitution_context(b,e,m,run,o,node,w,arena,remaining) = case+ e of
  | SubstitutionGraphContext(h,t) => tables(0,b,t,m,run,h,o,node,w,arena,remaining)
  | SubstitutionGraphVacant() => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphSingle(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphMultiple(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphAlternate(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphLigature(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphReverse(h,t) => glyph_substitution_fault(GlyphPassReference())
