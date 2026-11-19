(* Background line shaping on worker threads.

   Main thread: picks pending lines of the drawn document (below the viewport
   band first, then above), copies their projected text and shaping inputs into
   jobs, and later splices finished rows in with visual_wrap_apply. Workers own
   a private Font (same faces, same Unicode assets) and never see a Doc.
   Results are stamped with the document identity and VisualRows build; a
   result for any other build is disposed, so edits and rebuilds are safe. *)
staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/visual/visual_layout.sats"
%{#
#include "core_runtime/kernel/kernel.cats"
%}
(* source: Font source id; workers reopen their font when it changes. *)
typedef WrapStamp = @{document=ptr,build=int,px=int,source=int}
(* Line records (WRAP_JOB_LINE_WORDS each), the concatenated line text, the
   record count, and the main Font's primary and fallback face paths. *)
datavtype WrapJob = WrapJob of (WrapStamp,Buf,Buf,int,Buf,Buf)
datavtype WrapParagraphList = WrapParagraphsNil | WrapParagraphsCons of (Option_vt(VisualParagraph),WrapParagraphList)
(* Rows (relative offsets), per-line records (WRAP_RESULT_LINE_WORDS each),
   paragraphs in reverse record order, record count, status code. *)
datavtype WrapResult = WrapResult of (WrapStamp,Buf,Buf,WrapParagraphList,int,int)
(* Worker side (see ui_workspace/workers/worker_context.dats): a worker keeps
   its Font while jobs carry the same source id, and reopens it otherwise. *)
fun wrap_job_source(job: !WrapJob): int
fun wrap_job_font(slot: Option_vt(Font),source: int,job: !WrapJob): Option_vt(Font)
fun wrap_job_run{b:bool}(slot: !option_vt(Font,b),job: WrapJob): WrapResult

fun wrap_job_submit(worker: int,job: WrapJob): void = "mac#anth_k_submit_wrap"
fun wrap_result_take(worker: int): WrapResult = "mac#anth_k_take_wrap"

(* One frame of background work for `d`: splice finished results, then queue
   more lines. Returns the lines spliced in (VisualWrapped.count = 0: none). *)
fun visual_wrap_parallel_step(f: !Font,d: !Doc,rows: &VisualRows >> VisualRows,band: VisualLineRange): VisualWrapped
fun visual_wrap_parallel_available(): bool
