#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "os/diag.sats"

implement log_error_at(file, line, tag, msg, det) =
  diag_log_raw("ERROR", file, line, tag, msg, det)

implement log_warn_at(file, line, tag, msg, det) =
  diag_log_raw("WARN", file, line, tag, msg, det)

implement log_info_at(file, line, tag, msg, det) =
  diag_log_raw("INFO", file, line, tag, msg, det)

implement log_error(tag, msg, det) =
  diag_log_raw("ERROR", $extval(string, "__FILE__"), $extval(int, "__LINE__"), tag, msg, det)

implement log_warn(tag, msg, det) =
  diag_log_raw("WARN", $extval(string, "__FILE__"), $extval(int, "__LINE__"), tag, msg, det)

implement log_info(tag, msg, det) =
  diag_log_raw("INFO", $extval(string, "__FILE__"), $extval(int, "__LINE__"), tag, msg, det)

implement report_failure_at(event, path, file, line) =
  diag_log_raw("ERROR", file, line, "OS", event, path)

implement report_failure(event, path) =
  report_failure_at(event, path, $extval(string, "__FILE__"), $extval(int, "__LINE__"))
