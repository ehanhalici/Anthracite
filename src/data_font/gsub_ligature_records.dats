#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligature_work.sats"
implement gsub_ligature_set(b,info,index) = ot_optional_child(info.span,
  ot_u16(b,info.span,iadd(6,imul(index,2))),iadd(6,imul(info.count,2)))
implement gsub_ligature_rule(b,set,index) = ot_optional_child(set,
  ot_u16(b,set,iadd(2,imul(index,2))),iadd(2,imul(ot_u16(b,set,0),2)))
