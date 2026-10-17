#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_work.sats"
fun empty(): GsubSequenceInfo = @{span= @{offset=0,length=0},
  coverage= @{span= @{offset=0,length=0},encoding=OtList(),count=0,total=0},count=0,glyphs=0}
implement ot_sequence_tables_make(count) = let
  val rows=arrayptr_make_elt<GsubSequenceInfo>(g1int2uint_int_size(count),empty())
in OtSequenceTables(rows,count,0) end
implement ot_sequence_tables_append(t,info) = let val+ ~OtSequenceTables(rows,count,filled)=t
  val ()=arrayptr_set_at<GsubSequenceInfo>(rows,g1int2uint_int_size(filled),info)
in OtSequenceTables(rows,count,filled+1) end
implement ot_sequence_tables_get(t,index) = let val+ OtSequenceTables(rows,count,filled)=t in
  arrayptr_get_at<GsubSequenceInfo>(rows,g1int2uint_int_size(airlock_below(index,count))) end
implement ot_sequence_tables_dispose(t) = let val+ ~OtSequenceTables(rows,count,filled)=t in arrayptr_free(rows) end
