macdef EMBED_BACKGROUND_BUDGET_NS = 4000000L
macdef EMBED_ESTIMATED_LINES = 4
macdef EMBED_FRAME_PADDING_PIXELS = 8
fun work_scope_empty(): EmbedWorkScope =
  @{active=false,document=the_null_ptr,anchorLine= ~1,scroll=0,height=0,
    foreground=true,childDelta=0,band=EmbedWorkVisible()}
extern fun work_pins_exhausted(pins: EmbedPins): void = "mac#anth_die_void"
fun work_pins_free{n:nat} .<n>. (fuel: int(n),pins: EmbedPins): void =
  if not(recursion_fuel_available(fuel)) then work_pins_exhausted(pins) else
  case+ pins of | ~EmbedPinsNil() => () | ~EmbedPinsCons(path,stamp,key,rest) =>
    let val ()=buf_free(path) in work_pins_free(fuel-1,rest) end
fun work_remove{n:nat} .<n>. (fuel: int(n),cache: Cache): Cache =
  if not(recursion_fuel_available(fuel)) then cache else case+ cache of
  | ~CNil() => CNil()
  | ~CWork(state,pins,rest) => let val ()=work_pins_free(airlock_nat(MAX_REC_FUEL),pins)
    in work_remove(fuel-1,rest) end
  | ~CCons(p,t,w,h,rest) => CCons(p,t,w,h,work_remove(fuel-1,rest))
  | ~CEmbed(p,s,d,w,h,rest) => CEmbed(p,s,d,w,h,work_remove(fuel-1,rest))
  | ~CSelection(s,p,rest) => CSelection(s,p,work_remove(fuel-1,rest))
  | ~CView(p,s,state,rest) => CView(p,s,state,work_remove(fuel-1,rest))
implement cache_work_begin(cache) = let
  val rest=work_remove(airlock_nat(MAX_REC_FUEL),cache)
  val state: EmbedWorkState= @{enabled=true,deadline=0L,pending=false,scope=work_scope_empty()}
in cache := CWork(state,EmbedPinsNil(),rest) end
fun work_state{n:nat} .<n>. (fuel: int(n),cache: !Cache): EmbedWorkState =
  if not(recursion_fuel_available(fuel)) then @{enabled=false,deadline=0L,pending=false,scope=work_scope_empty()} else case+ cache of
  | CNil() => @{enabled=false,deadline=0L,pending=false,scope=work_scope_empty()}
  | CWork(state,pins,rest) => state
  | CCons(p,t,w,h,rest) => work_state(fuel-1,rest)
  | CEmbed(p,s,d,w,h,rest) => work_state(fuel-1,rest)
  | CSelection(s,p,rest) => work_state(fuel-1,rest)
  | CView(p,s,state,rest) => work_state(fuel-1,rest)
fun work_update{n:nat} .<n>. (fuel: int(n),cache: !Cache,state: EmbedWorkState): void =
  if not(recursion_fuel_available(fuel)) then () else case+ cache of
  | CNil() => ()
  | @CWork(old,pins,rest) => (old := state; fold@(cache))
  | CCons(p,t,w,h,rest) => work_update(fuel-1,rest,state)
  | CEmbed(p,s,d,w,h,rest) => work_update(fuel-1,rest,state)
  | CSelection(s,p,rest) => work_update(fuel-1,rest,state)
  | CView(p,s,view,rest) => work_update(fuel-1,rest,state)
fun work_scope(cache: !Cache): EmbedWorkScope = let val state=work_state(airlock_nat(MAX_REC_FUEL),cache) in state.scope end
fun work_set_scope(cache: !Cache,scope: EmbedWorkScope): void = let
  var state: EmbedWorkState=work_state(airlock_nat(MAX_REC_FUEL),cache)
  val ()=state.scope := scope
in work_update(airlock_nat(MAX_REC_FUEL),cache,state) end
implement cache_work_pending(cache) = let val state=work_state(airlock_nat(MAX_REC_FUEL),cache) in state.pending end
fun work_allow(cache: !Cache): bool = let
  var state: EmbedWorkState=work_state(airlock_nat(MAX_REC_FUEL),cache)
in if not(state.scope.active) orelse state.scope.foreground then true else let
    val now=mono_ns()
    val ()=if state.deadline = 0L then state.deadline := now+EMBED_BACKGROUND_BUDGET_NS else ()
    val allowed: bool=now < state.deadline
    val ()=if allowed then () else state.pending := true
    val ()=work_update(airlock_nat(MAX_REC_FUEL),cache,state)
  in allowed end end
fun work_top(d: !Doc,scope: EmbedWorkScope): int =
  iadd(if ilt(scope.anchorLine,0) then 0 else doc_line_y(d,scope.anchorLine),scope.scroll)
fun work_visible(d: !Doc,node: int,scope: EmbedWorkScope): bool = let
  val top=work_top(d,scope) val y=doc_node_y(d,node)
in ilt(y,iadd(top,scope.height)) andalso igt(iadd(y,doc_node_height(d,node)),top) end
fun work_in_band(d: !Doc,node: int,cache: !Cache): bool = let val scope=work_scope(cache)
in if not(scope.active) orelse scope.document <> doc_identity(d) then true else let
    val top=work_top(d,scope) val y=doc_node_y(d,node)
    val visible=work_visible(d,node,scope)
  in case+ scope.band of | EmbedWorkVisible() => visible
    | EmbedWorkOverscan() => not(visible) andalso ilt(y,iadd(top,imul(scope.height,2)))
      andalso igt(iadd(y,doc_node_height(d,node)),isub(top,scope.height)) end end
fun work_focus(d: !Doc,node: int,cache: !Cache): void = let
  var scope: EmbedWorkScope=work_scope(cache)
  val foreground=scope.foreground andalso work_visible(d,node,scope)
  val delta=isub(work_top(d,scope),doc_node_y(d,node))
  val ()=scope.foreground := foreground
  val ()=scope.childDelta := delta
in work_set_scope(cache,scope) end
fun work_has_document{n:nat} .<n>. (fuel: int(n),cache: !Cache,path: !Buf,stamp: EmbedSourceStamp): bool =
  if not(recursion_fuel_available(fuel)) then false else case+ cache of
  | CNil() => false
  | CWork(state,pins,rest) => work_has_document(fuel-1,rest,path,stamp)
  | CCons(p,t,w,h,rest) => work_has_document(fuel-1,rest,path,stamp)
  | CSelection(s,p,rest) => work_has_document(fuel-1,rest,path,stamp)
  | CView(p,s,state,rest) => work_has_document(fuel-1,rest,path,stamp)
  | CEmbed(p,s,d,w,h,rest) => (buffer_equal_from(p,path,0) andalso embedded_source_equal(s,stamp))
    orelse work_has_document(fuel-1,rest,path,stamp)
fun work_pin_exists{n:nat} .<n>. (fuel: int(n),pins: !EmbedPins,path: !Buf,stamp: EmbedSourceStamp,key: VisualKey): bool =
  if not(recursion_fuel_available(fuel)) then false else case+ pins of
  | EmbedPinsNil() => false | EmbedPinsCons(p,s,k,rest) =>
    (buffer_equal_from(p,path,0) andalso embedded_source_equal(s,stamp) andalso visual_key_context_matches(k,key))
    orelse work_pin_exists(fuel-1,rest,path,stamp,key)
fun work_pin_add{n:nat} .<n>. (fuel: int(n),cache: !Cache,path: !Buf,stamp: EmbedSourceStamp,key: VisualKey): void =
  if not(recursion_fuel_available(fuel)) then () else case+ cache of
  | CNil() => ()
  | @CWork(state,pins,rest) => let
      val ()=if state.scope.active andalso state.scope.foreground andalso not(work_pin_exists(airlock_nat(MAX_REC_FUEL),pins,path,stamp,key)) then let
        var copy: Buf=buf_make(buf_len(path)) val ()=buffer_append_range(copy,path,0,buf_len(path))
      in pins := EmbedPinsCons(copy,stamp,key,pins) end else ()
    in fold@(cache) end
  | CCons(p,t,w,h,rest) => work_pin_add(fuel-1,rest,path,stamp,key)
  | CEmbed(p,s,d,w,h,rest) => work_pin_add(fuel-1,rest,path,stamp,key)
  | CSelection(s,p,rest) => work_pin_add(fuel-1,rest,path,stamp,key)
  | CView(p,s,state,rest) => work_pin_add(fuel-1,rest,path,stamp,key)
extern fun work_clone_pins(cache: !Cache): EmbedPins
extern fun work_promote_documents(cache: &Cache >> _): void
fun work_paint_scope(cache: !Cache,delta: int,height: int): EmbedWorkScope = let
  val previous=work_scope(cache)
  var scope: EmbedWorkScope=previous
  val ()=scope.childDelta := delta
  val ()=scope.height := height
  val ()=scope.foreground := true
  val ()=work_set_scope(cache,scope)
in previous end
