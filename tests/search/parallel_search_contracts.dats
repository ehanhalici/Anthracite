(* Usage: parallel_search_contracts VAULT REPEAT QUERY...
   For every query: the sequential search (ANTHRACITE_PARALLEL_SEARCH=0) and
   REPEAT parallel runs must produce byte-identical hits, metadata and row
   counts. Prints one line per query; exits 1 on any mismatch or leak. *)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "os/fs.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/search/ui_search.sats"
staload "core_runtime/workers.sats"
extern fun c_atoi(s: string): int = "mac#atoi"
extern fun set_env(name: string,value: string,overwrite: int): int = "mac#setenv"

fun same(a: !Buf,b: !Buf): bool = buffer_equal_from(a,b,0)
fun search(vault: !Buf,query: !Buf,hits: &Buf >> _,meta: &Buf >> _): int = let var rows: int=0
  val ()=refresh_search(vault,query,hits,meta,rows) in rows end

fun parallel_runs{n:nat} .<n>. (left: int(n),vault: !Buf,query: !Buf,hits: !Buf,meta: !Buf,rows: int): int =
  if left = 0 then 0 else let
    var h=buf_make(0) var m=buf_make(0) val r=search(vault,query,h,m)
    val same_hits=same(h,hits) val same_meta=same(m,meta)
    val bad=if ieq(r,rows) andalso same_hits andalso same_meta then 0 else 1
    val ()=buf_free(h) val ()=buf_free(m)
  in iadd(bad,parallel_runs(left-1,vault,query,hits,meta,rows)) end

fun one_query(vault: !Buf,text: string,repeat: int): int = let
  var query=buf_make(0) val ()=buffer_append_string(query,text)
  val _=set_env("ANTHRACITE_PARALLEL_SEARCH","0",1)
  var hits=buf_make(0) var meta=buf_make(0) val rows=search(vault,query,hits,meta)
  val _=set_env("ANTHRACITE_PARALLEL_SEARCH","1",1)
  val started=mono_ns()
  val mismatches=parallel_runs(airlock_nat(imax(1,repeat)),vault,query,hits,meta,rows)
  val elapsed=mono_ns()-started
  val ()=print!("event=parallel_search query_bytes=",buf_len(query)," rows=",rows," hit_bytes=",buf_len(hits))
  val ()=println!(" runs=",repeat," mismatches=",mismatches," workers=",workers_count()," parallel_ns=",elapsed)
  val ()=buf_free(hits) val ()=buf_free(meta) val ()=buf_free(query)
in mismatches end

fun queries{n:nat} .<n>. (left: int(n),vault: !Buf,i: int,repeat: int): int =
  if left = 0 then 0 else iadd(one_query(vault,c_argv(i),repeat),queries(left-1,vault,iadd(i,1),repeat))

implement main0() = if c_argc() < 4 then exit(2) else let
  val _=workers_ensure()
  var vault=buf_make(0) val ()=buffer_append_string(vault,c_argv(1))
  val before=mem_live()
  val errors=queries(airlock_nat(isub(c_argc(),3)),vault,3,c_atoi(c_argv(2)))
  val leaked=isub(mem_live(),before)
  val ()=println!("event=parallel_search_contracts errors=",errors," live_delta=",leaked)
  val ()=buf_free(vault)
in if igt(errors,0) orelse ine(leaked,0) then exit(1) else () end
