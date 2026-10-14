#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_lookups.sats"
implement ot_lookup_dependencies(f,set,caps) =
  (not(f.ignoreBase orelse f.ignoreLigature orelse f.ignoreMarks) orelse caps.classes)
  andalso (ieq(f.attachment,0) orelse caps.attachments)
  andalso (not(f.useMarkSet) orelse (ige(set,0) andalso ilt(set,caps.markSets)))
