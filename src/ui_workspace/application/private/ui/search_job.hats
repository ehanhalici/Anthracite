implement search_job_clear(s) = let
  val old=s.search_pattern val ()=s.search_pattern := None_vt()
  val ()=literal_pattern_release(old)
  val ()=s.search_state := SEARCH_IDLE val ()=s.search_cursor := 0
  val ()=s.search_skipped := false
in () end
fun search_doc_stamp{n:nat} .<n>. (left: int(n),tabs: !Tabs,index: int): SearchDocumentStamp =
  if left = 0 then @{document=the_null_ptr,generation= ~1} else case+ tabs of
  | TNil() => @{document=the_null_ptr,generation= ~1}
  | TCons(doc,path,title,scroll,rest) => if ieq(index,0) then
      @{document=doc_identity(doc),generation=doc_parse_generation(doc)} else search_doc_stamp(left-1,rest,isub(index,1))
fun search_results_clear(s: &App_record >> _): void = let
  val ()=buffer_clear(s.hits) val ()=buffer_clear(s.hmeta) val ()=buffer_clear(s.hjump)
  val ()=buf_zero(s.ixq) val ()=s.hn := 0 val ()=s.hscroll := 0
  val ()=s.selected_search_row := ~1
in s.search_nfiles := 0 end
fun search_catalog_prepare(s: &App_record >> _): void =
  if s.search_catalog_ready then () else let
    val ()=buffer_clear(s.ixf) val ()=buffer_clear(s.ixp) var truncated: int=0
    val ()=ix_walk_vault(s.vault,s.ixf,s.ixp,truncated)
    val ()=s.search_skipped := igt(truncated,0)
  in s.search_catalog_ready := true end
fun search_job_begin(s: &App_record >> _): void = let
  val ()=search_job_clear(s) val ()=search_results_clear(s)
  val ()=s.search_document := pane_of(s.focus,s.active,s.righti)
  val ()=s.search_source := search_doc_stamp(airlock_nat(MAX_REC_FUEL),s.tabs,s.search_document)
in if ieq(buf_len(s.query),0) then () else case+ literal_pattern_open_default(s.query) of
  | ~None_vt() => s.search_state := SEARCH_UNAVAILABLE
  | ~Some_vt(pattern) => let val old=s.search_pattern
    val ()=s.search_pattern := Some_vt(pattern) val ()=literal_pattern_release(old)
    val ()=if ieq(s.scope,SEARCH_SCOPE_VAULT) then s.search_catalog_ready := false else ()
    val ()=if ieq(s.scope,SEARCH_SCOPE_VAULT) then search_catalog_prepare(s) else ()
  in s.search_state := SEARCH_RUNNING end end
fun append_search_document{n:nat} .<n>. (left: int(n),tabs: !Tabs,index: int,pattern: !LiteralPattern,
  hits: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,rows: &int >> _): SearchAppendResult =
  if left = 0 then @{matches=0,truncated=true} else case+ tabs of
  | TNil() => @{matches=0,truncated=false}
  | TCons(doc,path,title,scroll,rest) => if igt(index,0) then append_search_document(left-1,rest,isub(index,1),pattern,hits,meta,jumps,rows)
    else let var source=buf_make(doc_len(doc)) val length=doc_len(doc)
      val copied=doc_slice_buf(doc,0,length,source,length) val ()=buf_set_len(source,copied)
      val result=search_append_matches(source,path,pattern,0,hits,meta,jumps,rows)
      val ()=buf_free(source)
    in result end
fun append_search_file(files: !Buf,paths: !Buf,tabs: !Tabs,pattern: !LiteralPattern,file: int,
  hits: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,rows: &int >> _): SearchAppendResult = let
  val offset=ix_file_get(files,file,IX_F_PATHOFF)
  val length=ix_file_get(files,file,IX_F_PATHLEN)
  var path=buf_make(length) val ()=buffer_append_range(path,paths,offset,iadd(offset,length))
  val result=search_append_file(path,tabs,pattern,file,hits,meta,jumps,rows)
  val ()=buf_free(path)
in result end
fun search_with_pattern{b:bool}(slot: !option_vt(LiteralPattern,b),scope: int,document: int,file: int,
  files: !Buf,paths: !Buf,tabs: !Tabs,hits: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,rows: &int >> _): SearchAppendResult =
  case+ slot of | None_vt() => @{matches=0,truncated=true} | Some_vt(pattern) =>
    if ieq(scope,SEARCH_SCOPE_DOCUMENT) then append_search_document(airlock_nat(MAX_REC_FUEL),tabs,document,pattern,hits,meta,jumps,rows)
    else append_search_file(files,paths,tabs,pattern,file,hits,meta,jumps,rows)
fun search_process_one(s: &App_record >> _): void = let
  val result=search_with_pattern(s.search_pattern,s.scope,s.search_document,s.search_cursor,
    s.ixf,s.ixp,s.tabs,s.hits,s.hmeta,s.hjump,s.hn)
  val ()=if result.truncated then s.search_skipped := true else ()
  val ()=if igt(result.matches,0) then s.search_nfiles := iadd(s.search_nfiles,1) else ()
in s.search_cursor := iadd(s.search_cursor,1) end
fun search_drain{n:nat} .<n>. (left: int(n),s: &App_record >> _,deadline: lint): void =
  if left = 0 then () else let
    val total=if ieq(s.scope,SEARCH_SCOPE_DOCUMENT) then 1 else ix_file_count(s.ixf)
  in if ige(s.search_cursor,total) orelse ige(s.hn,SEARCH_RESULT_LIMIT) then
    s.search_state := (if s.search_skipped orelse ige(s.hn,SEARCH_RESULT_LIMIT) then SEARCH_PARTIAL else SEARCH_IDLE)
    else if mono_ns() >= deadline then () else let val ()=search_process_one(s)
    in search_drain(left-1,s,deadline) end end
fun search_refresh_document(s: &App_record >> _): void =
  if ieq(s.scope,SEARCH_SCOPE_DOCUMENT) andalso igt(buf_len(s.query),0) then let
    val index=pane_of(s.focus,s.active,s.righti) val current=search_doc_stamp(airlock_nat(MAX_REC_FUEL),s.tabs,index)
    val changed=current.document <> s.search_source.document orelse ine(current.generation,s.search_source.generation)
  in if changed then search_job_begin(s) else () end else ()
fun search_job_step(s: &App_record >> _): void =
  if is_side_search(s.side) then let val ()=search_refresh_document(s)
  in if ieq(s.search_state,SEARCH_RUNNING) then
    search_drain(airlock_nat(iadd(MAX_INDEX_FILES,1)),s,mono_ns()+SEARCH_WORK_BUDGET_NS) else () end else ()
