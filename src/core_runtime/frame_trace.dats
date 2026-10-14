#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "os/fs.sats"
staload "core_runtime/frame_trace.sats"
implement frame_trace(started) =
  if c_strcmp(c_getenv("ANTHRACITE_TRACE_FRAMES"),"1") = 0 then
    println!("event=frame_present elapsed_ns=",mono_ns()-started)
  else ()
