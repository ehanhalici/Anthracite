macdef MAX_EMBED_VIEW_ENTRIES = 128
macdef MAX_EMBED_VIEW_BYTES = 67108864LL
macdef EMBED_VIEW_OBJECT_ALLOWANCE_BYTES = 2048LL
fun view_path_copy(path: !Buf): Buf = let var copy=buf_make(buf_len(path))
  val ()=buffer_append_range(copy,path,0,buf_len(path))
in copy end
fun cache_view_busy{n:nat} .<n>. (fuel: int(n),cache: !Cache,path: !Buf): bool =
  if not(recursion_fuel_available(fuel)) then false else case+ cache of
  | CNil() => false | CCons(p,t,w,h,rest) => cache_view_busy(fuel-1,rest,path)
  | CEmbed(p,s,d,w,h,rest) => cache_view_busy(fuel-1,rest,path)
  | CSelection(s,p,rest) => cache_view_busy(fuel-1,rest,path)
  | CView(p,stamp,state,rest) => let val pending=case+ state of | EmbedViewPending() => true | EmbedViewReady(key,g) => false
    in (pending andalso buffer_equal_from(p,path,0)) orelse cache_view_busy(fuel-1,rest,path) end
fun cache_view_source_active{n:nat} .<n>. (fuel: int(n),cache: !Cache,source: EmbedSourceStamp): bool =
  if not(recursion_fuel_available(fuel)) then false else case+ cache of
  | CNil() => false | CCons(p,t,w,h,rest) => cache_view_source_active(fuel-1,rest,source)
  | CEmbed(p,s,d,w,h,rest) => cache_view_source_active(fuel-1,rest,source)
  | CSelection(s,p,rest) => cache_view_source_active(fuel-1,rest,source)
  | CView(p,stamp,state,rest) => let val pending=case+ state of | EmbedViewPending() => true | EmbedViewReady(key,g) => false
    in (pending andalso embedded_source_equal(stamp,source)) orelse cache_view_source_active(fuel-1,rest,source) end
fun cache_view_begin(cache: &Cache >> _,path: !Buf,stamp: EmbedSourceStamp): void =
  cache := CView(view_path_copy(path),stamp,EmbedViewPending(),cache)
fun cache_view_end{n:nat} .<n>. (fuel: int(n),cache: Cache,path: !Buf): Cache =
  if not(recursion_fuel_available(fuel)) then cache else case+ cache of
  | ~CNil() => CNil()
  | ~CCons(p,t,w,h,rest) => CCons(p,t,w,h,cache_view_end(fuel-1,rest,path))
  | ~CEmbed(p,s,d,w,h,rest) => CEmbed(p,s,d,w,h,cache_view_end(fuel-1,rest,path))
  | ~CSelection(s,p,rest) => CSelection(s,p,cache_view_end(fuel-1,rest,path))
  | ~CView(p,stamp,state,rest) => (case+ state of
    | ~EmbedViewPending() => if buffer_equal_from(p,path,0) then let val ()=buf_free(p) in rest end
      else CView(p,stamp,EmbedViewPending(),cache_view_end(fuel-1,rest,path))
    | ~EmbedViewReady(key,geometry) => CView(p,stamp,EmbedViewReady(key,geometry),cache_view_end(fuel-1,rest,path)))
fun restore_view_texture(path: Buf,texture: uint,width: int,height: int,result: @(Option_vt(DocGeometry),Cache)): @(Option_vt(DocGeometry),Cache) = let
  val (geometry,rest)=result
in @(geometry,CCons(path,texture,width,height,rest)) end
fun restore_view_document(path: Buf,stamp: EmbedSourceStamp,doc: Doc,width: int,height: int,
  result: @(Option_vt(DocGeometry),Cache)): @(Option_vt(DocGeometry),Cache) = let val (geometry,rest)=result
in @(geometry,CEmbed(path,stamp,doc,width,height,rest)) end
fun restore_view_selection(selection: EmbeddedSelection,path: Buf,result: @(Option_vt(DocGeometry),Cache)): @(Option_vt(DocGeometry),Cache) = let
  val (geometry,rest)=result
in @(geometry,CSelection(selection,path,rest)) end
fun restore_view_state(path: Buf,stamp: EmbedSourceStamp,state: EmbedViewState,
  result: @(Option_vt(DocGeometry),Cache)): @(Option_vt(DocGeometry),Cache) = let val (geometry,rest)=result
in @(geometry,CView(path,stamp,state,rest)) end
fun cache_view_take{n:nat} .<n,1>. (fuel: int(n),cache: Cache,path: !Buf,stamp: EmbedSourceStamp,key: VisualKey): @(Option_vt(DocGeometry),Cache) =
  if not(recursion_fuel_available(fuel)) then @(None_vt(),cache) else case+ cache of
  | ~CNil() => @(None_vt(),CNil())
  | ~CCons(p,t,w,h,rest) => restore_view_texture(p,t,w,h,cache_view_take(fuel-1,rest,path,stamp,key))
  | ~CEmbed(p,s,d,w,h,rest) => restore_view_document(p,s,d,w,h,cache_view_take(fuel-1,rest,path,stamp,key))
  | ~CSelection(s,p,rest) => restore_view_selection(s,p,cache_view_take(fuel-1,rest,path,stamp,key))
  | ~CView(p,s,state,rest) => cache_view_take_entry(fuel,p,s,state,rest,path,stamp,key)
and cache_view_take_entry{n:pos} .<n,0>. (fuel: int(n),saved: Buf,old_stamp: EmbedSourceStamp,state: EmbedViewState,
  rest: Cache,path: !Buf,stamp: EmbedSourceStamp,key: VisualKey): @(Option_vt(DocGeometry),Cache) = case+ state of
  | ~EmbedViewPending() => restore_view_state(saved,old_stamp,EmbedViewPending(),cache_view_take(fuel-1,rest,path,stamp,key))
  | ~EmbedViewReady(old_key,geometry) =>
    if buffer_equal_from(saved,path,0) andalso embedded_source_equal(old_stamp,stamp) andalso visual_key_context_matches(old_key,key)
    then let val ()=buf_free(saved) in @(Some_vt(geometry),rest) end
    else restore_view_state(saved,old_stamp,EmbedViewReady(old_key,geometry),cache_view_take(fuel-1,rest,path,stamp,key))
fun cache_view_restore(f: !Font,doc: !Doc,cache: &Cache >> _,path: !Buf,width: int): void = let
  val stamp=embedded_source_stamp(buf_cstr(path)) val key=visual_layout_key(f,doc,width,ViewRead)
  val (geometry,remaining)=cache_view_take(airlock_nat(MAX_REC_FUEL),cache,path,stamp,key)
  val ()=cache := remaining
in case+ geometry of | ~None_vt() => () | ~Some_vt(snapshot) => doc_geometry_put(doc,snapshot) end
fun view_charge(path: !Buf,geometry: !DocGeometry): llint =
  doc_geometry_bytes(geometry)+g0int2int_int_llint(buf_cap(path))+EMBED_VIEW_OBJECT_ALLOWANCE_BYTES
fun view_pin_matches(path: !Buf,stamp: EmbedSourceStamp,key: VisualKey,pinned: !Buf,selection: Option(EmbeddedSelection)): bool =
  case+ selection of | None() => false | Some(info) =>
    buffer_equal_from(path,pinned,0) andalso embedded_source_equal(stamp,info.source) andalso visual_key_context_matches(key,info.view)
fun view_pin_charge{n:nat} .<n>. (fuel: int(n),cache: !Cache,pinned: !Buf,selection: Option(EmbeddedSelection)): llint =
  if not(recursion_fuel_available(fuel)) then 0LL else case+ cache of
  | CNil() => 0LL | CCons(p,t,w,h,rest) => view_pin_charge(fuel-1,rest,pinned,selection)
  | CEmbed(p,s,d,w,h,rest) => view_pin_charge(fuel-1,rest,pinned,selection)
  | CSelection(s,p,rest) => view_pin_charge(fuel-1,rest,pinned,selection)
  | CView(p,s,state,rest) => let
    val charge: llint=case+ state of | EmbedViewPending() => 0LL
      | EmbedViewReady(key,geometry) => if view_pin_matches(p,s,key,pinned,selection) then view_charge(p,geometry) else 0LL
    in if g0int_gt_llint(charge,0LL) andalso g0int_lte_llint(charge,MAX_EMBED_VIEW_BYTES) then charge else view_pin_charge(fuel-1,rest,pinned,selection) end
fun cache_view_trim{n:nat} .<n,1>. (fuel: int(n),cache: Cache,count: &int >> _,bytes: &llint >> _,
  pinned: !Buf,selection: Option(EmbeddedSelection),reserved: &bool >> _): Cache =
  if not(recursion_fuel_available(fuel)) then cache else case+ cache of
  | ~CNil() => CNil()
  | ~CCons(p,t,w,h,rest) => CCons(p,t,w,h,cache_view_trim(fuel-1,rest,count,bytes,pinned,selection,reserved))
  | ~CEmbed(p,s,d,w,h,rest) => CEmbed(p,s,d,w,h,cache_view_trim(fuel-1,rest,count,bytes,pinned,selection,reserved))
  | ~CSelection(s,p,rest) => CSelection(s,p,cache_view_trim(fuel-1,rest,count,bytes,pinned,selection,reserved))
  | ~CView(p,s,state,rest) => cache_view_trim_entry(fuel,p,s,state,rest,count,bytes,pinned,selection,reserved)
and cache_view_trim_entry{n:pos} .<n,0>. (fuel: int(n),path: Buf,stamp: EmbedSourceStamp,state: EmbedViewState,
  rest: Cache,count: &int >> _,bytes: &llint >> _,pinned: !Buf,selection: Option(EmbeddedSelection),reserved: &bool >> _): Cache = case+ state of
  | ~EmbedViewPending() => CView(path,stamp,EmbedViewPending(),cache_view_trim(fuel-1,rest,count,bytes,pinned,selection,reserved))
  | ~EmbedViewReady(key,geometry) => let
    val charge=view_charge(path,geometry)
    val selected=reserved andalso view_pin_matches(path,stamp,key,pinned,selection)
    val retain=selected orelse (ilt(count,MAX_EMBED_VIEW_ENTRIES) andalso bytes+charge <= MAX_EMBED_VIEW_BYTES)
  in if retain then let
      val ()=if selected then reserved := false else (count := iadd(count,1); bytes := bytes+charge)
      in CView(path,stamp,EmbedViewReady(key,geometry),cache_view_trim(fuel-1,rest,count,bytes,pinned,selection,reserved)) end
    else let val ()=buf_free(path) val ()=doc_geometry_dispose(geometry)
      in cache_view_trim(fuel-1,rest,count,bytes,pinned,selection,reserved) end end
fun cache_trim_views(cache: &Cache >> _): void = let
  var pinned: Buf=buf_make(0) val ()=cache_pin_path(cache,pinned) val selection=cache_pin_info(cache)
  val reserve: llint=if igt(buf_len(pinned),0) then view_pin_charge(airlock_nat(MAX_REC_FUEL),cache,pinned,selection) else 0LL
  var bytes: llint=reserve var reserved: bool=g0int_gt_llint(reserve,0LL) var count: int=if reserved then 1 else 0
  val ()=cache := cache_view_trim(airlock_nat(MAX_REC_FUEL),cache,count,bytes,pinned,selection,reserved)
in buf_free(pinned) end
fun cache_view_store(cache: &Cache >> _,path: !Buf,stamp: EmbedSourceStamp,doc: !Doc): void = let
  val geometry=doc_geometry_take(doc)
  val key=doc_geometry_key(geometry)
in case+ key of | None() => doc_geometry_put(doc,geometry)
  | Some(context) => let
      val ()=cache := CView(view_path_copy(path),stamp,EmbedViewReady(context,geometry),cache)
    in cache_trim_views(cache) end end
fun view_stats_add(state: !EmbedViewState,path: !Buf,stats: EmbedCacheStats): EmbedCacheStats = case+ state of
  | EmbedViewPending() => @{documents=stats.documents,views=stats.views,pending=iadd(stats.pending,1),viewBytes=stats.viewBytes}
  | EmbedViewReady(key,geometry) =>
    @{documents=stats.documents,views=iadd(stats.views,1),pending=stats.pending,
      viewBytes=stats.viewBytes+doc_geometry_bytes(geometry)+g0int2int_int_llint(buf_cap(path))+EMBED_VIEW_OBJECT_ALLOWANCE_BYTES}
fun view_cache_stats{n:nat} .<n>. (fuel: int(n),cache: !Cache,stats: EmbedCacheStats): EmbedCacheStats =
  if not(recursion_fuel_available(fuel)) then stats else case+ cache of
  | CNil() => stats | CCons(p,t,w,h,rest) => view_cache_stats(fuel-1,rest,stats)
  | CSelection(s,p,rest) => view_cache_stats(fuel-1,rest,stats)
  | CEmbed(p,s,d,w,h,rest) => let var updated: EmbedCacheStats=stats val ()=updated.documents := iadd(updated.documents,1)
    in view_cache_stats(fuel-1,rest,updated) end
  | CView(p,s,state,rest) => view_cache_stats(fuel-1,rest,view_stats_add(state,p,stats))
implement cache_embed_stats(cache) = view_cache_stats(airlock_nat(MAX_REC_FUEL),cache,@{documents=0,views=0,pending=0,viewBytes=0LL})
