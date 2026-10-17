#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
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
macdef PREWARM_SAMPLE_INDEX = 63
macdef SETTLE_FRAME_LIMIT = 64

fun counter(name: string, key: int): void =
  println!("event=performance_counter name=",name," value=",performance_value(key))
fun report(): void = let
  val ()=counter("document_loads",PERF_DOCUMENT_LOADS)
  val ()=counter("ast_parses",PERF_AST_PARSES)
  val ()=counter("fold_prepares",PERF_FOLD_PREPARES)
  val ()=counter("layout_builds",PERF_LAYOUT_BUILDS)
  val ()=counter("wrap_builds",PERF_WRAP_BUILDS)
  val ()=counter("width_queries",PERF_WIDTH_QUERIES)
  val ()=counter("shape_calls",PERF_SHAPE_CALLS)
  val ()=counter("shaped_bytes",PERF_SHAPED_BYTES)
  val ()=counter("read_bytes",PERF_READ_BYTES)
  val ()=counter("paint_rows",PERF_PAINT_ROWS)
  val ()=counter("embed_hits",PERF_EMBED_HITS)
  val ()=counter("embed_misses",PERF_EMBED_MISSES)
  val ()=counter("media_index_builds",PERF_MEDIA_INDEX_BUILDS)
in counter("visual_index_builds",PERF_VISUAL_INDEX_BUILDS) end

fun paint(f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,scroll: int): void = let
  val ()=cache_work_begin(cache)
  val ()=rend_begin(r,VIEW_WIDTH_PIXELS,VIEW_HEIGHT_PIXELS)
  val ()=draw_doc(f,r,d,0,UI_TOPBAR_HEIGHT,VIEW_WIDTH_PIXELS,
    isub(VIEW_HEIGHT_PIXELS,UI_TOPBAR_HEIGHT),scroll,FONT_SIZE_PIXELS,vault,cache,scratch,mode)
  val ()=rend_flush(r)
  val ()=finish_gpu()
in plat_swap(p) end

fun sample(f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,index: int,scroll: int): void = let
  val ()=performance_reset()
  val started=mono_ns()
  val ()=paint(f,r,p,d,vault,cache,scratch,mode,scroll)
  val elapsed: lint=mono_ns()-started
  val phase: string=if ieq(index,PREWARM_SAMPLE_INDEX) then "prewarm_scroll"
    else if ieq(index,0) then "first" else if ilt(index,3) then "warm_idle" else "warm_scroll"
  val ()=print!("event=document_frame sample=",index," elapsed_ns=",elapsed)
  val ()=print_string(" scroll=") val ()=print_int(scroll)
  val ()=print_string(" phase=") val ()=print_string(phase) val ()=print_newline()
  val stats=cache_embed_stats(cache)
  val ()=println!("event=document_geometry height=",doc_layout_cache_height(d)," cached_documents=",stats.documents," pending=",cache_work_pending(cache))
in report() end

fun settle{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,
  cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,scroll: int): void =
  if not(cache_work_pending(cache)) then () else if left = 0 then exit(1) else let
    val ()=sample(f,r,p,d,vault,cache,scratch,mode,PREWARM_SAMPLE_INDEX,scroll)
  in settle(left-1,f,r,p,d,vault,cache,scratch,mode,scroll) end
fun prewarm{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,
  cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,index: int): void =
  if left = 0 then () else let
    val maximum=imax(0,isub(doc_layout_cache_height(d),isub(VIEW_HEIGHT_PIXELS,UI_TOPBAR_HEIGHT)))
    val scroll=if ieq(index,isub(SCROLL_FRAME_SAMPLES/2,1)) then maximum
      else imul(idiv(maximum,isub(SCROLL_FRAME_SAMPLES/2,1)),index)
    val ()=sample(f,r,p,d,vault,cache,scratch,mode,PREWARM_SAMPLE_INDEX,scroll)
    val ()=settle(SETTLE_FRAME_LIMIT,f,r,p,d,vault,cache,scratch,mode,scroll)
  in prewarm(left-1,f,r,p,d,vault,cache,scratch,mode,iadd(index,1)) end

fun scrolling{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,
  cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,index: int,maximum: int): void =
  if left = 0 then () else let
    val step=imod(index,SCROLL_FRAME_SAMPLES/2)
    val scroll=if ieq(step,isub(SCROLL_FRAME_SAMPLES/2,1)) then maximum
      else imul(idiv(maximum,isub(SCROLL_FRAME_SAMPLES/2,1)),step)
    val ()=sample(f,r,p,d,vault,cache,scratch,mode,iadd(index,3),scroll)
  in scrolling(left-1,f,r,p,d,vault,cache,scratch,mode,iadd(index,1),maximum) end
fun frames(f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode): void = let
  val ()=sample(f,r,p,d,vault,cache,scratch,mode,0,0)
  val ()=settle(SETTLE_FRAME_LIMIT,f,r,p,d,vault,cache,scratch,mode,0)
  val ()=sample(f,r,p,d,vault,cache,scratch,mode,1,0)
  val ()=sample(f,r,p,d,vault,cache,scratch,mode,2,0)
  val ()=prewarm(SCROLL_FRAME_SAMPLES/2,f,r,p,d,vault,cache,scratch,mode,0)
  val maximum=imax(0,isub(doc_layout_cache_height(d),isub(VIEW_HEIGHT_PIXELS,UI_TOPBAR_HEIGHT)))
in scrolling(SCROLL_FRAME_SAMPLES,f,r,p,d,vault,cache,scratch,mode,0,maximum) end

fun benchmark(f: !Font,r: !Rend,p: !Plat,path: string,root: string,mode: ViewMode): bool = let
  val d=doc_open()
  var vault: Buf=buf_make(c_strlen(root))
  val ()=buffer_append_string(vault,root)
  var cache: Cache=CNil()
  var scratch: Buf=buf_make(4096)
  val ()=performance_reset()
  val started=mono_ns()
  val loaded=doc_load(d,path)
  val ()=println!("event=document_load ok=",loaded," elapsed_ns=",mono_ns()-started)
  val ()=report()
  val ()=if loaded then frames(f,r,p,d,vault,cache,scratch,mode) else ()
  val ()=cache_free(cache)
  val ()=buf_free(scratch)
  val ()=buf_free(vault)
  val ()=doc_free(d)
in loaded end

fun run(): void = let
  val p=plat_open()
in if not(plat_ok(p)) then let val ()=plat_close(p) in exit(1) end else let
  val r=rend_open()
  val f=font_open()
  val ()=font_set_px(f,FONT_SIZE_PIXELS)
  val native=workspace_font_start(f)
  val ()=println!("event=benchmark_context width=",VIEW_WIDTH_PIXELS," height=",VIEW_HEIGHT_PIXELS,
    " font_px=",font_get_px(f)," native=",native)
  val ()=performance_enable(1)
  val mode=if c_argc()>3 andalso c_strcmp(c_argv(3),"edit")=0 then ViewEdit else ViewRead
  val loaded=if native then benchmark(f,r,p,c_argv(2),c_argv(1),mode) else false
  val ()=font_free(f)
  val ()=rend_close(r)
  val ()=plat_close(p)
in if native andalso loaded then () else exit(1) end end
implement main0() = if c_argc()<3 then exit(2) else run()
