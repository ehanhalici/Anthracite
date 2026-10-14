#include "data_font/glyph_substitution_lookup_internal.hats"
fun outputs{n:nat} .<n>. (left: int(n),b: !Buf,view: GsubSequenceView,output: !Buf,index: int): void =
  if left = 0 then () else let val ()=buf_set32(output,index,gsub_sequence_glyph(b,view,index))
  in outputs(left-1,b,view,output,iadd(index,1)) end
fun reserve(run: &GlyphRun(1) >> GlyphRun(1),capacity: int): GlyphPassStatus = let
  val+ ~GlyphRunEdited(result,status,node)=glyph_run_reserve(run,capacity)
  val ()=run := result
in glyph_substitution_edit_status(status) end
fun expand(run: &GlyphRun(1) >> GlyphRun(1),node: int,output: !Buf,count: int,next: int,used: int): GlyphSubstitutionStep = let
  val+ ~GlyphRunEdited(result,status,id)=glyph_run_multiple(run,node,output,count)
  val ()=run := result
in glyph_substitution_done(glyph_substitution_edit_status(status),next,true,@{node=node,first=used,added=isub(count,1)}) end
fun execute(b: !Buf,run: &GlyphRun(1) >> GlyphRun(1),node: int,view: GsubSequenceView,output: &Buf >> Buf,maximum: int,
  remaining: &int >> int): GlyphSubstitutionStep = let
  val current=glyph_run_query(run,node) and meta=glyph_run_meta(run)
  val added=isub(view.count,1)
in if ile(view.count,0) then glyph_substitution_fault(GlyphPassReference())
  else if igt(view.count,remaining) orelse igt(added,isub(maximum,meta.used)) orelse not(glyph_storage_capacity(iadd(meta.used,added)))
    then glyph_substitution_fault(GlyphPassCapacity()) else let
      val ()=remaining := isub(remaining,view.count)
      val ()=buf_ensure(output,imul(view.count,4))
      val ()=outputs(airlock_nat(view.count),b,view,output,0)
      val status=reserve(run,iadd(meta.used,added))
    in case+ status of | GlyphPassApplied() => expand(run,node,output,view.count,current.links.next,meta.used)
      | GlyphPassDomain() => glyph_substitution_fault(status) | GlyphPassReference() => glyph_substitution_fault(status)
      | GlyphPassCapacity() => glyph_substitution_fault(status) end end
implement glyph_substitution_multiple(b,e,run,node,output,maximum,remaining) = case+ e of
  | SubstitutionGraphMultiple(h,t) => let val current=glyph_run_query(run,node)
    val view=ot_multiple_lookup_query(b,t,current.core.glyph)
    in if view.matched then execute(b,run,node,view,output,maximum,remaining) else glyph_substitution_unchanged(current.links.next) end
  | SubstitutionGraphVacant() => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphSingle(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphAlternate(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphLigature(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphReverse(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphContext(h,t) => glyph_substitution_fault(GlyphPassReference())
