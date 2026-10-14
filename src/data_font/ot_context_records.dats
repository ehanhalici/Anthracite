#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_context_work.sats"
implement ot_context_set(b,info,index) = ot_optional_child(info.span,
  ot_u16(b,info.span,iadd(info.setHeader,imul(index,2))),info.floor)
implement ot_context_rule(b,set,index) = ot_optional_child(set,ot_u16(b,set,iadd(2,imul(index,2))),
  iadd(2,imul(ot_u16(b,set,0),2)))
