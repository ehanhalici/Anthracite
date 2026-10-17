#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "search/literal/literal_search.sats"
staload "search/results/search_results.sats"
staload "ui_workspace/common/ui_common.sats"
fun bytes(text: string): Buf = let var b=buf_make(0) val ()=buffer_append_string(b,text) in b end
fun offsets(meta: !Buf,jumps: !Buf): bool = search_row_is_header(meta,0)
  andalso ieq(buf_get32(jumps,iadd(SEARCH_JUMP_WORDS,SEARCH_JUMP_LINE)),1)
  andalso ieq(buf_get32(jumps,iadd(imul(2,SEARCH_JUMP_WORDS),SEARCH_JUMP_COLUMN)),7)
fun result_case(pattern: LiteralPattern): int = let
  val source=bytes("İLK\nİĞNE iğne\nson") val path=bytes("group.md")
  var hits=buf_make(0) var meta=buf_make(0) var jumps=buf_make(0) var collapsed=buf_make(0) var rows: int=0
  val first=search_append_matches(source,path,pattern,3,hits,meta,jumps,rows)
  val positions=offsets(meta,jumps)
  val mapped=ieq(first.matches,2) andalso ieq(rows,3) andalso positions
  val next=search_next_result(meta,~1,1) val previous=search_next_result(meta,1,~1)
  val before=search_visible_count(meta,collapsed) val closed=search_toggle_group(meta,collapsed,0)
  val hidden=search_visible_count(meta,collapsed) val missing=search_source_row(meta,collapsed,1)
  val opened=search_toggle_group(meta,collapsed,0) val after=search_visible_count(meta,collapsed)
  val child=search_source_row(meta,collapsed,2) val no_group=search_toggle_group(meta,collapsed,1)
  val good=mapped andalso ieq(next,1) andalso ieq(previous,2) andalso ieq(before,3) andalso closed
    andalso ieq(hidden,1) andalso ieq(missing,~1) andalso opened andalso ieq(after,3) andalso ieq(child,2)
  val ()=literal_pattern_free(pattern) val ()=buf_free(source) val ()=buf_free(path)
  val ()=buf_free(hits) val ()=buf_free(meta) val ()=buf_free(jumps) val ()=buf_free(collapsed)
in if good andalso not(no_group) then 0 else 1 end
implement main0() = let
  val before=mem_live() val query=bytes("iğne")
  val errors=case+ literal_pattern_open(query,c_argv(1)) of | ~None_vt() => 1 | ~Some_vt(pattern) => result_case(pattern)
  val ()=buf_free(query)
in if igt(errors,0) orelse ine(before,mem_live()) then exit(1) else () end
