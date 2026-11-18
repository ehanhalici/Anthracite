(* Usage: parallel_wrap_contracts FILE REPEAT
   Parallel line shaping must equal the sequential one exactly. FILE is opened
   twice per run: once wrapped on the main thread only (ANTHRACITE_PARALLEL_WRAP=0),
   once with the viewport band on the main thread and every other line shaped by
   workers. Rows, line y/step and node y/height must match. The worker count
   comes from ANTHRACITE_WORKERS; ANTHRACITE_THREAD_JITTER=1 randomizes timing.
   Exit 77 without an X display. *)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "os/fs.sats"
staload "core_runtime/performance.sats"
staload "core_runtime/text_engine_startup.sats"
staload "core_runtime/workers.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/resources/font_document_metrics.sats"
staload "data_font/resources/private/font_storage.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/doc_visual.sats"
staload "data_ast/layout/layout_internal.sats"
staload "data_ast/layout/visual_rows.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/visual/visual_layout.sats"
extern fun set_env(name: string,value: string,overwrite: int): int = "mac#setenv"
extern fun pause_microseconds(us: int): int = "mac#usleep"
extern fun c_atoi(s: string): int = "mac#atoi"
macdef WIDTH_PIXELS = 850
macdef VIEW_PIXELS = 776
macdef DRAIN_STEPS = 50000
macdef DRAIN_PAUSE_MICROSECONDS = 100

fun same_row(a: VisualRow,b: VisualRow): bool =
  ieq(a.start,b.start) andalso ieq(a.finish,b.finish) andalso ieq(a.width,b.width) andalso ieq(a.line,b.line)
  andalso ieq(a.ordinal,b.ordinal) andalso ieq(a.px,b.px) andalso ieq(a.height,b.height)
  andalso ieq(a.ascent,b.ascent) andalso ieq(a.top,b.top)
fun same_rows{n:nat} .<n>. (left: int(n),a: !VisualRows,b: !VisualRows,i: int): int =
  if left = 0 then 0 else iadd(if same_row(visual_rows_at(a,i),visual_rows_at(b,i)) then 0 else 1,same_rows(left-1,a,b,iadd(i,1)))
fun compare_rows{x,y:bool}(a: !option_vt(VisualRows,x),b: !option_vt(VisualRows,y)): int = case+ a of
  | None_vt() => 1 | Some_vt(ra) => (case+ b of | None_vt() => 1 | Some_vt(rb) => let
      val+ VisualRows(t1,m1,l1,d1,n1,k1,p1)=ra val+ VisualRows(t2,m2,l2,d2,n2,k2,p2)=rb
    in if ine(n1,n2) then 1 else same_rows(airlock_nat(n1),ra,rb,0) end)
fun same_lines{n:nat} .<n>. (left: int(n),a: !Doc,b: !Doc,i: int): int =
  if left = 0 then 0 else iadd(if ieq(doc_line_y(a,i),doc_line_y(b,i)) andalso ieq(doc_line_step(a,i),doc_line_step(b,i)) then 0 else 1,
    same_lines(left-1,a,b,iadd(i,1)))
fun same_nodes{n:nat} .<n>. (left: int(n),a: !Doc,b: !Doc,i: int): int =
  if left = 0 then 0 else iadd(if ieq(doc_node_y(a,i),doc_node_y(b,i)) andalso ieq(doc_node_height(a,i),doc_node_height(b,i)) then 0 else 1,
    same_nodes(left-1,a,b,iadd(i,1)))

fun drain{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,d: !Doc,view: VisualViewport,lh: int): int =
  if ile(visual_layout_pending(d),0) then 0 else if left = 0 then 1 else let
    val ()=visual_layout_background(f,r,d,WIDTH_PIXELS,ViewRead,view,1000000L)
    val _=doc_layout_mode(d,lh,1,WIDTH_PIXELS)
    val _=pause_microseconds(DRAIN_PAUSE_MICROSECONDS)
  in drain(left-1,f,r,d,view,lh) end

fun shaped(f: !Font,r: !Rend,path: string,lh: int,parallel: string): Doc = let
  val _=set_env("ANTHRACITE_PARALLEL_WRAP",parallel,1)
  val d=doc_open() val _=doc_load(d,path) val ()=doc_set_caret_move(d,0)
  val view: VisualViewport= @{anchorLine= ~1,offset=0,height=VIEW_PIXELS}
  val _=visual_layout_prepare_band(f,r,d,WIDTH_PIXELS,ViewRead,lh,view)
  val _=drain(airlock_nat(DRAIN_STEPS),f,r,d,view,lh)
  val _=doc_layout_mode(d,lh,1,WIDTH_PIXELS)
in d end

fun compare_docs(a: !Doc,b: !Doc,lh: int): int = let
  val ra=doc_visual_take(a) val rb=doc_visual_take(b)
  val rows=compare_rows(ra,rb)
  val ()=doc_visual_put(a,ra) val ()=doc_visual_put(b,rb)
  val lines=if ine(doc_nlines(a),doc_nlines(b)) then 1 else same_lines(airlock_nat(doc_nlines(a)),a,b,0)
  val nodes=if ine(doc_nnodes(a),doc_nnodes(b)) then 1 else same_nodes(airlock_nat(doc_nnodes(a)),a,b,0)
  val pending=iadd(visual_layout_pending(a),visual_layout_pending(b))
in iadd(iadd(rows,pending),iadd(lines,nodes)) end

fun runs{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,path: string,lh: int,reference: !Doc,i: int): int =
  if left = 0 then 0 else let
    val started=mono_ns()
    val d=shaped(f,r,path,lh,"1")
    val elapsed=mono_ns()-started
    val errors=compare_docs(reference,d,lh)
    val ()=println!("event=parallel_wrap_run run=",i," errors=",errors," elapsed_ns=",elapsed)
    val ()=doc_free(d)
  in iadd(errors,runs(left-1,f,r,path,lh,reference,iadd(i,1))) end

fun checked(f: !Font,r: !Rend): int = let
  val lh=font_document_line_height(f,font_line_h(f))
  val started=mono_ns()
  val reference=shaped(f,r,c_argv(1),lh,"0")
  val sequential=mono_ns()-started
  val before=mem_live()
  val errors=runs(airlock_nat(imax(1,c_atoi(c_argv(2)))),f,r,c_argv(1),lh,reference,0)
  val leaked=isub(mem_live(),before)
  val ()=println!("event=parallel_wrap_contracts workers=",workers_count()," errors=",errors,
    " live_delta=",leaked," sequential_ns=",sequential)
  val ()=println!("event=parallel_wrap_pool jobs=",workers_total(WORKER_TOTAL_JOBS)," steals=",workers_total(WORKER_TOTAL_STEALS),
    " busy_ns=",workers_total(WORKER_TOTAL_BUSY_NS)," cycles=",workers_total(WORKER_TOTAL_CYCLES),
    " instructions=",workers_total(WORKER_TOTAL_INSTRUCTIONS)," cache_misses=",workers_total(WORKER_TOTAL_CACHE_MISSES))
  val ()=doc_free(reference)
in iadd(errors,if ieq(leaked,0) then 0 else 1) end

implement main0() = if ine(c_argc(),3) then exit(2) else let
  val p=plat_open()
in if not(plat_ok(p)) then let val ()=plat_close(p) in exit(77) end else let
  val r=rend_open() val f=font_open() val ()=font_set_px(f,18)
  val native=workspace_font_start(f)
  val errors=if native then checked(f,r) else 1
  val ()=font_free(f) val ()=rend_close(r) val ()=plat_close(p)
in if igt(errors,0) then exit(1) else () end end
