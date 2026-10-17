fun math_heights{n:nat} .<n>. (left: int(n),d: !Doc,i: int,lh: int): bool =
  if left = 0 then true else let
    val matches=if is_kind(doc_node_kind(d,i),KMathb) then ieq(doc_node_height(d,i),doc_math_block_height(lh)) else true
  in matches andalso math_heights(left-1,d,iadd(i,1),lh) end
fun math_geometry_case(f: !Font,r: !Rend,d: !Doc,mode: ViewMode,width: int): bool = let
  val root=buf_make(0) var cache=CNil() var scratch=buf_make(0)
  val ()=cache_work_begin(cache) val ()=rend_begin(r,640,480)
  val ()=draw_doc(f,r,d,0,36,width,400,0,font_line_h(f),root,cache,scratch,mode)
  val lh=font_document_line_height(f,font_line_h(f)) val version=doc_layout_version(d)
  val height=doc_layout_cache_height(d) val correct=math_heights(airlock_nat(doc_nnodes(d)),d,0,lh)
  val ()=performance_enable(1) val ()=performance_reset()
  val ()=cache_work_begin(cache) val ()=rend_begin(r,640,480)
  val ()=draw_doc(f,r,d,0,36,width,400,0,font_line_h(f),root,cache,scratch,mode)
  val stable=ieq(version,doc_layout_version(d)) andalso ieq(height,doc_layout_cache_height(d))
    andalso performance_value(PERF_WRAP_BUILDS)=0ULL andalso performance_value(PERF_LAYOUT_BUILDS)=0ULL
  val ()=performance_enable(0) val ()=cache_free(cache) val ()=buf_free(scratch) val ()=buf_free(root)
in correct andalso stable end
fun math_geometry(f: !Font,r: !Rend): int = let
  val d=doc_open() val text=bytes("$$ x^{∞}+y_1 $$\n\n$$\\sqrt{x^2}$$\n")
  val length=buf_len(text) val ()=doc_insert_buf(d,text,length) val ()=buf_free(text)
  val previous=font_get_px(f) val ()=font_set_px(f,18)
  val read=math_geometry_case(f,r,d,ViewRead,640) val edit=math_geometry_case(f,r,d,ViewEdit,480)
  val ()=font_set_px(f,24) val large=math_geometry_case(f,r,d,ViewRead,480)
  val ()=font_set_px(f,28) val larger=math_geometry_case(f,r,d,ViewRead,640)
  val ()=font_set_px(f,previous) val ()=doc_free(d)
  val ()=println!("event=math_geometry read=",read," edit=",edit," large=",large," larger=",larger)
in if read andalso edit andalso large andalso larger then 0 else 1 end
