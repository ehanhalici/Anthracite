#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "os/fs.sats"
staload "os/file_stamp.sats"
implement file_stamp(path) = let
  var seconds: lint = 0L var nanoseconds: int = 0 var length: lint = 0L
  var device: ullint = 0ULL var inode: ullint = 0ULL
  val ok = fs_stat_stamp_raw(path, seconds, nanoseconds, length, device, inode)
in if ieq(ok, 0) then None_vt()
  else Some_vt(@{seconds=seconds,nanoseconds=nanoseconds,length=length,device=device,inode=inode}) end
implement file_stamp_equal(a, b) =
  a.seconds = b.seconds andalso ieq(a.nanoseconds, b.nanoseconds) andalso a.length = b.length
  andalso a.device = b.device andalso a.inode = b.inode
