#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization_graph.sats"

fun init_heads {n:nat} .<n>. (n: int(n), heads: !Buf, i: int): void =
  if n = 0 then () else let val () = buf_set32(heads,i,~1) in init_heads(n-1,heads,iadd(i,1)) end

implement norm_graph_make(rows,mappings) = let
  val heads = buf_make(imul(rows,4))
  val pending = buf_make(imul(rows,4))
  val targets = buf_make(imul(mappings,4))
  val next = buf_make(imul(mappings,4))
  val queue = buf_make(imul(rows,4))
  val meta = buf_make(12)
  val () = init_heads(airlock_nat(rows),heads,0)
in NormalizationGraph(heads,pending,targets,next,queue,meta) end

implement norm_graph_head(graph,node) = let val+ NormalizationGraph(heads,pending,targets,next,queue,meta) = graph in buf_get32(heads,node) end
implement norm_graph_pending(graph,node) = let val+ NormalizationGraph(heads,pending,targets,next,queue,meta) = graph in buf_get32(pending,node) end
implement norm_graph_target(graph,edge) = let val+ NormalizationGraph(heads,pending,targets,next,queue,meta) = graph in buf_get32(targets,edge) end
implement norm_graph_next(graph,edge) = let val+ NormalizationGraph(heads,pending,targets,next,queue,meta) = graph in buf_get32(next,edge) end

implement norm_graph_add(graph,child,parent) = let
  val+ NormalizationGraph(heads,pending,targets,next,queue,meta) = graph
  val edge = buf_get32(meta,0)
  val () = buf_set32(targets,edge,parent)
  val () = buf_set32(next,edge,buf_get32(heads,child))
  val () = buf_set32(heads,child,edge)
  val () = buf_set32(pending,parent,iadd(buf_get32(pending,parent),1))
in buf_set32(meta,0,iadd(edge,1)) end

implement norm_graph_push(graph,node) = let
  val+ NormalizationGraph(heads,pending,targets,next,queue,meta) = graph
  val tail = buf_get32(meta,2)
  val () = buf_set32(queue,tail,node)
in buf_set32(meta,2,iadd(tail,1)) end

implement norm_graph_pop(graph) = let
  val+ NormalizationGraph(heads,pending,targets,next,queue,meta) = graph
  val head = buf_get32(meta,1)
  val tail = buf_get32(meta,2)
in if ige(head,tail) then ~1 else let
    val node = buf_get32(queue,head)
    val () = buf_set32(meta,1,iadd(head,1))
  in node end end

implement norm_graph_processed(graph) = let val+ NormalizationGraph(heads,pending,targets,next,queue,meta) = graph in buf_get32(meta,1) end
implement norm_graph_complete_dependency(graph,node) = let
  val+ NormalizationGraph(heads,pending,targets,next,queue,meta) = graph
  val old = buf_get32(pending,node)
  val () = buf_set32(pending,node,isub(old,1))
in ieq(old,1) end

implement norm_graph_dispose(graph) = let
  val+ ~NormalizationGraph(heads,pending,targets,next,queue,meta) = graph
  val () = buf_free(heads)
  val () = buf_free(pending)
  val () = buf_free(targets)
  val () = buf_free(next)
  val () = buf_free(queue)
in buf_free(meta) end
