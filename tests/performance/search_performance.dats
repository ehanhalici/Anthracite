(* Usage: search_performance VAULT QUERY [REPEAT]
   Runs refresh_search REPEAT times (default 20) and prints one line per run plus
   live-allocation delta, so a single cold run cannot dominate the result. *)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "os/fs.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/search/ui_search.sats"
staload "core_runtime/performance.sats"
extern fun c_atoi(s: string): int = "mac#atoi"
macdef DEFAULT_REPEAT = 20
macdef MAX_REPEAT = 10000

fun run_once(vault: !Buf, query: !Buf, index: int): void = let
  var hits=buf_make(0) var meta=buf_make(0) var rows: int=0
  val ()=performance_reset() val started=mono_ns()
  val ()=refresh_search(vault,query,hits,meta,rows) val elapsed=mono_ns()-started
  val ()=print!("event=literal_search_benchmark run=",index," elapsed_ns=",elapsed," rows=",rows)
  val ()=print!(" document_loads=",performance_value(PERF_DOCUMENT_LOADS)," ast_parses=",performance_value(PERF_AST_PARSES))
  val ()=println!(" read_bytes=",performance_value(PERF_READ_BYTES)," alloc_calls=",performance_value(PERF_ALLOC_CALLS),
    " alloc_bytes=",performance_value(PERF_ALLOC_BYTES))
  val ()=buf_free(hits) val ()=buf_free(meta)
in () end

fun repeat{n:nat} .<n>. (left: int(n), vault: !Buf, query: !Buf, index: int): void =
  if left = 0 then () else let val ()=run_once(vault,query,index)
  in repeat(left-1,vault,query,iadd(index,1)) end

implement main0() = if c_argc() < 3 orelse c_argc() > 4 then exit(2) else let
  val ()=performance_runtime_init()
  val requested=if c_argc() = 4 then c_atoi(c_argv(3)) else DEFAULT_REPEAT
  val count=imax(1,imin(MAX_REPEAT,requested))
  var vault=buf_make(0) var query=buf_make(0)
  val ()=buffer_append_string(vault,c_argv(1)) val ()=buffer_append_string(query,c_argv(2))
  val ()=performance_enable(1)
  val before=mem_live()
  val ()=repeat(airlock_nat(count),vault,query,0)
  val after=mem_live()
  val ()=println!("event=literal_search_memory runs=",count," live_before=",before," live_after=",after,
    " live_delta=",isub(after,before))
  val ()=performance_enable(0) val ()=buf_free(vault) val ()=buf_free(query)
in () end
