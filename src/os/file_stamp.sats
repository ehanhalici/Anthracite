(* File identity as the OS reports it, wrapped once: the stat call is the only
   boundary, and its failure is a None_vt, never a sentinel value. *)
typedef FileStamp = @{seconds=lint,nanoseconds=int,length=lint,device=ullint,inode=ullint}
fun file_stamp(path: string): Option_vt(FileStamp)
fun file_stamp_equal(a: FileStamp,b: FileStamp): bool
