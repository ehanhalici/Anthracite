fun obtain_embed_doc(c: &Cache >> _,shown: !Buf,path: string,mtime: int,level: int): @(Doc,bool) = let
  val (cached,remaining)=cache_take_embed(c,shown,mtime)
  val ()=c := remaining
in case+ cached of
  | ~Some_vt(child) => let val ()=performance_note(PERF_EMBED_HITS,1)
      val ()=doc_set_embed_level(child,level)
    in @(child,true) end
  | ~None_vt() => let val ()=performance_note(PERF_EMBED_MISSES,1)
      val child=doc_open() val loaded=embedded_doc_load(child,path,level)
    in @(child,loaded) end
end
fun save_embed_cache(c: &Cache >> _,shown: !Buf,mtime: int,child: Doc,width: int,height: int): void = let
  var path=buf_make(buf_len(shown))
  val ()=buffer_append_range(path,shown,0,buf_len(shown))
in c := cache_put_embed(c,path,mtime,child,width,height) end
