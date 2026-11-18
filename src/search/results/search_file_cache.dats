#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "os/fs.sats"
staload "os/file_stamp.sats"
staload "data_text/source/text_source.sats"
staload "search/results/search_file_cache.sats"
macdef SEARCH_FILE_CACHE_BUCKETS = 128
macdef SEARCH_FILE_CACHE_BUDGET_BYTES = 67108864
macdef PATH_HASH_MULTIPLIER = 31
macdef PATH_HASH_MODULUS = 16777213

fun buckets_make{n:nat} .<n>. (left: int(n)): FileBuckets =
  if left = 0 then FileBucketsNil() else FileBucketsCons(FileEntriesNil(),buckets_make(left-1))
implement search_file_cache_make() = FileCache(buckets_make(SEARCH_FILE_CACHE_BUCKETS),0)

fun entries_free(e: FileEntries): void = case+ e of
  | ~FileEntriesNil() => ()
  | ~FileEntriesCons(path,stamp,bytes,rest) => let val ()=buf_free(path) val ()=buf_free(bytes) in entries_free(rest) end
fun buckets_free(b: FileBuckets): void = case+ b of
  | ~FileBucketsNil() => () | ~FileBucketsCons(e,rest) => let val ()=entries_free(e) in buckets_free(rest) end
implement search_file_cache_free(cache) = let val+ ~FileCache(buckets,bytes)=cache in buckets_free(buckets) end

fun hash_text{n:nat} .<n>. (left: int(n),text: string,i: int,h: int): int =
  if left = 0 then h else hash_text(left-1,text,iadd(i,1),imod(iadd(imul(h,PATH_HASH_MULTIPLIER),c_str_byte(text,i)),PATH_HASH_MODULUS))
fun bucket_of(path: string): int = imod(hash_text(airlock_nat(c_strlen(path)),path,0,7),SEARCH_FILE_CACHE_BUCKETS)

fun same_text{n:nat} .<n>. (left: int(n),b: !Buf,text: string,i: int): bool =
  if left = 0 then true else ieq(buf_get(b,i),c_str_byte(text,i)) andalso same_text(left-1,b,text,iadd(i,1))
fun is_path(b: !Buf,path: string): bool = let val n=c_strlen(path)
in ieq(buf_len(b),n) andalso same_text(airlock_nat(n),b,path,0) end
fun copy_of(b: !Buf): Buf = let val n=buf_len(b) var c=buf_make(imax(1,n)) val ()=buf_append_at(c,b,0,n) in c end
fun path_buf(path: string): Buf = let val n=c_strlen(path) var b=buf_make(imax(1,n))
  fun fill{k:nat} .<k>. (left: int(k),b: &Buf >> _,i: int): void =
    if left = 0 then () else let val ()=buf_push(b,c_str_byte(path,i)) in fill(left-1,b,iadd(i,1)) end
  val ()=fill(airlock_nat(n),b,0)
in b end

(* Looks `path` up in one chain: a current entry yields a copy; a stale one is
   removed (its bytes freed) and reported as missing. *)
fun chain_take{n:nat} .<n>. (left: int(n),e: &FileEntries >> _,path: string,now: FileStamp,bytes: &int >> _): Option_vt(Buf) =
  if left = 0 then None_vt() else case+ e of
  | FileEntriesNil() => None_vt()
  | @FileEntriesCons(p,stamp,data,rest) =>
    if not(is_path(p,path)) then let val r=chain_take(left-1,rest,path,now,bytes) prval ()=fold@(e) in r end
    else if file_stamp_equal(stamp,now) then let val r=copy_of(data) prval ()=fold@(e) in Some_vt(r) end
    else let
      val ()=bytes := isub(bytes,buf_len(data)) val tail=rest
      val ()=buf_free(p) val ()=buf_free(data) val ()=free@(e) val ()=e := tail
    in None_vt() end

fun bucket_take{n:nat} .<n>. (left: int(n),b: &FileBuckets >> _,k: int,path: string,now: FileStamp,bytes: &int >> _): Option_vt(Buf) =
  if left = 0 then None_vt() else case+ b of
  | FileBucketsNil() => None_vt()
  | @FileBucketsCons(e,rest) => let
      val r=(if ieq(k,0) then chain_take(airlock_nat(MAX_REC_FUEL),e,path,now,bytes)
        else bucket_take(left-1,rest,isub(k,1),path,now,bytes)): Option_vt(Buf)
      prval ()=fold@(b)
    in r end

fun bucket_put{n:nat} .<n>. (left: int(n),b: &FileBuckets >> _,k: int,entry: FileEntries): void =
  if left = 0 then entries_free(entry) else case+ b of
  | FileBucketsNil() => entries_free(entry)
  | @FileBucketsCons(e,rest) => let
      val ()=(if ieq(k,0) then (case+ entry of
          | ~FileEntriesNil() => ()
          | ~FileEntriesCons(p,stamp,data,none) => let val ()=entries_free(none) in e := FileEntriesCons(p,stamp,data,e) end)
        else bucket_put(left-1,rest,isub(k,1),entry)): void
      prval ()=fold@(b)
    in () end

fun read_disk(path: string,now: FileStamp,limit: int): Option_vt(Buf) =
  if now.length > g0int2int_int_lint(limit) then None_vt() else case+ text_file_read(path) of
  | ~TextFileError(code) => None_vt() | ~TextFile(data) => Some_vt(data)

(* Delayed cleanup: when the budget is passed the whole cache goes at once. *)
fun keep(cache: &FileCache >> _,path: string,now: FileStamp,data: !Buf): void = let
  val+ @FileCache(buckets,bytes)=cache
  val ()=if igt(iadd(bytes,buf_len(data)),SEARCH_FILE_CACHE_BUDGET_BYTES) then let
      val old=buckets val ()=buckets := buckets_make(SEARCH_FILE_CACHE_BUCKETS) val ()=buckets_free(old)
    in bytes := 0 end else ()
  val ()=bucket_put(airlock_nat(SEARCH_FILE_CACHE_BUCKETS),buckets,bucket_of(path),
    FileEntriesCons(path_buf(path),now,copy_of(data),FileEntriesNil()))
  val ()=bytes := iadd(bytes,buf_len(data))
  prval ()=fold@(cache)
in () end

fun cached(cache: &FileCache >> _,path: string,now: FileStamp): Option_vt(Buf) = let
  val+ @FileCache(buckets,bytes)=cache
  val r=bucket_take(airlock_nat(SEARCH_FILE_CACHE_BUCKETS),buckets,bucket_of(path),path,now,bytes)
  prval ()=fold@(cache)
in r end

fun loaded(cache: &FileCache >> _,path: string,now: FileStamp,limit: int): Option_vt(Buf) =
  case+ read_disk(path,now,limit) of
  | ~None_vt() => None_vt()
  | ~Some_vt(data) => let val ()=keep(cache,path,now,data) in Some_vt(data) end

implement search_file_cache_read(cache,path,limit) = case+ file_stamp(path) of
  | ~None_vt() => None_vt()
  | ~Some_vt(now) => (case+ cached(cache,path,now) of
    | ~Some_vt(data) => Some_vt(data)
    | ~None_vt() => loaded(cache,path,now,limit))
