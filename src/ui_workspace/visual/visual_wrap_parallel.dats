#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font.sats"
staload "data_font/resources/private/font_storage.sats"
staload "core_runtime/workers.sats"
staload "core_runtime/text_engine_startup.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/visual/visual_layout.sats"
staload "ui_workspace/visual/visual_wrap_parallel.sats"

(* Job line record. *)
macdef WRAP_JOB_LINE_WORDS = 9
macdef WRAP_JOB_LINE = 0
macdef WRAP_JOB_START = 1
macdef WRAP_JOB_LENGTH = 2
macdef WRAP_JOB_TEXT = 3
macdef WRAP_JOB_TARGET = 4
macdef WRAP_JOB_PX = 5
macdef WRAP_JOB_HEIGHT = 6
macdef WRAP_JOB_ASCENT = 7
macdef WRAP_JOB_TOP = 8
(* Result line record. *)
macdef WRAP_RESULT_LINE_WORDS = 4
macdef WRAP_RESULT_LINE = 0
macdef WRAP_RESULT_START = 1
macdef WRAP_RESULT_FIRST = 2
macdef WRAP_RESULT_COUNT = 3
macdef WRAP_STATUS_OK = 0
macdef WRAP_STATUS_NO_FONT = 1
(* Batching policy: a job is about one worker time slice of text. *)
macdef WRAP_JOB_TEXT_BYTES = 6144
macdef WRAP_JOB_MAX_LINES = 32
macdef WRAP_JOBS_PER_WORKER = 2
macdef WRAP_RESULTS_PER_FRAME = 64
macdef WRAP_INITIAL_BYTES = 256

(* ---- worker side ---- *)

fun font_release(slot: Option_vt(Font)): void = case+ slot of | ~None_vt() => () | ~Some_vt(f) => font_free(f)
(* Same face files as the main Font, then the shared Unicode assets. *)
fun open_from(primary: !Buf,fallback: !Buf): Option_vt(Font) = let
  val f=font_open()
  val loaded=igt(buf_len(primary),0) andalso font_use_file(f,buf_cstr(primary))
  val ()=if loaded andalso igt(buf_len(fallback),0) then (if font_use_fallback_file(f,buf_cstr(fallback)) then () else ()) else ()
  val ready=loaded andalso workspace_worker_text_start(f)
in if ready then Some_vt(f) else let val ()=font_free(f) in None_vt() end end

fun record_get(records: !Buf,i: int,field: int): int = buf_get32(records,iadd(imul(i,WRAP_JOB_LINE_WORDS),field))
fun record_style(records: !Buf,i: int): VisualRowStyle =
  @{px=record_get(records,i,WRAP_JOB_PX),height=record_get(records,i,WRAP_JOB_HEIGHT),
    ascent=record_get(records,i,WRAP_JOB_ASCENT),top=record_get(records,i,WRAP_JOB_TOP)}
fun row_total(rows: !Buf): int = idiv(buf_len(rows),imul(VISUAL_ROW_WORDS,WORD32_BYTES))
fun info_put(info: !Buf,i: int,line: int,start: int,first: int,count: int): void = let
  val base=imul(i,WRAP_RESULT_LINE_WORDS)
  val ()=buf_set32(info,iadd(base,WRAP_RESULT_LINE),line) val ()=buf_set32(info,iadd(base,WRAP_RESULT_START),start)
  val ()=buf_set32(info,iadd(base,WRAP_RESULT_FIRST),first)
in buf_set32(info,iadd(base,WRAP_RESULT_COUNT),count) end

fun shape_record(f: !Font,records: !Buf,text: !Buf,i: int,scratch: &Buf >> _,rows: &Buf >> _,info: !Buf,
  done: WrapParagraphList): WrapParagraphList = let
  val length=record_get(records,i,WRAP_JOB_LENGTH)
  val ()=buf_set_len(scratch,0) val ()=buf_append_at(scratch,text,record_get(records,i,WRAP_JOB_TEXT),length)
  val first=row_total(rows)
  val paragraph=visual_wrap_segment(f,scratch,length,record_get(records,i,WRAP_JOB_TARGET),record_style(records,i),rows)
  val ()=info_put(info,i,record_get(records,i,WRAP_JOB_LINE),record_get(records,i,WRAP_JOB_START),first,isub(row_total(rows),first))
in WrapParagraphsCons(paragraph,done) end

fun shape_records{n:nat} .<n>. (left: int(n),f: !Font,records: !Buf,text: !Buf,i: int,scratch: &Buf >> _,
  rows: &Buf >> _,info: !Buf,done: WrapParagraphList): WrapParagraphList =
  if left = 0 then done else let val next=shape_record(f,records,text,i,scratch,rows,info,done)
  in shape_records(left-1,f,records,text,iadd(i,1),scratch,rows,info,next) end

fun info_make(count: int): Buf = let val bytes=imul(imax(1,imul(count,WRAP_RESULT_LINE_WORDS)),WORD32_BYTES)
  val info=buf_make(bytes) val ()=buf_set_len(info,bytes) in info end

fun shaped_job(f: !Font,job: WrapJob): WrapResult = let
  val+ ~WrapJob(stamp,records,text,count,primary,fallback)=job
  val ()=buf_free(primary) val ()=buf_free(fallback)
  val ()=if ine(font_get_px(f),stamp.px) then font_set_px(f,stamp.px) else ()
  var rows=buf_make(WRAP_INITIAL_BYTES) var scratch=buf_make(WRAP_INITIAL_BYTES)
  val info=info_make(count)
  val paragraphs=shape_records(airlock_nat(imax(0,count)),f,records,text,0,scratch,rows,info,WrapParagraphsNil())
  val ()=buf_free(scratch) val ()=buf_free(records) val ()=buf_free(text)
in WrapResult(stamp,rows,info,paragraphs,count,WRAP_STATUS_OK) end

fun failed_job(job: WrapJob): WrapResult = let val+ ~WrapJob(stamp,records,text,count,primary,fallback)=job
  val ()=buf_free(records) val ()=buf_free(text) val ()=buf_free(primary) val ()=buf_free(fallback)
in WrapResult(stamp,buf_make(1),info_make(0),WrapParagraphsNil(),0,WRAP_STATUS_NO_FONT) end

implement wrap_job_source(job) = let val+ WrapJob(stamp,records,text,count,primary,fallback)=job in stamp.source end
fun job_reopen(job: !WrapJob): Option_vt(Font) = let val+ WrapJob(stamp,records,text,count,primary,fallback)=job
in open_from(primary,fallback) end
(* Keeps the font while the job's sources are the ones it was opened from. *)
implement wrap_job_font(slot,source,job) =
  if ieq(source,wrap_job_source(job)) then slot else let val ()=font_release(slot) in job_reopen(job) end
implement wrap_job_run(slot,job) = case+ slot of
  | Some_vt(f) => shaped_job(f,job) | None_vt() => failed_job(job)

(* ---- main side: collect ---- *)
fun paragraphs_dispose(list: WrapParagraphList): void = case+ list of
  | ~WrapParagraphsNil() => ()
  | ~WrapParagraphsCons(head,rest) => let
      val ()=case+ head of | ~None_vt() => () | ~Some_vt(p) => visual_paragraph_dispose(p)
    in paragraphs_dispose(rest) end
fun info_get(info: !Buf,i: int,field: int): int = buf_get32(info,iadd(imul(i,WRAP_RESULT_LINE_WORDS),field))

(* Paragraphs are listed newest first, so records are added from the last. *)
fun add_records(i: int,rows: !Buf,info: !Buf,list: WrapParagraphList,shaped: &VisualShaped >> _): void =
  case+ list of
  | ~WrapParagraphsNil() => ()
  | ~WrapParagraphsCons(paragraph,rest) => let
      val ()=visual_shaped_add(shaped,info_get(info,i,WRAP_RESULT_LINE),info_get(info,i,WRAP_RESULT_START),
        rows,info_get(info,i,WRAP_RESULT_FIRST),info_get(info,i,WRAP_RESULT_COUNT),paragraph)
    in add_records(isub(i,1),rows,info,rest,shaped) end

fun same_stamp(a: WrapStamp,b: WrapStamp): bool = a.document = b.document andalso ieq(a.build,b.build)

fun absorb(result: WrapResult,stamp: WrapStamp,shaped: &VisualShaped >> _): void = let
  val+ ~WrapResult(made,rows,info,paragraphs,count,status)=result
  val ()=if ine(status,WRAP_STATUS_OK) then wrap_disable() else ()
  val ()=if same_stamp(made,stamp) then add_records(isub(count,1),rows,info,paragraphs,shaped)
    else paragraphs_dispose(paragraphs)
  val ()=buf_free(rows)
in buf_free(info) end

fun drain{n:nat} .<n>. (left: int(n),worker: int,stamp: WrapStamp,shaped: &VisualShaped >> _): void =
  if left = 0 then () else if not(workers_has_result(worker,WORKER_JOB_WRAP)) then () else let
    val result=wrap_result_take(worker) val ()=wrap_received(worker)
    val ()=absorb(result,stamp,shaped)
  in drain(left-1,worker,stamp,shaped) end

fun collect{n:nat} .<n>. (left: int(n),worker: int,stamp: WrapStamp,shaped: &VisualShaped >> _): void =
  if left = 0 then () else let val ()=drain(airlock_nat(WRAP_RESULTS_PER_FRAME),worker,stamp,shaped)
  in collect(left-1,iadd(worker,1),stamp,shaped) end

(* ---- main side: dispatch ---- *)
fun append_record(records: &Buf >> _,text: &Buf >> _,source: !Buf,input: VisualLineInput): void = let
  val at=buf_len(records) val bytes=imul(WRAP_JOB_LINE_WORDS,WORD32_BYTES)
  val ()=buf_ensure(records,iadd(at,bytes)) val ()=buf_set_len(records,iadd(at,bytes))
  val i=idiv(at,bytes) val base=imul(i,WRAP_JOB_LINE_WORDS)
  val length=isub(input.b,input.a)
  val ()=buf_set32(records,iadd(base,WRAP_JOB_LINE),input.line)
  val ()=buf_set32(records,iadd(base,WRAP_JOB_START),input.a)
  val ()=buf_set32(records,iadd(base,WRAP_JOB_LENGTH),length)
  val ()=buf_set32(records,iadd(base,WRAP_JOB_TEXT),buf_len(text))
  val ()=buf_set32(records,iadd(base,WRAP_JOB_TARGET),input.target)
  val ()=buf_set32(records,iadd(base,WRAP_JOB_PX),input.style.px)
  val ()=buf_set32(records,iadd(base,WRAP_JOB_HEIGHT),input.style.height)
  val ()=buf_set32(records,iadd(base,WRAP_JOB_ASCENT),input.style.ascent)
  val ()=buf_set32(records,iadd(base,WRAP_JOB_TOP),input.style.top)
in buf_append_at(text,source,input.a,length) end

fun job_full(records: !Buf,text: !Buf): bool =
  ige(buf_len(text),WRAP_JOB_TEXT_BYTES) orelse ige(idiv(buf_len(records),imul(WRAP_JOB_LINE_WORDS,WORD32_BYTES)),WRAP_JOB_MAX_LINES)

(* Visits positions v in dispatch order (from `start`, wrapping around); the
   block-kind cursor restarts when the order wraps to the top of the document. *)
fun fill{n:nat} .<n>. (left: int(n),d: !Doc,rows: !VisualRows,records: &Buf >> _,text: &Buf >> _,
  v: int,start: int,cur: &int >> _,previous: &int >> _): int =
  if left = 0 then v else if job_full(records,text) then v else let
    val line=imod(iadd(start,v),doc_nlines(d))
    val ()=if ilt(line,previous) then cur := 0 else ()
    val ()=previous := line
    val ()=if visual_rows_line_pending(rows,line) then let
        val input=visual_wrap_line_input(d,rows,line,cur)
        val+ VisualRows(source,m,l,data,n,k,plans)=rows
      in if input.shaped then append_record(records,text,source,input) else () end else ()
  in fill(left-1,d,rows,records,text,iadd(v,1),start,cur,previous) end

fun records_count(records: !Buf): int = idiv(buf_len(records),imul(WRAP_JOB_LINE_WORDS,WORD32_BYTES))

fun send_one(f: !Font,d: !Doc,rows: !VisualRows,stamp: WrapStamp,worker: int,cursor: int): int = let
  val nlines=doc_nlines(d) val start=imod(imax(0,wrap_start()),imax(1,nlines))
  var records=buf_make(WRAP_INITIAL_BYTES) var text=buf_make(WRAP_JOB_TEXT_BYTES)
  var cur: int=0 var previous: int= ~1
  val next=fill(airlock_nat(imax(0,isub(nlines,cursor))),d,rows,records,text,cursor,start,cur,previous)
  val count=records_count(records)
in if igt(count,0) then let
    var primary=buf_make(0) var fallback=buf_make(0) val ()=font_source_paths(f,primary,fallback)
    val ()=wrap_job_submit(worker,WrapJob(stamp,records,text,count,primary,fallback)) val ()=wrap_sent(worker)
  in next end
  else let val ()=buf_free(records) val ()=buf_free(text) in next end end

fun dispatch{n:nat} .<n>. (left: int(n),f: !Font,d: !Doc,rows: !VisualRows,stamp: WrapStamp,cursor: int): int =
  if left = 0 then cursor else if ige(cursor,doc_nlines(d)) then cursor else let val worker=wrap_pick_worker(WRAP_JOBS_PER_WORKER)
  in if ilt(worker,0) then cursor else dispatch(left-1,f,d,rows,stamp,send_one(f,d,rows,stamp,worker,cursor)) end

fun stamp_of(f: !Font,d: !Doc,rows: !VisualRows): WrapStamp = let val+ VisualRows(t,m,l,data,n,key,plans)=rows
in @{document=doc_identity(d),build=key.build,px=key.px,source=font_source_id(f)} end

implement visual_wrap_parallel_available() = wrap_enabled()

implement visual_wrap_parallel_step(f,d,rows,band) = let
  val stamp=stamp_of(f,d,rows)
  var shaped=visual_shaped_make(doc_nlines(d))
  val ()=collect(airlock_nat(workers_count()),0,stamp,shaped)
  val wrapped=visual_wrap_apply(d,rows,shaped)
  val ()=visual_shaped_dispose(shaped)
  val cursor=wrap_plan(stamp.document,stamp.build,iadd(band.last,1))
  val sent=dispatch(airlock_nat(imul(workers_count(),WRAP_JOBS_PER_WORKER)),f,d,rows,stamp,cursor)
  (* Every line visited and nothing in flight, yet lines still pending (their
     results were for an older build): sweep again from the start. *)
  val again=ige(sent,doc_nlines(d)) andalso ieq(wrap_outstanding(),0) andalso igt(visual_rows_pending(rows),0)
  val ()=wrap_set_cursor(if again then 0 else sent)
in wrapped end
