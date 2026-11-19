(* File bytes cached by one worker thread (no sharing, no locks): entries are
   keyed by path and revalidated by file stamp on every read. Buckets are a
   fixed list of SEARCH_FILE_CACHE_BUCKETS chains. Cleanup is delayed: nothing
   is released until the budget is passed, then the whole cache is dropped. *)
staload "mem.sats"
staload "os/file_stamp.sats"
datavtype FileEntries = FileEntriesNil | FileEntriesCons of (Buf,FileStamp,Buf,FileEntries)
datavtype FileBuckets = FileBucketsNil | FileBucketsCons of (FileEntries,FileBuckets)
datavtype FileCache = FileCache of (FileBuckets,int)
fun search_file_cache_make(): FileCache
fun search_file_cache_free(cache: FileCache): void
(* A copy of the file's bytes, or None_vt when it cannot be read or is larger than limit. *)
fun search_file_cache_read(cache: &FileCache >> _,path: string,limit: int): Option_vt(Buf)
