#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_types.sats"
staload "data_text/line_break_map.sats"

implement line_breaks_make(count) = LineBreakMap(buf_make(iadd(count,1)),count)
implement line_breaks_put(map,index,decision) = let val+ LineBreakMap(b,n) = map in
  buf_set(b,index,line_break_code(decision)) end
implement line_break_at(map,index) = let val+ LineBreakMap(b,n) = map in
  line_break_of(buf_get(b,airlock_below(index,airlock_pos(iadd(n,1))))) end
implement line_break_count(map) = let val+ LineBreakMap(b,n) = map in n end
implement line_breaks_dispose(map) = let val+ ~LineBreakMap(b,n) = map in buf_free(b) end
