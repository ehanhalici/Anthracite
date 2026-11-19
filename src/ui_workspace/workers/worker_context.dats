#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/resources/font.sats"
staload "search/literal/literal_search.sats"
staload "search/results/search_file_cache.sats"
staload "search/parallel/search_parallel.sats"
staload "ui_workspace/visual/visual_wrap_parallel.sats"
staload "ui_workspace/workers/worker_context.sats"
(* Entry points called by the worker pool (core_runtime/kernel/workers.dats) on worker threads. *)
extern fun context_open(): WorkerContext = "ext#anth_worker_context_open"
extern fun context_free(context: WorkerContext): void = "ext#anth_worker_context_free"
extern fun run_wrap(context: !WorkerContext,job: WrapJob): WrapResult = "ext#anth_worker_run_wrap"
extern fun run_search(context: !WorkerContext,job: SearchJob): SearchResult = "ext#anth_worker_run_search"

(* Everything opens lazily from the first job that needs it. *)
implement context_open() = WorkerContext(None_vt(),0,None_vt(),buf_make(0),search_file_cache_make())
implement context_free(context) = let val+ ~WorkerContext(font,source,pattern,query,files)=context
  val ()=search_file_cache_free(files)
  val ()=case+ font of | ~None_vt() => () | ~Some_vt(f) => font_free(f)
  val ()=literal_pattern_release(pattern)
in buf_free(query) end
implement run_wrap(context,job) = let val+ @WorkerContext(font,source,pattern,query,files)=context
  val ()=font := wrap_job_font(font,source,job)
  val ()=source := wrap_job_source(job)
  val result=wrap_job_run(font,job)
  prval ()=fold@(context)
in result end
implement run_search(context,job) = let val+ @WorkerContext(font,source,pattern,query,files)=context
  val ()=pattern := search_job_pattern(pattern,query,job)
  val result=search_job_run(pattern,files,job)
  prval ()=fold@(context)
in result end
