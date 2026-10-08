#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "os/diag.sats"

implement report_failure(event, path) = let
  val () = println! ("event=", event, " status=failed path=", path)
in
end
