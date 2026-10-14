#include "glyph_context_arena_test.hats"
fun capture(arena: &GlyphContextArena >> GlyphContextArena,w: !GlyphContextWindow,m: !GlyphMetadata,
  b: !Buf,run: !GlyphRun(1),node: int,count: int,remaining: &int >> int): GlyphContextChainRead = let
  val+ GlyphRun(phase,meta,s)=run
  val span=glyph_window_gather_limits(b,m,s,meta,@{flags=ligation_test_flags(0),set=0,
    selection= @{kind=GlyphAll(),mask=0u}},node,w,@{back=0,input=count,look=0},remaining)
in glyph_context_arena_capture(arena,w,span,count,remaining) end
fun rebase(arena: &GlyphContextArena >> GlyphContextArena,chain: GlyphContextChain,run: !GlyphRun(1),
  insertion: GlyphContextInsertion,remaining: &int >> int): GlyphContextChainRead = let val+ GlyphRun(phase,meta,s)=run
in glyph_context_arena_rebase(arena,chain,s,meta,insertion,remaining) end
fun sequence(arena: !GlyphContextArena,r: GlyphContextChainRead,ids: string,remaining: &int >> int): int = let
  val expected=ot_fixture_words(ids)
  fun check{n:nat} .<n>. (left: int(n),arena: !GlyphContextArena,chain: GlyphContextChain,
    expected: !Buf,index: int,remaining: &int >> int): int =
    if left = 0 then 0 else let val node=glyph_context_arena_node(arena,chain,index,remaining)
      val error=if reverse_pass_ready(node.status) andalso ieq(node.node,ot_fixture_read16(expected,imul(index,2))) then 0 else 1
    in iadd(error,check(left-1,arena,chain,expected,iadd(index,1),remaining)) end
  val count=idiv(isub(buf_len(expected),8),2)
  val errors=check(airlock_nat(count),arena,r.chain,expected,0,remaining)
  val status=reverse_pass_ready(r.status) andalso ieq(r.chain.count,count)
  val ()=buf_free(expected)
in iadd(errors,if status then 0 else 1) end
fun expanded(arena: &GlyphContextArena >> GlyphContextArena,a: GlyphContextChainRead,c: GlyphContextChainRead,
  source: !GlyphRun(1),remaining: &int >> int,errors: &int >> int): GlyphRun(1) = let
  val clone=glyph_run_clone(source)
  val reserved=run_test_take(glyph_run_reserve(clone,6),run_test_updated,errors)
  val output=buf_make(12)
  val ()=buf_set32(output,0,20) and ()=buf_set32(output,1,21) and ()=buf_set32(output,2,22)
  val run=run_test_take(glyph_run_multiple(reserved,1,output,3),run_test_updated,errors)
  val ()=buf_free(output)
  val insertion: GlyphContextInsertion= @{node=1,first=4,added=2}
  val parent=rebase(arena,a.chain,run,insertion,remaining)
  val child=rebase(arena,c.chain,run,insertion,remaining)
  val ()=errors := errors+sequence(arena,parent,"0000 0001 0004 0005 0002 0003",remaining)
    +sequence(arena,child,"0001 0004 0005 0002 0003",remaining)
  val ids=run_test_indices(0,1)
  val run=run_test_take(glyph_run_ligate(run,ids,2,14),run_test_updated,errors)
  val ()=buf_free(ids)
  val parent=rebase(arena,parent.chain,run,@{node= ~1,first=0,added=0},remaining)
  val child=rebase(arena,child.chain,run,@{node= ~1,first=0,added=0},remaining)
  val ()=errors := errors+sequence(arena,parent,"0000 0004 0005 0002 0003",remaining)
    +sequence(arena,child,"0004 0005 0002 0003",remaining)
in run end
implement context_arena_edits() = let
  var errors: int=0 and remaining: int=4096
  val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val run=ligation_test_run("0005 0006 0007 0008",errors)
  val w=window_test_make(@{back=0,input=4,look=0})
  var arena: GlyphContextArena=glyph_context_arena_make(128)
  val a=capture(arena,w,m,b,run,0,4,remaining)
  val c=capture(arena,w,m,b,run,1,3,remaining)
  val result=expanded(arena,a,c,run,remaining,errors)
  val source=glyph_run_query(run,1) and meta=glyph_run_meta(run) and target=glyph_run_meta(result)
  val ()=if ieq(source.core.glyph,6) andalso ieq(meta.used,4) andalso ieq(meta.live,4)
    andalso ieq(target.used,6) andalso ieq(target.live,5) then () else errors := iadd(errors,1)
  val ()=glyph_run_dispose(result) and ()=glyph_run_dispose(run) and ()=glyph_window_dispose(w)
  val ()=glyph_context_arena_dispose(arena) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
