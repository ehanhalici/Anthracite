#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef REFRESH_SEARCH_IXF_INITIAL_BYTES = 64
macdef REFRESH_SEARCH_IXS_INITIAL_BYTES = 64
macdef REFRESH_SEARCH_IXP_INITIAL_BYTES = 64
macdef REFRESH_SEARCH_IXB_INITIAL_BYTES = 64
macdef REFRESH_SEARCH_HJUMP_INITIAL_BYTES = 64


staload "mem.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/search/ui_search.sats"
staload "airlock.sats"
staload "os/diag.sats"
staload "data_ast/document/doc.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "search/ix_store.sats"
staload "search/ix_fold.sats"
staload "search/ix_query.sats"
staload "search/ix_build.sats"
staload "search/ix_match.sats"
staload "search/literal/literal_search.sats"
staload "search/results/search_results.sats"
staload "core_runtime/text_engine_startup.sats"

implement literal_pattern_open_default(query) = let
  val location=workspace_text_location() var path=buf_make(0)
  val ()=buffer_append_string(path,location.generated)
  val ()=buffer_append_string(path,"/search-case-map.bin")
  val result=literal_pattern_open(query,buffer_c_string(path)) val ()=buf_free(path)
in result end



fun refresh_files{n:nat} .<n>. (left: int(n),files: !Buf,paths: !Buf,pattern: !LiteralPattern,tabs: !Tabs,
  file: int,hits: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,rows: &int >> _): void =
  if left = 0 then () else if ige(rows,SEARCH_RESULT_LIMIT) then () else let
    val off=ix_file_get(files,file,IX_F_PATHOFF) val length=ix_file_get(files,file,IX_F_PATHLEN)
    var path=buf_make(length) val ()=buffer_append_range(path,paths,off,iadd(off,length))
    val result=search_append_file(path,tabs,pattern,file,hits,meta,jumps,rows) val ()=buf_free(path)
  in refresh_files(left-1,files,paths,pattern,tabs,iadd(file,1),hits,meta,jumps,rows) end
fun refresh_pattern(pattern: LiteralPattern,vault: !Buf,hits: &Buf >> _,meta: &Buf >> _,rows: &int >> _): void = let
  var files=buf_make(0) var paths=buf_make(0) var jumps=buf_make(0) var truncated: int=0
  val ()=ix_walk_vault(vault,files,paths,truncated) val tabs=TNil()
  val ()=refresh_files(airlock_nat(ix_file_count(files)),files,paths,pattern,tabs,0,hits,meta,jumps,rows)
  val ()=tabs_free(tabs) val ()=literal_pattern_free(pattern)
  val ()=buf_free(files) val ()=buf_free(paths)
in buf_free(jumps) end
implement refresh_search(vault,q,hits,meta,rows) = let
  val ()=buffer_clear(hits) val ()=buffer_clear(meta) val ()=rows := 0
in if ieq(buf_len(q),0) then () else case+ literal_pattern_open_default(q) of
  | ~None_vt() => () | ~Some_vt(pattern) => refresh_pattern(pattern,vault,hits,meta,rows) end

implement search_dir(path, q, hits, hmeta, hn, depth) =
  refresh_search(path, q, hits, hmeta, hn)

extern fun hit_head_fuel_exhausted(hmeta: !Buf, r: int): int = "mac#anth_die_int"

fun hit_head_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hmeta: !Buf, r: int): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(r, 0) then ~1
    else if ilt(buf_get32(hmeta, imul(r, 4)), 0) then r
    else hit_head_with_fuel(recfuel - 1, hmeta, isub(r, 1))
  ) else hit_head_fuel_exhausted(hmeta, r)

implement find_hit_file(hmeta, hits, row, dst) = let
  val () = buffer_clear(dst)
  val head_row = hit_head_with_fuel(airlock_nat(MAX_REC_FUEL), hmeta, row)
in
  if ige(head_row, 0) then let
    val off = buf_get32(hmeta, iadd(imul(head_row, 4), 1))
    val n = buf_get32(hmeta, iadd(imul(head_row, 4), 2))
  in
    buffer_append_range(dst, hits, off, iadd(off, n))
  end else ()
end

implement hit_text(hits, off, n, f, r, x, y, c) =
  if ile(n, 0) then 0
  else let
    val cap = buf_cap(hits)
  in
    font_draw_at(f, r, x, y, hits, off, n, c)
  end
