fun scheduler_pages{n:nat} .<n>. (left: int(n),root: !Buf,index: int,remove: bool,contents: string): int =
  if left = 0 then 0 else let
    val path=depth_path(root,index)
    val result=if remove then fs_unlink(buf_cstr(path)) else let
      val text=bytes(contents) val length=buf_len(text)
      val written=fs_write_buf(buf_cstr(path),text,length) val ()=buf_free(text)
    in if ieq(written,1) then 0 else 1 end
    val ()=buf_free(path)
  in iadd(if ieq(result,0) then 0 else 1,scheduler_pages(left-1,root,iadd(index,1),remove,contents)) end
fun scheduler_frame(f: !Font,r: !Rend,d: !Doc,root: !Buf,cache: &Cache >> _,scratch: &Buf >> _,scroll: int): void = let
  val ()=rend_begin(r,640,480)
in draw_doc(f,r,d,0,36,640,120,scroll,font_line_h(f),root,cache,scratch,ViewRead) end
fun scheduler_drain{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,d: !Doc,root: !Buf,cache: &Cache >> _,scratch: &Buf >> _): bool =
  if left = 0 then false else let
    val ()=cache_work_begin(cache) val ()=scheduler_frame(f,r,d,root,cache,scratch,0)
  in if cache_work_pending(cache) then scheduler_drain(left-1,f,r,d,root,cache,scratch) else true end
fun scheduler_anchor(f: !Font,r: !Rend,d: Doc,root: !Buf,cache: &Cache >> _,scratch: &Buf >> _): bool = let
  val changed=write_note(root,"depth-C.md","a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk\nl\n") val ()=buf_free(changed)
  val scroll=iadd(doc_line_y(d,3),1)
  val tabs=TCons(d,buf_make(0),buf_make(0),scroll,TNil())
  val ()=cache_work_begin(cache)
  val drawn=draw_focus(f,r,tabs,0,0,36,640,120,font_line_h(f),root,cache,scratch,0,ViewRead)
  val stable=case+ drawn of | TNil() => false | TCons(doc,p,t,sc,rest) => ieq(sc,iadd(doc_line_y(doc,3),1))
  val ()=tabs_free(drawn)
in stable end
fun hidden_embed_schedule(f: !Font,r: !Rend,root: !Buf): int = let
  val source=bytes("# folded\n![[depth-A]]\n") val d=doc_open() val length=buf_len(source)
  val ()=doc_insert_buf(d,source,length) val ()=buf_free(source)
  val node=doc_line_node_foldable(d,0) val ()=doc_toggle(d,node)
  var cache: Cache=CNil() var scratch: Buf=buf_make(256)
  val ()=cache_work_begin(cache) val ()=scheduler_frame(f,r,d,root,cache,scratch,0)
  val ()=performance_enable(1) val ()=performance_reset()
  val ()=cache_work_begin(cache) val ()=scheduler_frame(f,r,d,root,cache,scratch,0)
  val stable=performance_value(PERF_DOCUMENT_LOADS)=0ULL andalso performance_value(PERF_WRAP_BUILDS)=0ULL
    andalso performance_value(PERF_LAYOUT_BUILDS)=0ULL
  val ()=performance_enable(0) val ()=cache_free(cache) val ()=buf_free(scratch) val ()=doc_free(d)
in if stable then 0 else 1 end
fun scheduled_view_exists{n:nat} .<n>. (left: int(n),cache: !Cache,path: !Buf,stamp: EmbedSourceStamp,key: VisualKey): bool =
  if left = 0 then false else case+ cache of | CNil() => false
  | CWork(s,pins,rest) => scheduled_view_exists(left-1,rest,path,stamp,key)
  | CSelection(s,p,rest) => scheduled_view_exists(left-1,rest,path,stamp,key)
  | CCons(p,t,w,h,rest) => scheduled_view_exists(left-1,rest,path,stamp,key)
  | CEmbed(p,s,d,w,h,rest) => scheduled_view_exists(left-1,rest,path,stamp,key)
  | CView(p,s,state,rest) => let
      val matches=case+ state of | EmbedViewPending() => false | EmbedViewReady(k,g) =>
        buffer_equal_from(p,path,0) andalso embedded_source_equal(s,stamp) andalso visual_key_context_matches(k,key)
    in matches orelse scheduled_view_exists(left-1,rest,path,stamp,key) end
fun scheduled_pins_saved{n:nat} .<n>. (left: int(n),pins: !EmbedPins,cache: !Cache,count: &int >> _): bool =
  if left = 0 then false else case+ pins of | EmbedPinsNil() => true
  | EmbedPinsCons(path,stamp,key,rest) => let val ()=count := iadd(count,1)
    in scheduled_view_exists(512,cache,path,stamp,key) andalso scheduled_pins_saved(left-1,rest,cache,count) end
fun copy_scheduled_pins{n:nat} .<n>. (left: int(n),pins: !EmbedPins): EmbedPins =
  if left = 0 then EmbedPinsNil() else case+ pins of | EmbedPinsNil() => EmbedPinsNil()
  | EmbedPinsCons(path,stamp,key,rest) => let var copy: Buf=buf_make(buf_len(path))
      val ()=buffer_append_range(copy,path,0,buf_len(path))
    in EmbedPinsCons(copy,stamp,key,copy_scheduled_pins(left-1,rest)) end
fun snapshot_scheduled_pins{n:nat} .<n>. (left: int(n),cache: !Cache): EmbedPins =
  if left = 0 then EmbedPinsNil() else case+ cache of | CNil() => EmbedPinsNil()
  | CWork(s,pins,rest) => copy_scheduled_pins(128,pins)
  | CSelection(s,p,rest) => snapshot_scheduled_pins(left-1,rest)
  | CCons(p,t,w,h,rest) => snapshot_scheduled_pins(left-1,rest)
  | CEmbed(p,s,d,w,h,rest) => snapshot_scheduled_pins(left-1,rest)
  | CView(p,s,state,rest) => snapshot_scheduled_pins(left-1,rest)
extern fun release_scheduled_pins_exhausted(pins: EmbedPins): void = "mac#anth_die_void"
fun release_scheduled_pins{n:nat} .<n>. (left: int(n),pins: EmbedPins): void =
  if not(recursion_fuel_available(left)) then release_scheduled_pins_exhausted(pins)
  else case+ pins of | ~EmbedPinsNil() => () | ~EmbedPinsCons(path,stamp,key,rest) =>
    let val ()=buf_free(path) in release_scheduled_pins(left-1,rest) end
fun all_scheduled_pins(cache: !Cache,count: &int >> _): bool = let
  val pins=snapshot_scheduled_pins(512,cache)
  val saved=scheduled_pins_saved(128,pins,cache,count)
  val ()=release_scheduled_pins(128,pins)
in saved end
fun scheduler_visible_pins(f: !Font,r: !Rend,d: !Doc,root: !Buf,cache: &Cache >> _,scratch: &Buf >> _): bool = let
  val ()=cache_work_begin(cache) val ()=scheduler_frame(f,r,d,root,cache,scratch,0)
  val ()=populate_views(26,f,r,d,cache,root,0) var count: int=0
  val pinned=all_scheduled_pins(cache,count) val stats=cache_embed_stats(cache)
in pinned andalso igt(count,0) andalso ieq(stats.views,128) andalso stats.viewBytes <= 67108864LL end
fun overscan_closure_frame(f: !Font,r: !Rend,d: !Doc,root: !Buf,cache: &Cache >> _,scratch: &Buf >> _): void = let
  val lh=font_document_line_height(f,font_line_h(f))
  val ()=rend_begin(r,640,480)
in draw_doc(f,r,d,0,36,640,imul(iadd(lh,8),2),0,font_line_h(f),root,cache,scratch,ViewRead) end
fun overscan_closure_case(f: !Font,r: !Rend,root: !Buf): int = let
  val created=scheduler_pages(5,root,0,false,"short\n")
  val source=bytes("![[depth-A]]\n![[depth-B]]\n![[depth-C]]\n![[depth-D]]\n![[depth-E]]\n")
  val d=doc_open() val length=buf_len(source) val ()=doc_insert_buf(d,source,length) val ()=buf_free(source)
  val scope: EmbedWorkScope= @{active=false,document=the_null_ptr,anchorLine= ~1,scroll=0,height=0,foreground=true,childDelta=0,band=EmbedWorkVisible()}
  val state: EmbedWorkState= @{enabled=true,deadline=mono_ns()+60000000000L,pending=false,scope=scope}
  var cache: Cache=CWork(state,EmbedPinsNil(),CNil()) var scratch: Buf=buf_make(256)
  val ()=overscan_closure_frame(f,r,d,root,cache,scratch)
  val first=cache_embed_stats(cache) val height=doc_layout_cache_height(d) val ready=not(cache_work_pending(cache))
  val ()=performance_enable(1) val ()=performance_reset() val ()=cache_work_begin(cache)
  val ()=overscan_closure_frame(f,r,d,root,cache,scratch)
  val warm=performance_value(PERF_DOCUMENT_LOADS)=0ULL andalso performance_value(PERF_WRAP_BUILDS)=0ULL andalso performance_value(PERF_LAYOUT_BUILDS)=0ULL
  val after=cache_embed_stats(cache) val stable=ieq(height,doc_layout_cache_height(d)) andalso ieq(first.documents,after.documents)
  val ()=performance_enable(0) val ()=cache_free(cache) val ()=buf_free(scratch) val ()=doc_free(d)
  val removed=scheduler_pages(5,root,0,true,"")
  val ()=println!("event=overscan_closure ready=",ready," warm=",warm," stable=",stable," documents=",first.documents)
in iadd(created+removed,if ready andalso warm andalso stable andalso igt(first.documents,0) andalso ilt(first.documents,5) then 0 else 1) end
fun scheduler_fixture(f: !Font,r: !Rend,root: !Buf): int = let
  val closure=overscan_closure_case(f,r,root)
  val created=scheduler_pages(5,root,0,false,"alpha\nbeta\ngamma\ndelta\nepsilon\nzeta\n")
  val hidden=hidden_embed_schedule(f,r,root)
  val source=bytes("![[depth-A]]\n![[depth-B]]\n![[depth-C]]\n![[depth-D]]\n![[depth-E]]\n")
  val d=doc_open() val length=buf_len(source) val ()=doc_insert_buf(d,source,length) val ()=buf_free(source)
  val scope: EmbedWorkScope= @{active=false,document=the_null_ptr,anchorLine= ~1,scroll=0,height=0,foreground=true,childDelta=0,band=EmbedWorkVisible()}
  val state: EmbedWorkState= @{enabled=true,deadline=1L,pending=false,scope=scope}
  var cache: Cache=CWork(state,EmbedPinsNil(),CNil()) var scratch: Buf=buf_make(256)
  val ()=scheduler_frame(f,r,d,root,cache,scratch,0)
  val stats=cache_embed_stats(cache)
  val deferred=cache_work_pending(cache) andalso igt(stats.documents,0) andalso ilt(stats.documents,5) andalso ieq(stats.pending,0)
  val drained=scheduler_drain(10,f,r,d,root,cache,scratch)
  val ready=cache_embed_stats(cache) val limited=ilt(ready.documents,5)
  val ()=cache_work_begin(cache) val ()=scheduler_frame(f,r,d,root,cache,scratch,imax(0,isub(doc_layout_cache_height(d),120)))
  val end_stats=cache_embed_stats(cache) val reached=igt(end_stats.documents,ready.documents)
  val pinned=scheduler_visible_pins(f,r,d,root,cache,scratch)
  val stable=scheduler_anchor(f,r,d,root,cache,scratch)
  val ()=cache_free(cache) val ()=buf_free(scratch)
  val removed=scheduler_pages(5,root,0,true,"")
  val ()=println!("event=embed_scheduler deferred=",deferred," drained=",drained," limited=",limited," reached=",reached," anchor=",stable," pins=",pinned)
in iadd(created+removed+hidden+closure,if deferred andalso drained andalso limited andalso reached andalso stable andalso pinned then 0 else 1) end
