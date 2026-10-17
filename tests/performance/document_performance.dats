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
staload "data_ast/document/doc.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/render/ui_render.sats"
extern fun finish_gpu(): void = "mac#glFinish"
macdef VIEW_WIDTH_PIXELS = 1280
macdef VIEW_HEIGHT_PIXELS = 800
macdef FONT_SIZE_PIXELS = 18

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
in counter("visual_index_builds",PERF_VISUAL_INDEX_BUILDS) end

fun paint(f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,scroll: int): void = let
  val ()=rend_begin(r,VIEW_WIDTH_PIXELS,VIEW_HEIGHT_PIXELS)
  val ()=draw_doc(f,r,d,0,UI_TOPBAR_HEIGHT,VIEW_WIDTH_PIXELS,
    isub(VIEW_HEIGHT_PIXELS,UI_TOPBAR_HEIGHT),scroll,FONT_SIZE_PIXELS,vault,cache,scratch,mode)
  val ()=rend_flush(r)
  val ()=finish_gpu()
in plat_swap(p) end

fun sample(f: !Font,r: !Rend,p: !Plat,d: !Doc,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,index: int): void = let
  val ()=performance_reset()
  val started=mono_ns()
  val ()=paint(f,r,p,d,vault,cache,scratch,mode,0)
  val elapsed=mono_ns()-started
  val ()=println!("event=document_frame sample=",index," elapsed_ns=",elapsed)
in report() end

fun benchmark(f: !Font,r: !Rend,p: !Plat,path: string,root: string,mode: ViewMode): void = let
  val d=doc_open()
  var vault: Buf=buf_make(c_strlen(root))
  val ()=buffer_append_string(vault,root)
  var cache=CNil()
  var scratch: Buf=buf_make(4096)
  val ()=performance_reset()
  val started=mono_ns()
  val loaded=doc_load(d,path)
  val ()=println!("event=document_load ok=",loaded," elapsed_ns=",mono_ns()-started)
  val ()=report()
  val ()=sample(f,r,p,d,vault,cache,scratch,mode,0)
  val ()=sample(f,r,p,d,vault,cache,scratch,mode,1)
  val ()=sample(f,r,p,d,vault,cache,scratch,mode,2)
  val ()=cache_free(cache)
  val ()=buf_free(scratch)
  val ()=buf_free(vault)
in doc_free(d) end

fun run(): void = let
  val p=plat_open()
in if not(plat_ok(p)) then let val ()=plat_close(p) in exit(1) end else let
  val r=rend_open()
  val f=font_open()
  val ()=font_set_px(f,FONT_SIZE_PIXELS)
  val native=workspace_font_start(f)
  val ()=performance_enable(1)
  val mode=if c_argc()>3 andalso c_strcmp(c_argv(3),"edit")=0 then ViewEdit else ViewRead
  val ()=if native then benchmark(f,r,p,c_argv(2),c_argv(1),mode) else ()
  val ()=font_free(f)
  val ()=rend_close(r)
  val ()=plat_close(p)
in if native then () else exit(1) end end
implement main0() = if c_argc()<3 then exit(2) else run()
