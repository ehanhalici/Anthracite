%{#
#include "os/diag.cats"
%}

fun diag_log_raw(lvl: string, file: string, line: int, tag: string, msg: string, det: string): void = "mac#anth_diag_log"
fun report_failure(event: string, path: string): void
fun report_failure_at(event: string, path: string, file: string, line: int): void

fun log_error_at(file: string, line: int, tag: string, msg: string, det: string): void
fun log_warn_at(file: string, line: int, tag: string, msg: string, det: string): void
fun log_info_at(file: string, line: int, tag: string, msg: string, det: string): void

fun log_error(tag: string, msg: string, det: string): void
fun log_warn(tag: string, msg: string, det: string): void
fun log_info(tag: string, msg: string, det: string): void
