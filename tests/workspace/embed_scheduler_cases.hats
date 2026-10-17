fun scheduler_pages{n:nat} .<n>. (left: int(n),root: !Buf,index: int,remove: bool): int =
  if left = 0 then 0 else let
    val path=depth_path(root,index)
    val result=if remove then fs_unlink(buf_cstr(path)) else let
      val text=bytes("alpha\nbeta\ngamma\ndelta\nepsilon\nzeta\n") val length=buf_len(text)
      val written=fs_write_buf(buf_cstr(path),text,length) val ()=buf_free(text)
    in if ieq(written,1) then 0 else 1 end
    val ()=buf_free(path)
  in iadd(if ieq(result,0) then 0 else 1,scheduler_pages(left-1,root,iadd(index,1),remove)) end
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
fun scheduler_fixture(f: !Font,r: !Rend,root: !Buf): int = let
  val created=scheduler_pages(5,root,0,false)
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
  val stable=scheduler_anchor(f,r,d,root,cache,scratch)
  val ()=cache_free(cache) val ()=buf_free(scratch)
  val removed=scheduler_pages(5,root,0,true)
  val ()=println!("event=embed_scheduler deferred=",deferred," drained=",drained," limited=",limited," reached=",reached," anchor=",stable)
in iadd(created+removed,if deferred andalso drained andalso limited andalso reached andalso stable then 0 else 1) end
