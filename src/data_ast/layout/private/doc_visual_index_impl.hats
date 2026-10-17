extern fun visual_index_capacity(rows: VisualRows): VisualRows = "mac#anth_die_box"
fun visual_prefix{n:nat} .<n>. (left: int(n),d: !Doc,data: !Buf,base: int,i: int,previous: int): void =
  if left = 0 then () else let
    val bottom=imax(previous,iadd(doc_node_y(d,i),doc_node_height(d,i)))
    val ()=buf_set32(data,iadd(base,i),bottom)
  in visual_prefix(left-1,d,data,base,iadd(i,1),bottom) end
fun visual_index(d: !Doc,rows: VisualRows): VisualRows = let val+ VisualRows(t,m,l,data,n,k,plans)=rows
  val words=iadd(imul(n,5),doc_nnodes(d))
in if igt(words,268435455) then visual_index_capacity(rows) else let
  val+ ~VisualRows(t,m,l,old,n,k,plans)=rows var data: Buf=old
  val ()=buf_ensure(data,imul(words,4))
  val ()=visual_prefix(airlock_nat(doc_nnodes(d)),d,data,imul(n,5),0,0)
  val ()=buf_set_len(data,imul(words,4))
in VisualRows(t,m,l,data,n,k,plans) end end
fun visual_reindex(d: !Doc,state: Option_vt(VisualRows)): Option_vt(VisualRows) = case+ state of
  | ~None_vt() => None_vt() | ~Some_vt(rows) => Some_vt(visual_index(d,rows))
implement doc_visual_index(d) = let val state=doc_visual_take(d)
  val () = performance_note(PERF_VISUAL_INDEX_BUILDS, 1)
  val updated=visual_reindex(d,state)
in doc_visual_put(d,updated) end
fun visual_bottom{b:bool}(state: !option_vt(VisualRows,b),index: int): Option(int) = case+ state of
  | None_vt() => None() | Some_vt(rows) => let val+ VisualRows(t,m,l,data,n,k,plans)=rows val at=iadd(imul(n,5),index)
  in if ige(at,0) andalso ilt(at,idiv(buf_len(data),4)) then Some(buf_get32(data,at)) else None() end
implement doc_visual_node_bottom(d,index) = case+ d of | @DOC(s) => let
  val bottom=visual_bottom(s.visual,index) prval ()=fold@(d)
in bottom end
