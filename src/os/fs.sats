%{#
#include "os/fs.cats"
%}

fun fs_open_read(path: string): int = "mac#anth_open_read"
fun fs_read(fd: int, buf: ptr, n: int): int = "mac#anth_read"
fun fs_atomic_write(path: string, buf: ptr, n: int): int = "mac#anth_atomic_write"
fun fs_close(fd: int): void = "mac#anth_close"
fun fs_size(path: string): int = "mac#anth_size"
fun fs_isdir(path: string): int = "mac#anth_isdir"
fun fs_exists(path: string): int = "mac#anth_exists"
fun fs_mkdir(path: string): int = "mac#anth_mkdir"
fun fs_rename(a: string, b: string): int = "mac#rename"
fun fs_unlink(path: string): int = "mac#unlink"
fun fs_rmdir(path: string): int = "mac#rmdir"
fun fs_vfs_path(path: string, dst: ptr, dstmax: int): void = "mac#anth_vfs_path"

fun dir_open(path: string): ptr = "mac#opendir"
fun dir_close(d: ptr): void = "mac#anth_dirclose"
fun dir_next(d: ptr, name: ptr, namemax: int, isdir: &int >> _): int = "mac#anth_dirnext"

fun mono_ns(): lint = "mac#anth_now_ns"
fun rss_kb(): int = "mac#anth_rss_kb"

fun c_strlen(s: string): int = "mac#strlen"
fun c_strcmp(a: string, b: string): int = "mac#strcmp"
fun c_str_byte(s: string, i: int): int = "mac#anth_str_byte"
fun c_str_ptr(s: string): ptr = "mac#anth_str_ptr"
fun c_getenv(k: string): string = "mac#anth_getenv"
fun c_fc_font(dst: ptr, n: int): int = "mac#anth_fc_font"
fun c_argc(): int = "mac#anth_argc"
fun c_argv(i: int): string = "mac#anth_argv"
fun c_cwd(dst: ptr, n: int): int = "mac#anth_cwd"

fun n_i2d(i: int): double = "mac#anth_i2d"
fun n_d2i(d: double): int = "mac#anth_d2i"
fun n_cos(x: double): double = "mac#cos"
fun n_floor(x: double): double = "mac#floor"
