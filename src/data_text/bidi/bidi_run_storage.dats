#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_runs.sats"

implement bidi_runs_make(capacity) = let
  val size = imul(capacity,4)
  val active = buf_make(size)
  val mapping = buf_make(size)
  val starts = buf_make(size)
  val ends = buf_make(size)
  val links = buf_make(size)
  val incoming = buf_make(size)
  val before = buf_make(size)
  val after = buf_make(size)
  val levels = buf_make(size)
in BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) end

implement bidi_runs_dispose(runs) = let
  val+ ~BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs
  val () = buf_free(active)
  val () = buf_free(mapping)
  val () = buf_free(starts)
  val () = buf_free(ends)
  val () = buf_free(links)
  val () = buf_free(incoming)
  val () = buf_free(before)
  val () = buf_free(after)
in buf_free(levels) end

implement bidi_run_active(runs,i) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_get32(active,i) end
implement bidi_run_set_active(runs,i,value) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_set32(active,i,value) end
implement bidi_run_map(runs,i) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_get32(mapping,i) end
implement bidi_run_set_map(runs,i,value) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_set32(mapping,i,value) end
implement bidi_run_start(runs,i) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_get32(starts,i) end
implement bidi_run_set_start(runs,i,value) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_set32(starts,i,value) end
implement bidi_run_end(runs,i) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_get32(ends,i) end
implement bidi_run_set_end(runs,i,value) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_set32(ends,i,value) end
implement bidi_run_next(runs,i) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_get32(links,i) end
implement bidi_run_set_next(runs,i,value) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_set32(links,i,value) end
implement bidi_run_before(runs,i) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_get32(before,i) end
implement bidi_run_set_before(runs,i,value) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_set32(before,i,value) end
implement bidi_run_after(runs,i) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_get32(after,i) end
implement bidi_run_set_after(runs,i,value) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_set32(after,i,value) end
implement bidi_run_level(runs,i) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_get32(levels,i) end
implement bidi_run_set_level(runs,i,value) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_set32(levels,i,value) end
implement bidi_run_incoming(runs,i) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in igt(buf_get32(incoming,i),0) end
implement bidi_run_set_incoming(runs,i) = let val+ BidiRuns(active,mapping,starts,ends,links,incoming,before,after,levels) = runs in buf_set32(incoming,i,1) end
