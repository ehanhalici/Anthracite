#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_graph_types.sats"
staload "data_font/glyph_position_graph.sats"
implement glyph_position_graph_make(n) = let
  val origins=arrayptr_make_elt<GlyphPositionOrigin>(i2sz(n),@{x=0LL,y=0LL})
  val states=arrayptr_make_elt<GlyphPositionVisit>(i2sz(n),PositionFresh())
  val path=arrayptr_make_elt<int>(i2sz(n),~1)
in GlyphPositionGraph(n,origins,states,path) end
implement glyph_position_graph_dispose(g) = let val+ ~GlyphPositionGraph(n,o,s,p)=g
  val ()=arrayptr_free(o) and ()=arrayptr_free(s)
in arrayptr_free(p) end
implement glyph_position_graph_visit(g,node) = let val+ GlyphPositionGraph(n,o,s,p)=g
  val i=airlock_below(node,n) in arrayptr_get_at<GlyphPositionVisit>(s,i2sz(i)) end
implement glyph_position_graph_set_visit(g,node,v) = let val+ GlyphPositionGraph(n,o,s,p)=g
  val i=airlock_below(node,n) in arrayptr_set_at<GlyphPositionVisit>(s,i2sz(i),v) end
implement glyph_position_graph_origin(g,node) = let val+ GlyphPositionGraph(n,o,s,p)=g
  val i=airlock_below(node,n) in arrayptr_get_at<GlyphPositionOrigin>(o,i2sz(i)) end
implement glyph_position_graph_set_origin(g,node,v) = let val+ GlyphPositionGraph(n,o,s,p)=g
  val i=airlock_below(node,n) in arrayptr_set_at<GlyphPositionOrigin>(o,i2sz(i),v) end
implement glyph_position_graph_push(g,depth,node) = let val+ GlyphPositionGraph(n,o,s,p)=g
  val i=airlock_below(depth,n) in arrayptr_set_at<int>(p,i2sz(i),node) end
implement glyph_position_graph_path(g,depth) = let val+ GlyphPositionGraph(n,o,s,p)=g
  val i=airlock_below(depth,n) in arrayptr_get_at<int>(p,i2sz(i)) end
