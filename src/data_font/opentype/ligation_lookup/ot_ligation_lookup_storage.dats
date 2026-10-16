#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/opentype/substitution/gsub_ligatures.sats"
staload "data_font/opentype/substitution/gsub_ligature_work.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_work.sats"
fun empty(): GsubLigatureInfo = @{span= @{offset=0,length=0},
  coverage= @{span= @{offset=0,length=0},encoding=OtList(),count=0,total=0},count=0,glyphs=0,maximum=0}
implement ot_ligation_tables_make(n) = let
  val rows=arrayptr_make_elt<GsubLigatureInfo>(i2sz(n),empty())
in OtLigationTables(rows,n,0) end
implement ot_ligation_tables_append(t,info) = let val+ ~OtLigationTables(rows,n,i)=t
  val ()=arrayptr_set_at<GsubLigatureInfo>(rows,i2sz(i),info)
in OtLigationTables(rows,n,i+1) end
implement ot_ligation_tables_get(t,index) = let val+ OtLigationTables(rows,n,i)=t
in arrayptr_get_at<GsubLigatureInfo>(rows,i2sz(airlock_below(index,i))) end
implement ot_ligation_tables_dispose(t) = let val+ ~OtLigationTables(rows,n,i)=t in arrayptr_free(rows) end
