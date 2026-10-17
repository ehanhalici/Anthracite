#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/search/ui_search.sats"
staload "core_runtime/performance.sats"
implement main0() = if c_argc() <> 3 then exit(2) else let
  var vault=buf_make(0) var query=buf_make(0) var hits=buf_make(0) var meta=buf_make(0) var rows: int=0
  val ()=buffer_append_string(vault,c_argv(1)) val ()=buffer_append_string(query,c_argv(2))
  val before=mem_live() val ()=performance_enable(1) val ()=performance_reset() val started=mono_ns()
  val ()=refresh_search(vault,query,hits,meta,rows) val elapsed=mono_ns()-started
  val ()=println!("event=literal_search_benchmark elapsed_ns=",elapsed," rows=",rows,
    " document_loads=",performance_value(PERF_DOCUMENT_LOADS)," ast_parses=",performance_value(PERF_AST_PARSES),
    " read_bytes=",performance_value(PERF_READ_BYTES))
  val ()=performance_enable(0) val ()=buf_free(vault) val ()=buf_free(query)
  val ()=buf_free(hits) val ()=buf_free(meta)
in () end
