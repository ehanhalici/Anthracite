fun clone_work_pins{n:nat} .<n>. (fuel: int(n),pins: !EmbedPins): EmbedPins =
  if not(recursion_fuel_available(fuel)) then EmbedPinsNil() else case+ pins of
  | EmbedPinsNil() => EmbedPinsNil()
  | EmbedPinsCons(path,stamp,key,rest) => EmbedPinsCons(view_path_copy(path),stamp,key,clone_work_pins(fuel-1,rest))
fun find_work_pins{n:nat} .<n>. (fuel: int(n),cache: !Cache): EmbedPins =
  if not(recursion_fuel_available(fuel)) then EmbedPinsNil() else case+ cache of
  | CNil() => EmbedPinsNil() | CWork(state,pins,rest) => clone_work_pins(airlock_nat(MAX_REC_FUEL),pins)
  | CCons(p,t,w,h,rest) => find_work_pins(fuel-1,rest)
  | CEmbed(p,s,d,w,h,rest) => find_work_pins(fuel-1,rest)
  | CSelection(s,p,rest) => find_work_pins(fuel-1,rest)
  | CView(p,s,state,rest) => find_work_pins(fuel-1,rest)
implement work_clone_pins(cache) = find_work_pins(airlock_nat(MAX_REC_FUEL),cache)
fun promote_visible_view(cache: &Cache >> _,path: !Buf,stamp: EmbedSourceStamp,key: VisualKey): void = let
  val (geometry,rest)=cache_view_take(airlock_nat(MAX_REC_FUEL),cache,path,stamp,key)
  val ()=cache := rest
in case+ geometry of | ~None_vt() => () | ~Some_vt(snapshot) =>
  cache := CView(view_path_copy(path),stamp,EmbedViewReady(key,snapshot),cache) end
fun promote_visible_document(cache: &Cache >> _,path: !Buf,stamp: EmbedSourceStamp): void = let
  val (doc,rest)=cache_take_embed(cache,path,stamp)
  val ()=cache := rest
in case+ doc of | ~None_vt() => () | ~Some_vt(child) =>
  cache := CEmbed(view_path_copy(path),stamp,child,0,0,cache) end
fun promote_pins{n:nat} .<n>. (fuel: int(n),cache: &Cache >> _,pins: EmbedPins,views: bool): void =
  if not(recursion_fuel_available(fuel)) then work_pins_free(airlock_nat(MAX_REC_FUEL),pins) else case+ pins of
  | ~EmbedPinsNil() => () | ~EmbedPinsCons(path,stamp,key,rest) => let
      val fresh=embedded_source_equal(stamp,embedded_source_stamp(buf_cstr(path)))
      val ()=if not(fresh) then () else if views then promote_visible_view(cache,path,stamp,key) else promote_visible_document(cache,path,stamp)
      val ()=buf_free(path)
    in promote_pins(fuel-1,cache,rest,views) end
implement work_promote_views(cache) = let val pins=work_clone_pins(cache)
in promote_pins(airlock_nat(MAX_REC_FUEL),cache,pins,true) end
implement work_promote_documents(cache) = let val pins=work_clone_pins(cache)
in promote_pins(airlock_nat(MAX_REC_FUEL),cache,pins,false) end
