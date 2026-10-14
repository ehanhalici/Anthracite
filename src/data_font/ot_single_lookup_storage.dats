#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/ot_single_lookup_types.sats"
staload "data_font/ot_single_lookup_work.sats"
fun empty(): GsubSingleInfo = @{span= @{offset=0,length=0},
  coverage= @{span= @{offset=0,length=0},encoding=OtList(),count=0,total=0},
  encoding=GsubArray(),delta=0,count=0,glyphs=0}
implement ot_single_tables_make(count) = let
  val rows=arrayptr_make_elt<GsubSingleInfo>(g1int2uint_int_size(count),empty())
in OtSingleTables(rows,count,0) end
implement ot_single_tables_append(tables,info) = let
  val+ ~OtSingleTables(rows,count,filled)=tables
  val ()=arrayptr_set_at<GsubSingleInfo>(rows,g1int2uint_int_size(filled),info)
in OtSingleTables(rows,count,filled+1) end
implement ot_single_tables_get(tables,index) = let val+ OtSingleTables(rows,count,filled)=tables in
  arrayptr_get_at<GsubSingleInfo>(rows,g1int2uint_int_size(airlock_below(index,count))) end
implement ot_single_tables_dispose(tables) = let val+ ~OtSingleTables(rows,count,filled)=tables in
  arrayptr_free(rows) end
