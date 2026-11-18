(* Per-worker state, created and used only on its worker thread: a Font opened
   from the main Font's face files (line shaping) and the compiled pattern of
   the last query (search) with that query's bytes, and its file cache. *)
staload "mem.sats"
staload "data_font/resources/font.sats"
staload "search/literal/literal_search.sats"
staload "search/results/search_file_cache.sats"
datavtype WorkerContext = WorkerContext of (Option_vt(Font),int,Option_vt(LiteralPattern),Buf,FileCache)
