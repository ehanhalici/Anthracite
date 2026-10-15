%{#
#include "os/diag.cats"
%}

macdef LOG_LEVEL_DEBUG = 0
macdef LOG_LEVEL_INFO = 1
macdef LOG_LEVEL_WARN = 2
macdef LOG_LEVEL_ERROR = 3
macdef LOG_LEVEL_SILENT = 4

fun diag_set_level(lvl: int): void = "mac#anth_diag_set_level"
fun diag_get_level(): int = "mac#anth_diag_get_level"

fun diag_log_raw(lvl: string, file: string, line: int, tag: string, msg: string, det: string): void = "mac#anth_diag_log"
fun report_failure(event: string, path: string): void
fun report_failure_at(event: string, path: string, file: string, line: int): void

fun log_error_at(file: string, line: int, tag: string, msg: string, det: string): void
fun log_warn_at(file: string, line: int, tag: string, msg: string, det: string): void
fun log_info_at(file: string, line: int, tag: string, msg: string, det: string): void
fun log_debug_at(file: string, line: int, tag: string, msg: string, det: string): void

fun log_error(tag: string, msg: string, det: string): void
fun log_warn(tag: string, msg: string, det: string): void
fun log_info(tag: string, msg: string, det: string): void
fun log_debug(tag: string, msg: string, det: string): void
