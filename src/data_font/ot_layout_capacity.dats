#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "data_font/ot_layout_work.sats"
implement ot_layout_charge(remaining,count) =
  if ilt(count,0) orelse ilt(remaining,count) then false
  else let val ()=remaining := isub(remaining,count) in true end

