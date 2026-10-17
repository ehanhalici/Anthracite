macdef GEOMETRY_NODE_WORDS = 1
macdef GEOMETRY_NODE_AUX = 0
fun capture_geometry_nodes{n:nat} .<n>. (left: int(n),d: !Doc,snapshot: !Buf,i: int): void =
  if left = 0 then () else let val at=imul(i,GEOMETRY_NODE_WORDS)
    val ()=buf_set32(snapshot,iadd(at,GEOMETRY_NODE_AUX),doc_node_aux(d,i))
  in capture_geometry_nodes(left-1,d,snapshot,iadd(i,1)) end
fun restore_geometry_nodes{n:nat} .<n>. (left: int(n),d: !Doc,snapshot: !Buf,i: int): void =
  if left = 0 then () else let val at=imul(i,GEOMETRY_NODE_WORDS)
    val ()=doc_set(d,i,NF_AUX,buf_get32(snapshot,iadd(at,GEOMETRY_NODE_AUX)))
  in restore_geometry_nodes(left-1,d,snapshot,iadd(i,1)) end
implement doc_geometry_take(d) = let
  val snapshot=buf_make(imul(imul(doc_nnodes(d),GEOMETRY_NODE_WORDS),WORD32_BYTES))
  val ()=capture_geometry_nodes(airlock_nat(doc_nnodes(d)),d,snapshot,0)
  val+ @DOC(s)=d val layout=s.lay val visual=s.visual val version=s.ver
  val ()=s.lay := layout_open() val ()=s.visual := None_vt() prval ()=fold@(d)
in DocGeometry(layout,visual,snapshot,version) end
implement doc_geometry_put(d,geometry) = let val+ ~DocGeometry(layout,visual,snapshot,version)=geometry
  val ()=restore_geometry_nodes(airlock_nat(doc_nnodes(d)),d,snapshot,0) val ()=buf_free(snapshot)
  val+ @DOC(s)=d val old_layout=s.lay val old_visual=s.visual
  val ()=s.lay := layout val ()=s.visual := visual val ()=s.ver := version
  val ()=layout_dispose(old_layout) val ()=visual_release(old_visual)
in fold@(d) end
implement doc_geometry_dispose(geometry) = let val+ ~DocGeometry(layout,visual,snapshot,version)=geometry
  val ()=layout_dispose(layout) val ()=visual_release(visual)
in buf_free(snapshot) end
implement doc_geometry_key(geometry) = let val+ DocGeometry(layout,visual,snapshot,version)=geometry
in case+ visual of | None_vt() => None() | Some_vt(rows) => let val+ VisualRows(t,m,l,data,n,key,plans)=rows in Some(key) end end
fun visual_geometry_bytes{b:bool}(visual: !option_vt(VisualRows,b)): llint = case+ visual of
  | None_vt() => 0LL | Some_vt(rows) => let val+ VisualRows(t,m,l,data,n,key,plans)=rows
  in g0int2int_int_llint(buf_cap(t))+g0int2int_int_llint(buf_cap(m))
    +g0int2int_int_llint(buf_cap(l))+g0int2int_int_llint(buf_cap(data))+visual_plans_bytes(plans) end
implement doc_geometry_bytes(geometry) = let val+ DocGeometry(layout,visual,snapshot,version)=geometry
in g0int2int_int_llint(buf_cap(layout))+g0int2int_int_llint(buf_cap(snapshot))+visual_geometry_bytes(visual) end
implement doc_set_view_range(d,start,finish) = case+ d of | @DOC(s) => let
  val ()=s.view_start := imax(0,imin(start,s.len)) val ()=s.view_finish := imax(s.view_start,imin(finish,s.len))
in fold@(d) end
implement doc_view_range(d) = case+ d of | @DOC(s) => let
  val range= @{start=s.view_start,finish=if s.view_finish < 0 then s.len else s.view_finish} prval ()=fold@(d)
in range end
implement doc_parse_generation(d) = case+ d of | @DOC(s) => let val generation=s.parse_generation prval ()=fold@(d) in generation end
