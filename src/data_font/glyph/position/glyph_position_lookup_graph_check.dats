#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
extern fun graph_check_invariant(): int = "mac#anth_die_int"
fun header(entry: !OtPositionGraphEntry): OtLookupInfo(2) = case+ entry of
  | PositionGraphDirect(t) => let val+ OtPositionLookup(h,a,glyphs,tables)=t in h end
  | PositionGraphContext(h,t) => h | PositionGraphVacant() => let val failed=graph_check_invariant()
    in @{span= @{offset=failed,length=0},action=PosSingle(),flags= @{rtl=false,ignoreBase=false,ignoreLigature=false,
      ignoreMarks=false,useMarkSet=false,attachment=0},count=0,markSet=0} end
fun check{n,i:nat | i <= n} .<n-i>. (index: int(i),t: !OtPositionGraphEntries(n,n),m: !GlyphMetadata,meta: GlyphRunMeta): GlyphPositionStatus = let
  val+ OtPositionGraphEntries(pf,gc | rows,n,filled)=t
in if index = n then PositionReady() else let
  var loan: OtPositionGraphEntry=PositionGraphVacant()
  val ()=array_exch_at<OtPositionGraphEntry>(!rows,i2sz(index),loan)
  val h=header(loan)
  val status=glyph_position_filter_check(m,meta,meta.glyphs,h.flags,h.markSet)
  val ()=array_exch_at<OtPositionGraphEntry>(!rows,i2sz(index),loan)
  val ()=ot_position_graph_entry_dispose(loan)
in if glyph_position_ready(status) then check(index+1,t,m,meta) else status end end
implement glyph_position_lookup_graph_validate(g,m,meta) = let val+ OtPositionGraph(font,glyphs,limits,entries)=g
  val info=glyph_metadata_info(m)
in if ine(font,meta.font) orelse ine(glyphs,meta.glyphs) orelse ine(font,info.font) orelse ine(glyphs,info.glyphs)
  then PositionDomain() else check(0,entries,m,meta) end
implement glyph_position_lookup_graph_check(g,m,meta,lookup) = let val+ OtPositionGraph(font,glyphs,limits,entries)=g
  val+ OtPositionGraphEntries(pf,gc | rows,n,filled)=entries
in if ilt(lookup,0) orelse ige(lookup,n) then PositionReference() else glyph_position_lookup_graph_validate(g,m,meta) end
