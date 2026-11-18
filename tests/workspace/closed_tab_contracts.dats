(* Closed-tab document cache (ClosedDocs, ui_tab.sats):
   - reopening an unchanged file after closing its tab loads nothing and
     returns the kept document (same identity, same text);
   - a file changed on disk after closing is loaded again;
   - ANTHRACITE_TAB_CACHE=0 keeps nothing;
   - clearing the cache frees everything (main-thread live bytes balance). *)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "os/fs.sats"
staload "os/selftest_fixture.sats"
staload "data_ast/document/doc.sats"
staload "core_runtime/performance.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/tabs/ui_tab.sats"
extern fun set_env(name: string,value: string,overwrite: int): int = "mac#setenv"
extern fun pause_microseconds(us: int): int = "mac#usleep"
(* mtime has one-second resolution in the stamp used by some file systems. *)
macdef MTIME_STEP_MICROSECONDS = 1100000

fun write_text(path: !Buf,text: string): void = let var b=buf_make(0) val ()=buffer_append_string(b,text)
  val n=buf_len(b) val _=fs_write_buf(buf_cstr(path),b,n) in buf_free(b) end
fun path_copy(path: !Buf): Buf = let val n=buf_len(path) var c=buf_make(imax(1,n)) val ()=buf_append_at(c,path,0,n) in c end
fun head_identity(ts: !Tabs): ptr = case+ ts of | TNil() => the_null_ptr | TCons(d,p,t,s,r) => doc_identity(d)
fun head_length(ts: !Tabs): int = case+ ts of | TNil() => ~1 | TCons(d,p,t,s,r) => doc_len(d)

(* Opens path in a fresh tab list and reports (document loads, identity, length). *)
fun open_once(path: !Buf,kept: &ClosedDocs >> _): @(int,ptr,int,Tabs) = let
  val ()=performance_reset()
  val ts=tabs_open_kept(TNil(),path_copy(path),kept)
in @(if performance_value(PERF_DOCUMENT_LOADS) = 0ULL then 0 else 1,head_identity(ts),head_length(ts),ts) end

fun cycle(path: !Buf,kept: &ClosedDocs >> _): @(int,ptr,int) = let
  val @(loads,identity,length,ts)=open_once(path,kept)
  val ts=tabs_drop_kept(ts,0,kept)
  val ()=tabs_free(ts)
in @(loads,identity,length) end

implement main0() = let
  var root=buf_make(0) val ok=selftest_fixture_open(root)
  val path=selftest_fixture_path(buf_cstr(root),"closed-tab.md")
  val ()=write_text(path,"# Kept\nfirst version of the note\n")
  val ()=performance_enable(1)
  val before=mem_live()
  var kept: ClosedDocs=ClosedNone()
  val @(loads1,id1,len1)=cycle(path,kept)
  val @(loads2,id2,len2)=cycle(path,kept)
  val reused=ieq(loads1,1) andalso ieq(loads2,0) andalso id1 = id2 andalso ieq(len1,len2)
  val _=pause_microseconds(MTIME_STEP_MICROSECONDS)
  val ()=write_text(path,"# Changed\nsecond, longer version of the same note\n")
  val @(loads3,id3,len3)=cycle(path,kept)
  val reloaded=ieq(loads3,1) andalso igt(len3,len2)
  val _=set_env("ANTHRACITE_TAB_CACHE","0",1)
  val ()=closed_docs_free(kept) val ()=kept := ClosedNone()
  val @(a,ida,la)=cycle(path,kept) val @(b,idb,lb)=cycle(path,kept)
  val disabled=ieq(a,1) andalso ieq(b,1) andalso ieq(closed_docs_count(kept),0)
  val ()=closed_docs_free(kept)
  val balanced=ieq(mem_live(),before)
  val ()=println!("event=closed_tab_contracts reused=",reused," reloaded=",reloaded," disabled=",disabled,
    " balanced=",balanced," loads=",loads1,",",loads2,",",loads3)
  val _=fs_unlink(buf_cstr(path)) val ()=buf_free(path) val ()=buf_free(root)
in if ok andalso reused andalso reloaded andalso disabled andalso balanced then () else exit(1) end
