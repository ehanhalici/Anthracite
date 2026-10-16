#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "core_runtime/performance.sats"

implement fs_read_buf(fd, b, n) = let
  val bytes = fs_read(fd, buf_ptr(b), n)
  val () = performance_note(PERF_READ_BYTES, bytes)
in bytes end

implement fs_write_buf(path, b, n) = fs_atomic_write(path, buf_ptr(b), n)

implement dir_next_buf(d, name, namemax, isdir) = dir_next(d, buf_ptr(name), namemax, isdir)

implement fs_vfs_buf(path, dst, dstmax) = fs_vfs_path(path, buf_ptr(dst), dstmax)

implement c_cwd_buf(dst, n) = c_cwd(buf_ptr(dst), n)

implement c_fc_font_buf(dst, n) = c_fc_font(buf_ptr(dst), n)
implement c_fc_arabic_font_buf(dst, n) = c_fc_arabic_font(buf_ptr(dst), n)
