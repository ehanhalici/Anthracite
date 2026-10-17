#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef VISUAL_PROJECTION_MAKE_BUFFER_INITIAL_BYTES = 256

staload "airlock.sats"
staload "mem.sats"
staload "flag.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/syntax/ast.sats"
staload "data_ast/layout/visual_rows.sats"
staload "ui_workspace/visual/visual_layout.sats"
fun clear{n:nat} .<n>. (left: int(n),mask: !Buf,i: int): void =
  if left = 0 then () else let val ()=buf_set(mask,i,0) in clear(left-1,mask,iadd(i,1)) end
fun hidden(d: !Doc,i: int): bool = let
  val k=doc_node_kind(d,i)
  val p_idx=doc_node_parent(d,i)
  val p_k=if ige(p_idx,0) then doc_node_kind(d,p_idx) else KNone
  val line=doc_line_of(d,doc_node_start(d,i))
  val l_hid=doc_is_line_hidden(d,line)
in ieq(l_hid,1) orelse is_on(doc_node_hidden(d,i)) orelse is_kind(k,KMark) orelse is_kind(k,KLinkDest) orelse is_kind(k,KLinkTitle)
  orelse is_kind(k,KTableDelim) orelse is_kind(p_k,KMathb)
  orelse ine(anth_iand(doc_node_flags(d,i),FL_READ_HIDDEN),0) end
fun nodes{n:nat} .<n>. (left: int(n),d: !Doc,mask: !Buf,i: int): void =
  if left = 0 then () else let
    val ()=if hidden(d,i) then clear(airlock_span(doc_node_start(d,i),doc_node_end(d,i)),mask,doc_node_start(d,i)) else ()
  in nodes(left-1,d,mask,iadd(i,1)) end
fun project{n:nat} .<n>. (left: int(n),d: !Doc,mask: !Buf,text: !Buf,map: !Buf,i: int,at: int): int =
  if left = 0 then let val ()=buf_set32(map,i,at) in at end else let
    val ()=buf_set32(map,i,at) val byte=doc_byte(d,i)
    val keep=ine(buf_get(mask,i),0) orelse ieq(byte,10)
    val ()=if keep then buf_set(text,at,byte) else ()
  in project(left-1,d,mask,text,map,iadd(i,1),if keep then iadd(at,1) else at) end
extern fun capacity(): VisualRows = "mac#anth_die_box"
implement visual_projection_make(d,key) =
  if igt(doc_len(d),isub(MAX_REC_FUEL,2)) then capacity() else let val n=doc_len(d)
    val mask=buf_make(imax(1,n)) val ()=buf_zero(mask)
    fun fill{k:nat} .<k>. (left: int(k),mask: !Buf,i: int): void =
      if left = 0 then () else let val ()=buf_set(mask,i,1) in fill(left-1,mask,iadd(i,1)) end
    val ()=fill(airlock_nat(n),mask,0)
    val ()=case+ key.projection of | VisualSource() => () | VisualRendered() => nodes(airlock_nat(doc_nnodes(d)),d,mask,0)
    val text=buf_make(imax(1,n)) val map=buf_make(imul(iadd(n,1),4))
    val length=project(airlock_nat(n),d,mask,text,map,0,0) val ()=buf_free(mask) val ()=buf_set_len(text,length)
    val lines=buf_make(imul(iadd(doc_nlines(d),1),4))
  in VisualRows(text,map,lines,buf_make(VISUAL_PROJECTION_MAKE_BUFFER_INITIAL_BYTES),0,key,visual_plans_make(VISUAL_ROW_PLAN_CACHE_ENTRIES,doc_nlines(d))) end
