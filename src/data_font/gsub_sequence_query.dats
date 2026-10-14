#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/gsub_sequences.sats"
staload "data_font/gsub_sequence_work.sats"
implement gsub_sequences_query_info(b,info,glyph) = let
  val index=ot_coverage_index(b,info.coverage,glyph)
in if not(index.found) then @{matched=false,span= @{offset=0,length=0},count=0}
  else let val child=gsub_sequence_child(b,info,index.index) in
    @{matched=true,span=child.span,count=ot_u16(b,child.span,0)} end end
implement gsub_sequences_query(b,table,glyph) = let val+ GsubSequences(info)=table in
  gsub_sequences_query_info(b,info,glyph) end
implement gsub_sequence_glyph(b,view,index) =
  ot_u16(b,view.span,iadd(2,imul(airlock_below(index,airlock_pos(view.count)),2)))
implement gsub_alternate_select_info(b,info,glyph,choice) = let
  val view=gsub_sequences_query_info(b,info,glyph)
in if not(view.matched) orelse ile(choice,0) orelse igt(choice,view.count)
  then @{matched=false,glyph=glyph}
  else @{matched=true,glyph=gsub_sequence_glyph(b,view,isub(choice,1))} end
implement gsub_alternate_select(b,table,glyph,choice) = let val+ GsubSequences(info)=table in
  gsub_alternate_select_info(b,info,glyph,choice) end
implement gsub_sequences_dispose(table) = let val+ ~GsubSequences(info)=table in () end
