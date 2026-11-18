#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "search/ix_store.sats"
staload "search/literal/literal_search.sats"
staload "search/results/search_results.sats"
staload "search/results/search_file_cache.sats"
staload "search/parallel/search_parallel.sats"
staload "core_runtime/workers.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/common/ui_common.sats"

(* Job file record. *)
macdef SEARCH_JOB_FILE_WORDS = 3
macdef SEARCH_JOB_FILE = 0
macdef SEARCH_JOB_PATH = 1
macdef SEARCH_JOB_PATH_LENGTH = 2
(* Result file record; rows ~1 = not searched (no pattern on the worker). *)
macdef SEARCH_DONE_WORDS = 5
macdef SEARCH_DONE_FILE = 0
macdef SEARCH_DONE_FIRST = 1
macdef SEARCH_DONE_ROWS = 2
macdef SEARCH_DONE_MATCHES = 3
macdef SEARCH_DONE_TRUNCATED = 4
macdef SEARCH_NOT_SEARCHED = ~1
macdef SEARCH_JOBS_PER_WORKER = 2
macdef SEARCH_CHUNKS_PER_WORKER = 2
macdef SEARCH_RESULTS_PER_STEP = 256
macdef SEARCH_INITIAL_BYTES = 256

fun words_make(count: int,words: int): Buf = let val bytes=imul(imax(1,imul(count,words)),WORD32_BYTES)
  val b=buf_make(bytes) val ()=buf_set_len(b,bytes) in b end
fun word_append(b: &Buf >> _,value: int): void = let val at=buf_len(b)
  val ()=buf_ensure(b,iadd(at,WORD32_BYTES)) val ()=buf_set_len(b,iadd(at,WORD32_BYTES))
in buf_set32(b,idiv(at,WORD32_BYTES),value) end
fun bool_code(value: bool): int = if value then 1 else 0

(* ---- worker side ---- *)
implement search_job_pattern(slot,key,job) = let val+ SearchJob(stamp,query,map,paths,records,count)=job
in if buffer_equal_from(key,query,0) then slot else let
    val ()=literal_pattern_release(slot)
    val ()=buf_set_len(key,0) val ()=buf_append_at(key,query,0,buf_len(query))
  in literal_pattern_open(query,buffer_c_string(map)) end end

fun job_get(records: !Buf,i: int,field: int): int = buf_get32(records,iadd(imul(i,SEARCH_JOB_FILE_WORDS),field))
fun done_put(done: !Buf,i: int,file: int,first: int,rows: int,matches: int,truncated: int): void = let
  val base=imul(i,SEARCH_DONE_WORDS)
  val ()=buf_set32(done,iadd(base,SEARCH_DONE_FILE),file) val ()=buf_set32(done,iadd(base,SEARCH_DONE_FIRST),first)
  val ()=buf_set32(done,iadd(base,SEARCH_DONE_ROWS),rows) val ()=buf_set32(done,iadd(base,SEARCH_DONE_MATCHES),matches)
in buf_set32(done,iadd(base,SEARCH_DONE_TRUNCATED),truncated) end

(* Appends one file's rows (searched from row 0) after the rows already held. *)
fun append_meta{n:nat} .<n>. (left: int(n),meta: &Buf >> _,own: !Buf,word: int,text_base: int): void =
  if left = 0 then () else let
    val value=buf_get32(own,word)
    val field=imod(word,SEARCH_RESULT_WORDS)
    val ()=word_append(meta,if ieq(field,SEARCH_RESULT_TEXT) then iadd(value,text_base) else value)
  in append_meta(left-1,meta,own,iadd(word,1),text_base) end
fun append_words{n:nat} .<n>. (left: int(n),out: &Buf >> _,own: !Buf,word: int): void =
  if left = 0 then () else let val ()=word_append(out,buf_get32(own,word)) in append_words(left-1,out,own,iadd(word,1)) end
fun append_local(text: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,lt: !Buf,lm: !Buf,lj: !Buf,rows: int): void = let
  val base=buf_len(text) val ()=buf_append_at(text,lt,0,buf_len(lt))
  val ()=append_meta(airlock_nat(imax(0,imul(rows,SEARCH_RESULT_WORDS))),meta,lm,0,base)
in append_words(airlock_nat(imax(0,imul(rows,SEARCH_JUMP_WORDS))),jumps,lj,0) end

fun search_source(pattern: !LiteralPattern,source: !Buf,path: !Buf,file: int,i: int,
  text: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,done: !Buf,rows: &int >> _): void = let
  var lt=buf_make(SEARCH_INITIAL_BYTES) var lm=buf_make(SEARCH_INITIAL_BYTES) var lj=buf_make(SEARCH_INITIAL_BYTES)
  var own: int=0
  val result=search_append_matches(source,path,pattern,file,lt,lm,lj,own)
  val ()=append_local(text,meta,jumps,lt,lm,lj,own)
  val ()=done_put(done,i,file,rows,own,result.matches,bool_code(result.truncated))
  val ()=rows := iadd(rows,own)
  val ()=buf_free(lt) val ()=buf_free(lm)
in buf_free(lj) end

fun job_path(paths: !Buf,records: !Buf,i: int): Buf = let
  val length=job_get(records,i,SEARCH_JOB_PATH_LENGTH)
  var path=buf_make(imax(1,length)) val ()=buf_append_at(path,paths,job_get(records,i,SEARCH_JOB_PATH),length)
in path end
fun run_file{b:bool}(slot: !option_vt(LiteralPattern,b),cache: &FileCache >> _,paths: !Buf,records: !Buf,i: int,
  text: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,done: !Buf,rows: &int >> _): void = let
  val file=job_get(records,i,SEARCH_JOB_FILE)
  val path=job_path(paths,records,i)
  val ()=case+ slot of
    | None_vt() => done_put(done,i,file,rows,SEARCH_NOT_SEARCHED,0,0)
    | Some_vt(pattern) => (case+ search_cached_source(cache,path) of
      | ~None_vt() => done_put(done,i,file,rows,0,0,1)
      | ~Some_vt(source) => let val ()=search_source(pattern,source,path,file,i,text,meta,jumps,done,rows)
        in buf_free(source) end)
in buf_free(path) end

fun run_files{n:nat}{b:bool} .<n>. (left: int(n),slot: !option_vt(LiteralPattern,b),cache: &FileCache >> _,paths: !Buf,records: !Buf,i: int,
  text: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,done: !Buf,rows: &int >> _): void =
  if left = 0 then () else let val ()=run_file(slot,cache,paths,records,i,text,meta,jumps,done,rows)
  in run_files(left-1,slot,cache,paths,records,iadd(i,1),text,meta,jumps,done,rows) end

implement search_job_run(slot,cache,job) = let val+ ~SearchJob(stamp,query,map,paths,records,count)=job
  var text=buf_make(SEARCH_INITIAL_BYTES) var meta=buf_make(SEARCH_INITIAL_BYTES) var jumps=buf_make(SEARCH_INITIAL_BYTES)
  val done=words_make(count,SEARCH_DONE_WORDS)
  var rows: int=0
  val ()=run_files(airlock_nat(imax(0,count)),slot,cache,paths,records,0,text,meta,jumps,done,rows)
  val ()=buf_free(query) val ()=buf_free(map) val ()=buf_free(paths) val ()=buf_free(records)
in SearchResult(stamp,text,meta,jumps,done,count) end

(* ---- main side: planning ---- *)
fun file_bytes(files: !Buf,i: int): int = imax(0,ix_file_get(files,i,IX_F_SIZE))
fun total_bytes{n:nat} .<n>. (left: int(n),files: !Buf,i: int,sum: int): int =
  if left = 0 then sum else total_bytes(left-1,files,iadd(i,1),iadd(sum,file_bytes(files,i)))
(* Chunks never split a file; a file bigger than the target is its own chunk. *)
fun plan{n:nat} .<n>. (left: int(n),files: !Buf,i: int,used: int,target: int): void =
  if left = 0 then () else let val size=file_bytes(files,i)
    val fresh=ieq(i,0) orelse (igt(used,0) andalso igt(iadd(used,size),target))
    val ()=if fresh then search_plan_push(i) else ()
  in plan(left-1,files,iadd(i,1),iadd(if fresh then 0 else used,size),target) end

implement search_parallel_available() = search_parallel_enabled()
implement search_parallel_begin(files) = let
  val count=ix_file_count(files) val _=search_begin(count)
  val total=total_bytes(airlock_nat(imax(0,count)),files,0,0)
  val spread=idiv(total,imax(1,imul(workers_active(),SEARCH_CHUNKS_PER_WORKER)))
  val target=imax(1,imin(workers_chunk_bytes(),spread))
  val ()=plan(airlock_nat(imax(0,count)),files,0,0,target)
in search_plan_close(count) end

(* ---- main side: dispatch ---- *)
fun add_file(files: !Buf,paths: !Buf,i: int,records: &Buf >> _,text: &Buf >> _): void = let
  val offset=ix_file_get(files,i,IX_F_PATHOFF) val length=ix_file_get(files,i,IX_F_PATHLEN)
  val ()=word_append(records,i) val ()=word_append(records,buf_len(text)) val ()=word_append(records,length)
in buf_append_at(text,paths,offset,length) end
fun add_files{n:nat} .<n>. (left: int(n),files: !Buf,paths: !Buf,i: int,records: &Buf >> _,text: &Buf >> _): void =
  if left = 0 then () else let val ()=add_file(files,paths,i,records,text)
  in add_files(left-1,files,paths,iadd(i,1),records,text) end
fun copy_of(b: !Buf): Buf = let var c=buf_make(imax(1,buf_len(b))) val ()=buf_append_at(c,b,0,buf_len(b)) in c end
fun chunk_job(files: !Buf,paths: !Buf,query: !Buf,map: !Buf,chunk: int): SearchJob = let
  val first=search_first(chunk) val last=search_first(iadd(chunk,1))
  var records=buf_make(SEARCH_INITIAL_BYTES) var text=buf_make(SEARCH_INITIAL_BYTES)
  val ()=add_files(airlock_nat(imax(0,isub(last,first))),files,paths,first,records,text)
  val stamp: SearchStamp= @{generation=search_generation(),chunk=chunk}
in SearchJob(stamp,copy_of(query),copy_of(map),text,records,isub(last,first)) end
(* Chunk c goes to worker c mod count when that worker can take it, so the
   same files meet the same worker's file cache on every search; otherwise any
   available worker (idle workers steal queued chunks anyway). *)
fun sticky_worker(chunk: int): int = let val count=workers_count()
  val home=imod(chunk,imax(1,count))
in if igt(count,0) andalso workers_has_room(home) andalso ilt(workers_queued(home),SEARCH_JOBS_PER_WORKER)
  then home else workers_pick(SEARCH_JOBS_PER_WORKER) end
fun dispatch{n:nat} .<n>. (left: int(n),files: !Buf,paths: !Buf,query: !Buf,map: !Buf): void =
  if left = 0 then () else if ige(search_dispatched(),search_chunks()) then () else let
    val worker=sticky_worker(search_dispatched())
  in if ilt(worker,0) then () else let
      val chunk=search_dispatched()
      val ()=search_job_submit(worker,chunk_job(files,paths,query,map,chunk)) val ()=search_sent()
      val ()=search_set_dispatched(iadd(chunk,1))
    in dispatch(left-1,files,paths,query,map) end end

(* ---- main side: collect ---- *)
fun result_dispose(result: SearchResult): void = let val+ ~SearchResult(stamp,text,meta,jumps,done,count)=result
  val ()=buf_free(text) val ()=buf_free(meta) val ()=buf_free(jumps) in buf_free(done) end
fun result_stamp(result: !SearchResult): SearchStamp = let val+ SearchResult(stamp,t,m,j,d,c)=result in stamp end
fun keep(result: SearchResult): void = let val stamp=result_stamp(result)
in if search_active() andalso ieq(stamp.generation,search_generation()) andalso not(search_has_parked(stamp.chunk))
  then search_result_park(stamp.chunk,result) else result_dispose(result) end
fun collect_worker{n:nat} .<n>. (left: int(n),worker: int): void =
  if left = 0 then () else if not(workers_has_result(worker,WORKER_JOB_SEARCH)) then () else let
    val result=search_result_take(worker) val ()=search_got()
    val ()=keep(result) in collect_worker(left-1,worker) end
fun collect{n:nat} .<n>. (left: int(n),worker: int): void =
  if left = 0 then () else let val ()=collect_worker(airlock_nat(SEARCH_RESULTS_PER_STEP),worker)
  in collect(left-1,iadd(worker,1)) end

(* ---- main side: merge (same limits as the sequential search) ---- *)
fun done_get(done: !Buf,i: int,field: int): int = buf_get32(done,iadd(imul(i,SEARCH_DONE_WORDS),field))
fun meta_get(meta: !Buf,row: int,field: int): int = buf_get32(meta,iadd(imul(row,SEARCH_RESULT_WORDS),field))
fun copy_meta{n:nat} .<n>. (left: int(n),source: !Buf,row: int,shift: int,meta: &Buf >> _,at: int): void =
  if left = 0 then () else let
    val base=imul(at,SEARCH_RESULT_WORDS)
    val ()=buf_ensure(meta,imul(iadd(base,SEARCH_RESULT_WORDS),WORD32_BYTES))
    val ()=buf_set32(meta,iadd(base,SEARCH_RESULT_MATCH),meta_get(source,row,SEARCH_RESULT_MATCH))
    val ()=buf_set32(meta,iadd(base,SEARCH_RESULT_TEXT),iadd(meta_get(source,row,SEARCH_RESULT_TEXT),shift))
    val ()=buf_set32(meta,iadd(base,SEARCH_RESULT_LENGTH),meta_get(source,row,SEARCH_RESULT_LENGTH))
    val ()=buf_set32(meta,iadd(base,SEARCH_RESULT_MATCH_LENGTH),meta_get(source,row,SEARCH_RESULT_MATCH_LENGTH))
    val ()=buf_set_len(meta,imul(iadd(base,SEARCH_RESULT_WORDS),WORD32_BYTES))
  in copy_meta(left-1,source,iadd(row,1),shift,meta,iadd(at,1)) end
fun copy_jumps{n:nat} .<n>. (left: int(n),source: !Buf,row: int,jumps: &Buf >> _,at: int): void =
  if left = 0 then () else let
    val base=imul(at,SEARCH_JUMP_WORDS) val from=imul(row,SEARCH_JUMP_WORDS)
    val ()=buf_ensure(jumps,imul(iadd(base,SEARCH_JUMP_WORDS),WORD32_BYTES))
    val ()=buf_set32(jumps,iadd(base,SEARCH_JUMP_FILE),buf_get32(source,iadd(from,SEARCH_JUMP_FILE)))
    val ()=buf_set32(jumps,iadd(base,SEARCH_JUMP_LINE),buf_get32(source,iadd(from,SEARCH_JUMP_LINE)))
    val ()=buf_set32(jumps,iadd(base,SEARCH_JUMP_COLUMN),buf_get32(source,iadd(from,SEARCH_JUMP_COLUMN)))
    val ()=buf_set_len(jumps,imul(iadd(base,SEARCH_JUMP_WORDS),WORD32_BYTES))
  in copy_jumps(left-1,source,iadd(row,1),jumps,iadd(at,1)) end

(* Rows [first, first+k) were produced as if this file came first; taking
   min(rows, LIMIT - current) of them reproduces the sequential output. *)
fun take_rows(text: !Buf,meta: !Buf,jumps: !Buf,first: int,count: int,matches: int,truncated: bool,
  hits: &Buf >> _,hmeta: &Buf >> _,hjumps: &Buf >> _,rows: &int >> _): SearchAppendResult =
  if ile(count,0) then @{matches=matches,truncated=truncated}
  else if ige(rows,isub(SEARCH_RESULT_LIMIT,1)) then @{matches=0,truncated=true} else let
    val k=imin(count,isub(SEARCH_RESULT_LIMIT,rows))
    val start=meta_get(meta,first,SEARCH_RESULT_TEXT)
    val last=iadd(first,isub(k,1))
    val finish=iadd(meta_get(meta,last,SEARCH_RESULT_TEXT),meta_get(meta,last,SEARCH_RESULT_LENGTH))
    val shift=isub(buf_len(hits),start)
    val ()=buf_append_at(hits,text,start,isub(finish,start))
    val ()=copy_meta(airlock_nat(k),meta,first,shift,hmeta,rows)
    val ()=copy_jumps(airlock_nat(k),jumps,first,hjumps,rows)
    val ()=rows := iadd(rows,k)
    val taken=isub(k,1)
  in @{matches=taken,truncated=ilt(taken,matches) orelse truncated} end

fun catalog_path(files: !Buf,paths: !Buf,file: int): Buf = let
  val offset=ix_file_get(files,file,IX_F_PATHOFF) val length=ix_file_get(files,file,IX_F_PATHLEN)
  var path=buf_make(imax(1,length)) val ()=buf_append_at(path,paths,offset,length)
in path end

(* The open tab's buffer, if the file is open (found > 0). *)
fun tab_text(tabs: !Tabs,path: !Buf): (int,Buf) = let
  var text=buf_make(0) val found=tabs_copy_doc_text(tabs,path,text)
in (found,text) end
fun merge_file(result: !SearchResult,i: int,files: !Buf,paths: !Buf,tabs: !Tabs,pattern: !LiteralPattern,
  hits: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,rows: &int >> _): SearchAppendResult = let
  val+ SearchResult(stamp,text,rmeta,rjumps,done,count)=result
  val file=done_get(done,i,SEARCH_DONE_FILE)
  val path=catalog_path(files,paths,file)
  val (found,opened)=tab_text(tabs,path)
  val out=(if igt(found,0) then search_append_matches(opened,path,pattern,file,hits,meta,jumps,rows)
    else if ilt(done_get(done,i,SEARCH_DONE_ROWS),0) then search_append_file(path,tabs,pattern,file,hits,meta,jumps,rows)
    else take_rows(text,rmeta,rjumps,done_get(done,i,SEARCH_DONE_FIRST),done_get(done,i,SEARCH_DONE_ROWS),
      done_get(done,i,SEARCH_DONE_MATCHES),igt(done_get(done,i,SEARCH_DONE_TRUNCATED),0),hits,meta,jumps,rows)): SearchAppendResult
  val ()=buf_free(opened) val ()=buf_free(path)
in out end

fun merged_add(acc: SearchMerged,out: SearchAppendResult): SearchMerged =
  @{files=iadd(acc.files,1),matched=iadd(acc.matched,if igt(out.matches,0) then 1 else 0),
    truncated=acc.truncated orelse out.truncated,done=acc.done}

fun result_count(result: !SearchResult): int = let val+ SearchResult(stamp,t,m,j,d,count)=result in count end
fun merge_files{n:nat} .<n>. (left: int(n),result: !SearchResult,i: int,files: !Buf,paths: !Buf,tabs: !Tabs,
  pattern: !LiteralPattern,hits: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,rows: &int >> _,acc: SearchMerged): SearchMerged =
  if left = 0 then acc else if ige(rows,SEARCH_RESULT_LIMIT) then acc else let
    val out=merge_file(result,i,files,paths,tabs,pattern,hits,meta,jumps,rows)
  in merge_files(left-1,result,iadd(i,1),files,paths,tabs,pattern,hits,meta,jumps,rows,merged_add(acc,out)) end

fun merge_chunks{n:nat} .<n>. (left: int(n),files: !Buf,paths: !Buf,tabs: !Tabs,pattern: !LiteralPattern,
  hits: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,rows: &int >> _,acc: SearchMerged): SearchMerged =
  if left = 0 then acc else if ige(rows,SEARCH_RESULT_LIMIT) then acc
  else if ige(search_merged(),search_chunks()) then acc
  else if not(search_has_parked(search_merged())) then acc else let
    val chunk=search_merged() val result=search_result_unpark(chunk)
    val next=merge_files(airlock_nat(imax(0,result_count(result))),result,0,files,paths,tabs,pattern,hits,meta,jumps,rows,acc)
    val ()=result_dispose(result) val ()=search_set_merged(iadd(chunk,1))
  in merge_chunks(left-1,files,paths,tabs,pattern,hits,meta,jumps,rows,next) end

fun drop_parked{n:nat} .<n>. (left: int(n),chunk: int): void =
  if left = 0 then () else let
    val ()=if search_has_parked(chunk) then result_dispose(search_result_unpark(chunk)) else ()
  in drop_parked(left-1,iadd(chunk,1)) end
implement search_parallel_cancel() = let
  val ()=drop_parked(airlock_nat(imax(0,search_chunks())),0)
in search_finish() end

implement search_parallel_step(files,paths,query,map,tabs,pattern,hits,meta,jumps,rows) = let
  val ()=collect(airlock_nat(workers_count()),0)
  val ()=dispatch(airlock_nat(imul(workers_count(),SEARCH_JOBS_PER_WORKER)),files,paths,query,map)
  val start: SearchMerged= @{files=0,matched=0,truncated=false,done=false}
  val merged=merge_chunks(airlock_nat(imax(0,search_chunks())),files,paths,tabs,pattern,hits,meta,jumps,rows,start)
  val finished=ige(search_merged(),search_chunks()) orelse ige(rows,SEARCH_RESULT_LIMIT)
  val ()=if finished then search_parallel_cancel() else ()
in @{files=merged.files,matched=merged.matched,truncated=merged.truncated,done=finished} end

implement search_parallel_settle() = collect(airlock_nat(workers_count()),0)
