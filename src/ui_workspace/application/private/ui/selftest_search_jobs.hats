fun selftest_search_lines{n:nat} .<n>. (left: int(n),body: &Buf >> _): void =
  if left = 0 then () else let val ()=buffer_append_string(body,"plain line\n")
  in selftest_search_lines(left-1,body) end
fun selftest_search_state(root: string): App_record = let
  var vault=buf_make(0) val ()=buffer_append_string(vault,root)
  val path=selftest_fixture_path(root,"search-jobs.md") var body=buf_make(0)
  val ()=buffer_append_string(body,"# Group\n- parent\n  Needle here\n\n")
  val ()=selftest_search_lines(60,body) val ()=buffer_append_string(body,"İĞNE Needle end\n")
  val length=buf_len(body) val doc=doc_open() val ()=doc_insert_buf(doc,body,length)
  val wrote=fs_write_buf(buf_cstr(path),body,length) val ()=buf_free(body)
  val tabs=TCons(doc,path,buf_make(0),0,TNil())
in app_record_make(vault,tabs,buf_make(0),buf_make(0),buf_make(0),0,buf_make(0),buf_make(0),buf_make(0),0,
  buf_make(0),buf_make(0),buf_make(0),18,0,0,0,0,1,280,0) end
fun selftest_search_release(s: App_record): void = let
  val ()=literal_pattern_release(s.search_pattern)
  val ()=free_input_bufs(s.clip,s.promptb,s.query,s.tree,s.tmeta,s.topen)
  val ()=free_search_bufs(s.hits,s.hmeta,s.scratch,s.imgpath)
  val ()=free_index_bufs(s.ixf,s.ixs,s.ixp,s.ixb,s.ixq,s.hjump)
  val ()=free_font_bufs(s.fpaths,s.fnames,s.fmeta,s.font_path)
in free_app_state(s.vault,s.tabs,s.cache,s.vpaths,s.vnames,s.vmeta,s.tab_pane,s.open_dirs) end
fun selftest_search_drain{n:nat} .<n>. (left: int(n),s: &App_record >> _): bool =
  if left = 0 then false else if ine(s.search_state,SEARCH_RUNNING) then true else let val ()=search_job_step(s)
  in selftest_search_drain(left-1,s) end
fun selftest_search_query(s: &App_record >> _,scope: int,text: string): bool = let
  val ()=s.qfocus := On
  val ()=s.scope := scope val ()=s.side := SideSearch val ()=buffer_clear(s.query)
  val ()=buffer_append_string(s.query,text) val ()=search_job_begin(s)
in selftest_search_drain(100,s) end
fun selftest_search_raw(s: &App_record >> _): bool = let
  val ()=performance_enable(1) val ()=performance_reset()
  val finished=selftest_search_query(s,SEARCH_SCOPE_DOCUMENT,"nEeDlE") val rows=s.hn
  val generation=s.search_cursor val ()=search_query_edit(s,EditNone)
  val stable=ieq(generation,s.search_cursor) andalso ieq(rows,s.hn)
  val raw=performance_value(PERF_DOCUMENT_LOADS)=0ULL andalso performance_value(PERF_AST_PARSES)=0ULL
  val ()=performance_enable(0)
in finished andalso ieq(rows,3) andalso stable andalso raw end
fun selftest_search_click(s: &App_record >> _,f: !Font,r: !Rend): bool = let
  val ()=rend_begin(r,800,600) val ()=draw_sidebar_search(f,r,s,280,600)
  val g=s.search_layout val second=iadd(g.resultsTop,imul(2,g.rowHeight))
  val old=s.tabs val ()=s.tabs := TNil()
  val clicked=handle_search_click(s,old,40,iadd(second,1)) val empty=s.tabs val ()=s.tabs := clicked val ()=tabs_free(empty)
  val line=s.jump_line val col=s.jump_col val ()=draw_editor_panes(f,r,s,280,520,800,600,font_line_h(f))
  val jumped=case+ s.tabs of | TNil() => false | TCons(doc,path,title,scroll,rest) =>
    igt(scroll,0) andalso ieq(doc_line_of(doc,doc_caret(doc)),line)
      andalso ieq(isub(doc_caret(doc),doc_line_start(doc,line)),col) andalso ieq(doc_get_flash(doc,mono_ns()),line)
  val timed=search_flash_wait(mono_ns(),s.flash_until_ns) > 0
in jumped andalso ige(line,60) andalso timed end
fun selftest_search_group_click(s: &App_record >> _): bool = let
  val g=s.search_layout val old=s.tabs val ()=s.tabs := TNil()
  val closed=handle_search_click(s,old,12,g.resultsTop) val empty=s.tabs val ()=s.tabs := closed val ()=tabs_free(empty)
  val hidden=search_visible_count(s.hmeta,s.ixq)
  val old=s.tabs val ()=s.tabs := TNil()
  val opened=handle_search_click(s,old,12,g.resultsTop) val empty=s.tabs val ()=s.tabs := opened val ()=tabs_free(empty)
  val visible=search_visible_count(s.hmeta,s.ixq)
in ieq(hidden,1) andalso ieq(visible,3) end
fun selftest_search_expired(state: App_record): @(App_record,bool) = let
  var app=APP(state)
  val ()=case+ app of | @APP(s) => let val ()=s.search_state := SEARCH_IDLE
    val ()=s.flash_until_ns := mono_ns()-1L in fold@(app) end
  val pending=app_work_pending(app) val delay=app_idle_wait(app)
  val+ ~APP(s)=app
in (s,pending andalso ieq(delay,0)) end
fun selftest_search_ui(r: !Rend,root: string): int = let
  val before=mem_live() var state: App_record=selftest_search_state(root)
  val raw=selftest_search_raw(state) val f=font_open() val native=workspace_font_start(f) val ()=font_set_px(f,18)
  val click=selftest_search_click(state,f,r) val groups=selftest_search_group_click(state)
  val vault=selftest_search_query(state,SEARCH_SCOPE_VAULT,"iğne") val vault_hit=ige(state.hn,2)
  val cancelled=selftest_search_query(state,SEARCH_SCOPE_DOCUMENT,"absent") val empty=ieq(state.hn,0)
  val (state,expired)=selftest_search_expired(state) val ()=font_free(f)
  val path=selftest_fixture_path(root,"search-jobs.md") val removed=fs_unlink(buf_cstr(path)) val ()=buf_free(path)
  val ()=selftest_search_release(state) val balanced=ieq(before,mem_live())
  val ok=raw andalso native andalso click andalso groups andalso vault andalso vault_hit andalso cancelled andalso empty andalso expired andalso balanced andalso ieq(removed,0)
  val ()=println!("event=workspace_search raw=",raw," click=",click," groups=",groups," vault=",vault,
    " hit=",vault_hit," cancelled=",cancelled," empty=",empty," expired=",expired," balanced=",balanced)
in if ok then 1 else 0 end
