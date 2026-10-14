#include "glyph_context_arena_test.hats"
fun rejected(s: GlyphPassStatus): bool = case+ s of | GlyphPassCapacity() => true
  | GlyphPassReference() => true | GlyphPassDomain() => false | GlyphPassApplied() => false
fun append(arena: &GlyphContextArena >> GlyphContextArena): int = let var remaining: int=4
  val a=glyph_context_arena_append(arena,2,remaining)
  val c=glyph_context_arena_append(arena,3,remaining)
  val overflow=glyph_context_arena_append(arena,4,remaining)
  val chain=glyph_context_chain_push(arena,glyph_context_chain_empty(),a.id)
  val chain=glyph_context_chain_push(arena,chain,c.id)
  val badIndex=glyph_context_arena_node(arena,chain,2,remaining)
  val ()=remaining := 0
  val limited=glyph_context_arena_node(arena,chain,0,remaining)
  val ok=reverse_pass_ready(a.status) andalso reverse_pass_ready(c.status)
    andalso rejected(overflow.status) andalso rejected(badIndex.status) andalso rejected(limited.status)
in if ok then 0 else 1 end
fun reference(arena: &GlyphContextArena >> GlyphContextArena): int = let var errors: int=0 and remaining: int=32
  val r=reverse_pass_run(2,errors)
  val+ GlyphRun(phase,meta,s)=r
  val bad=glyph_context_arena_rebase(arena,@{head=0,tail=1,count=2147483647},s,meta,@{node=0,first=0,added=0},remaining)
  val insert=glyph_context_arena_rebase(arena,@{head=0,tail=1,count=2},s,meta,@{node=0,first=2147483647,added=2},remaining)
  val ()=glyph_context_arena_link(arena,1,0)
  val cycle=glyph_context_arena_rebase(arena,@{head=0,tail=1,count=2},s,meta,@{node=0,first=0,added=0},remaining)
  val ()=glyph_run_dispose(r)
in iadd(errors,if rejected(bad.status) andalso rejected(insert.status) andalso rejected(cycle.status) then 0 else 1) end
implement context_arena_rejections() = let var arena: GlyphContextArena=glyph_context_arena_make(2)
  val errors=append(arena)+reference(arena)
  val ()=glyph_context_arena_reset(arena)
  var remaining: int=1
  val first=glyph_context_arena_append(arena,9,remaining)
  val reset=reverse_pass_ready(first.status) andalso ieq(first.id,0) andalso ieq(remaining,0)
  val ()=glyph_context_arena_dispose(arena)
in iadd(errors,if reset then 0 else 1) end
