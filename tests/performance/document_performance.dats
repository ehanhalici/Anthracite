(* Usage: document_performance VAULT FILE [read|edit] [jump|wheel|page] *)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "os/fs.sats"
staload "core_runtime/performance.sats"
staload "core_runtime/text_engine_startup.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/resources/font.sats"
staload "data_font/resources/private/font_storage.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/layout_internal.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/render/ui_render.sats"
extern fun finish_gpu(): void = "mac#glFinish"
macdef VIEW_WIDTH_PIXELS = 1280
macdef VIEW_HEIGHT_PIXELS = 800
macdef FONT_SIZE_PIXELS = 18
macdef SCROLL_FRAME_SAMPLES = 60
macdef PREWARM_SAMPLE_INDEX = 9999
macdef BACKGROUND_SAMPLE_INDEX = 9998
(* Deferred wrapping finishes in ~cost/6 ms frames; Debug needs ~70 for the fixture. *)
macdef SETTLE_FRAME_LIMIT = 1000

fun counter(name: string, key: int): void =
  println!("event=performance_counter name=",name," value=",performance_value(key))
fun phase_row(name: string, phase: int): void = let
  val calls = performance_phase_count(phase)
  val total = performance_phase_total(phase)
  val mx = performance_phase_max(phase)
  val () = print!("event=perf_phase name=",name," calls=",calls)
in
  println!(" total_ns=",total," max_ns=",mx)
end
fun report(): void = let
  val ()=counter("document_loads",PERF_DOCUMENT_LOADS)
  val ()=counter("ast_parses",PERF_AST_PARSES)
  val ()=counter("fold_prepares",PERF_FOLD_PREPARES)
  val ()=counter("layout_builds",PERF_LAYOUT_BUILDS)
  val ()=counter("layout_updates",PERF_LAYOUT_UPDATES)
  val ()=counter("wrap_builds",PERF_WRAP_BUILDS)
  val ()=counter("wrap_lines",PERF_WRAP_LINES)
  val ()=counter("width_queries",PERF_WIDTH_QUERIES)
  val ()=counter("shape_calls",PERF_SHAPE_CALLS)
  val ()=counter("shaped_bytes",PERF_SHAPED_BYTES)
  val ()=counter("read_bytes",PERF_READ_BYTES)
  val ()=counter("paint_rows",PERF_PAINT_ROWS)
  val ()=counter("embed_hits",PERF_EMBED_HITS)
  val ()=counter("embed_misses",PERF_EMBED_MISSES)
  val ()=counter("media_index_builds",PERF_MEDIA_INDEX_BUILDS)
  val ()=counter("visual_index_builds",PERF_VISUAL_INDEX_BUILDS)
  val ()=counter("gl_flush_calls",PERF_GL_FLUSH_CALLS)
  val ()=counter("gl_mode_switches",PERF_GL_MODE_SWITCHES)
  val ()=counter("gl_quads",PERF_GL_QUADS)
  val ()=counter("font_atlas_uploads",PERF_FONT_ATLAS_UPLOADS)
  val ()=counter("alloc_calls",PERF_ALLOC_CALLS)
  val ()=counter("alloc_bytes",PERF_ALLOC_BYTES)
  val ()=phase_row("visual_prepare",PERF_PHASE_VISUAL_PREPARE)
  val ()=phase_row("doc_layout",PERF_PHASE_DOC_LAYOUT)
  val ()=phase_row("visual_paint",PERF_PHASE_VISUAL_PAINT)
  val ()=phase_row("rend_flush",PERF_PHASE_REND_FLUSH)
  val ()=phase_row("plat_swap",PERF_PHASE_PLAT_SWAP)
  val ()=phase_row("ast_reparse",PERF_PHASE_AST_REPARSE)
in phase_row("font_glyph",PERF_PHASE_FONT_GLYPH) end

(* Scroll scenarios: jump = scrollbar-like leaps (max/29 px), wheel = the app's
   48 px wheel step down then back up from mid-document, page = one viewport. *)
macdef SCENARIO_JUMP = 0
macdef SCENARIO_WHEEL = 1
macdef SCENARIO_PAGE = 2
macdef WHEEL_STEP_PIXELS = 48
macdef WHEEL_FRAME_SAMPLES = 120
(* Profiler sample tags; match tools/performance/map_c_to_ats.py --tag names. *)
macdef TAG_LOAD = 1
macdef TAG_FIRST = 2
macdef TAG_IDLE = 3
macdef TAG_PREWARM = 4
macdef TAG_SCROLL = 5
macdef TAG_BACKGROUND = 6

fun view_height(): int = isub(VIEW_HEIGHT_PIXELS,UI_TOPBAR_HEIGHT)
fun scenario_name(s: int): string =
  if ieq(s,SCENARIO_WHEEL) then "wheel" else if ieq(s,SCENARIO_PAGE) then "page" else "jump"
fun scenario_frames(s: int): int = if ieq(s,SCENARIO_WHEEL) then WHEEL_FRAME_SAMPLES else SCROLL_FRAME_SAMPLES
fun jump_scroll(step: int,maximum: int): int =
  if ieq(step,isub(SCROLL_FRAME_SAMPLES/2,1)) then maximum
  else imul(idiv(maximum,isub(SCROLL_FRAME_SAMPLES/2,1)),step)
fun scroll_at(s: int,k: int,maximum: int): int =
  if ieq(s,SCENARIO_WHEEL) then let
    val half=WHEEL_FRAME_SAMPLES/2
    val offset=if ilt(k,half) then iadd(k,1) else isub(WHEEL_FRAME_SAMPLES,k)
  in imax(0,imin(maximum,iadd(idiv(maximum,2),imul(WHEEL_STEP_PIXELS,offset)))) end
  else if ieq(s,SCENARIO_PAGE) then imin(maximum,imul(iadd(k,1),view_height()))
  else jump_scroll(imod(k,SCROLL_FRAME_SAMPLES/2),maximum)

(* Returns CPU submit time (draw + rend_flush), GPU wait (glFinish) and swap separately
   so frame totals that are VSync-locked do not hide CPU cost. *)
fun paint(f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,scroll: int): @(lint,lint,lint) = let
  val t0=mono_ns()
  val ()=cache_work_begin(cache)
  val ()=rend_begin(r,VIEW_WIDTH_PIXELS,VIEW_HEIGHT_PIXELS)
  val ()=draw_doc(f,r,d,0,UI_TOPBAR_HEIGHT,VIEW_WIDTH_PIXELS,
    view_height(),scroll,FONT_SIZE_PIXELS,vault,cache,scratch,mode)
  val ()=rend_flush(r)
  val t1=mono_ns()
  (* Untag driver waits: NVIDIA spins in glFinish, which would otherwise swamp
     the profile of the tagged phase with [vdso]/libnvidia samples. *)
  val ()=performance_set_sample_tag(0)
  val ()=finish_gpu()
  val t2=mono_ns()
  val ()=plat_swap(p)
  val t3=mono_ns()
in @(t1-t0,t2-t1,t3-t2) end

fun sample_tag(index: int): int =
  if ieq(index,PREWARM_SAMPLE_INDEX) then TAG_PREWARM else if ieq(index,BACKGROUND_SAMPLE_INDEX) then TAG_BACKGROUND else if ieq(index,0) then TAG_FIRST
  else if ilt(index,3) then TAG_IDLE else TAG_SCROLL

fun sample(f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,scenario: int,index: int,scroll: int): void = let
  val ()=performance_reset()
  val ()=performance_set_sample_tag(sample_tag(index))
  val started=mono_ns()
  val @(cpu,gpu,swap)=paint(f,r,p,d,vault,cache,scratch,mode,scroll)
  val elapsed: lint=mono_ns()-started
  val ()=performance_set_sample_tag(0)
  val tag=sample_tag(index)
  val phase: string=if ieq(tag,TAG_PREWARM) then "prewarm_scroll" else if ieq(tag,TAG_BACKGROUND) then "background"
    else if ieq(tag,TAG_FIRST) then "first" else if ieq(tag,TAG_IDLE) then "warm_idle"
    else if ieq(scenario,SCENARIO_WHEEL) then "warm_scroll_wheel"
    else if ieq(scenario,SCENARIO_PAGE) then "warm_scroll_page" else "warm_scroll_jump"
  val ()=print!("event=document_frame sample=",index," elapsed_ns=",elapsed)
  val ()=print!(" cpu_ns=",cpu," gpu_wait_ns=",gpu," swap_ns=",swap)
  val ()=print_string(" scroll=") val ()=print_int(scroll)
  val ()=print_string(" phase=") val ()=print_string(phase) val ()=print_newline()
  val stats=cache_embed_stats(cache)
  val ()=println!("event=document_geometry height=",doc_layout_cache_height(d)," cached_documents=",stats.documents," pending=",cache_work_pending(cache))
in report() end

fun settle{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,
  cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,scenario: int,index: int,scroll: int): void =
  if not(cache_work_pending(cache)) then () else if left = 0 then exit(1) else let
    val ()=sample(f,r,p,d,vault,cache,scratch,mode,scenario,index,scroll)
  in settle(left-1,f,r,p,d,vault,cache,scratch,mode,scenario,index,scroll) end
(* Prewarm only for jump: it revisits the same 30 positions so warm_scroll_jump measures
   a warm cache. wheel/page deliberately scroll into unvisited rows like a user does. *)
fun prewarm{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,
  cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,index: int): void =
  if left = 0 then () else let
    val maximum=imax(0,isub(doc_layout_cache_height(d),view_height()))
    val scroll=jump_scroll(index,maximum)
    val ()=sample(f,r,p,d,vault,cache,scratch,mode,SCENARIO_JUMP,PREWARM_SAMPLE_INDEX,scroll)
    val ()=settle(SETTLE_FRAME_LIMIT,f,r,p,d,vault,cache,scratch,mode,SCENARIO_JUMP,PREWARM_SAMPLE_INDEX,scroll)
  in prewarm(left-1,f,r,p,d,vault,cache,scratch,mode,iadd(index,1)) end

fun scrolling{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,
  cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,scenario: int,index: int,maximum: int): void =
  if left = 0 then () else let
    val scroll=scroll_at(scenario,index,maximum)
    val ()=sample(f,r,p,d,vault,cache,scratch,mode,scenario,iadd(index,3),scroll)
  in scrolling(left-1,f,r,p,d,vault,cache,scratch,mode,scenario,iadd(index,1),maximum) end
fun frames(f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,scenario: int): void = let
  val ()=sample(f,r,p,d,vault,cache,scratch,mode,scenario,0,0)
  val ()=settle(SETTLE_FRAME_LIMIT,f,r,p,d,vault,cache,scratch,mode,scenario,BACKGROUND_SAMPLE_INDEX,0)
  val ()=sample(f,r,p,d,vault,cache,scratch,mode,scenario,1,0)
  val ()=sample(f,r,p,d,vault,cache,scratch,mode,scenario,2,0)
  val ()=if ieq(scenario,SCENARIO_JUMP) then prewarm(SCROLL_FRAME_SAMPLES/2,f,r,p,d,vault,cache,scratch,mode,0)
  val maximum=imax(0,isub(doc_layout_cache_height(d),view_height()))
  val total=airlock_nat(scenario_frames(scenario))
in scrolling(total,f,r,p,d,vault,cache,scratch,mode,scenario,0,maximum) end

fun benchmark(f: !Font,r: !Rend,p: !Plat,path: string,root: string,mode: ViewMode,scenario: int): bool = let
  val d=doc_open()
  var vault: Buf=buf_make(c_strlen(root))
  val ()=buffer_append_string(vault,root)
  var cache: Cache=CNil()
  var scratch: Buf=buf_make(4096)
  val ()=performance_reset()
  val ()=performance_set_sample_tag(TAG_LOAD)
  val started=mono_ns()
  val loaded=doc_load(d,path)
  val ()=performance_set_sample_tag(0)
  val ()=println!("event=document_load ok=",loaded," elapsed_ns=",mono_ns()-started)
  val ()=report()
  val ()=if loaded then frames(f,r,p,d,vault,cache,scratch,mode,scenario) else ()
  val ()=cache_free(cache)
  val ()=buf_free(scratch)
  val ()=buf_free(vault)
  val ()=doc_free(d)
in loaded end

fun run(): void = let
  val ()=performance_runtime_init()
  val p=plat_open()
in if not(plat_ok(p)) then let val ()=plat_close(p) in exit(1) end else let
  val r=rend_open()
  val f=font_open()
  val ()=font_set_px(f,FONT_SIZE_PIXELS)
  val native=workspace_font_start(f)
  val ()=performance_enable(1)
  val edit=c_argc()>3 andalso c_strcmp(c_argv(3),"edit")=0
  val mode=if edit then ViewEdit else ViewRead
  val mode_name: string=if edit then "edit" else "read"
  val scenario=if c_argc()<=4 then SCENARIO_JUMP
    else if c_strcmp(c_argv(4),"wheel")=0 then SCENARIO_WHEEL
    else if c_strcmp(c_argv(4),"page")=0 then SCENARIO_PAGE else SCENARIO_JUMP
  val ()=print!("event=benchmark_context width=",VIEW_WIDTH_PIXELS," height=",VIEW_HEIGHT_PIXELS,
    " font_px=",font_get_px(f)," native=",native)
  val ()=print_string(" mode=") val ()=print_string(mode_name)
  val ()=print_string(" scenario=") val ()=print_string(scenario_name(scenario)) val ()=print_newline()
  val loaded=if native then benchmark(f,r,p,c_argv(2),c_argv(1),mode,scenario) else false
  val ()=font_free(f)
  val ()=rend_close(r)
  val ()=plat_close(p)
in if native andalso loaded then () else exit(1) end end
implement main0() = if c_argc()<3 then exit(2) else run()
