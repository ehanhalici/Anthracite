fun selection_info{n:nat} .<n>. (fuel: int(n),cache: !Cache): Option(EmbeddedSelection) =
  if not(recursion_fuel_available(fuel)) then None() else case+ cache of
  | CNil() => None() | CSelection(info,path,rest) => Some(info)
  | CCons(path,tex,w,h,rest) => selection_info(fuel-1,rest)
  | CEmbed(path,stamp,doc,w,h,rest) => selection_info(fuel-1,rest)
implement cache_embed_selection_active(cache) = case+ selection_info(airlock_nat(MAX_REC_FUEL),cache) of
  | None() => false | Some(info) => true
implement cache_embed_selection_dragged(cache) = case+ selection_info(airlock_nat(MAX_REC_FUEL),cache) of
  | None() => false | Some(info) => info.dragged
fun selection_remove{n:nat} .<n>. (fuel: int(n),cache: Cache): Cache =
  if not(recursion_fuel_available(fuel)) then cache else case+ cache of
  | ~CNil() => CNil()
  | ~CSelection(info,path,rest) => let val ()=buf_free(path) in selection_remove(fuel-1,rest) end
  | ~CCons(path,tex,w,h,rest) => CCons(path,tex,w,h,selection_remove(fuel-1,rest))
  | ~CEmbed(path,stamp,doc,w,h,rest) => CEmbed(path,stamp,doc,w,h,selection_remove(fuel-1,rest))
implement cache_clear_embed_selection(cache) = cache := selection_remove(airlock_nat(MAX_REC_FUEL),cache)
fun selection_same(a: EmbeddedSelection,b: EmbeddedSelection): bool =
  a.parent = b.parent andalso ieq(a.parentVersion,b.parentVersion) andalso ieq(a.node,b.node)
  andalso a.child = b.child andalso ieq(a.childVersion,b.childVersion)
fun selection_install(cache: &Cache >> _,info: EmbeddedSelection,path: !Buf,extend: bool): bool = let
  val old=selection_info(airlock_nat(MAX_REC_FUEL),cache)
  val allowed: bool=case+ old of | None() => not(extend) | Some(previous) => not(extend) orelse selection_same(previous,info)
in if allowed then let
    var updated: EmbeddedSelection=info
    val anchor: int=case+ old of | None() => info.anchor | Some(previous) => if extend then previous.anchor else info.anchor
    val ()=updated.anchor := anchor
    val ()=updated.dragged := extend
    var copy: Buf=buf_make(buf_len(path)) val ()=buffer_append_range(copy,path,0,buf_len(path))
    val ()=cache_clear_embed_selection(cache) val ()=cache := CSelection(updated,copy,cache)
  in true end else false end
fun selection_node(cache: !Cache,parent: !Doc,fallback: int,extend: bool): int =
  if not(extend) then fallback else case+ selection_info(airlock_nat(MAX_REC_FUEL),cache) of
  | None() => ~1 | Some(info) => if info.parent = doc_identity(parent) andalso ieq(info.parentVersion,doc_ver(parent)) then info.node else ~1
typedef EmbedHitBox = @{x=int,y=int,width=int,scroll=int,lh=int}
fun select_child(f: !Font,r: !Rend,parent: !Doc,node: int,child: !Doc,anchor: !Buf,path: !Buf,
  box: EmbedHitBox,x: int,y: int,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,extend: bool): bool = let
  val height=prepare_document_layout(f,child,cache,r,vault,box.lh,embed_text_width(f,r,box.width),ViewRead)
  val target=embedded_target(child,embed_scope(parent,node),anchor)
  val scroll=doc_line_y(child,doc_line_of(child,target.start))
  val content_h=embedded_target_height(child,target,box.lh)
  val hit_y=imin(isub(iadd(box.y,content_h),1),imax(box.y,y))
  val raw=visual_click_source(f,child,x,hit_y,editor_colx(f,r,box.x,box.width),box.y,scroll,box.lh,scratch)
  val offset=imin(target.finish,imax(target.start,raw))
  val info: EmbeddedSelection= @{parent=doc_identity(parent),parentVersion=doc_ver(parent),node=node,
    child=doc_identity(child),childVersion=doc_ver(child),anchor=offset,caret=offset,start=target.start,finish=target.finish,dragged=false}
in if target.found then selection_install(cache,info,path,extend) else false end
fun select_path(f: !Font,r: !Rend,parent: !Doc,node: int,anchor: !Buf,path: !Buf,box: EmbedHitBox,
  x: int,y: int,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,extend: bool): bool = let
  val stamp=embedded_source_stamp(buf_cstr(path)) val level=iadd(doc_embed_level(parent),1)
in if not(stamp.file.exists) orelse igt(level,MAX_EMBED_DEPTH) then false else let
    val (child,loaded)=obtain_embed_doc(cache,path,buf_cstr(path),stamp,level)
    val selected=if loaded then select_child(f,r,parent,node,child,anchor,path,box,x,y,vault,cache,scratch,extend) else false
    val ()=if loaded then save_embed_cache(cache,path,stamp,child,box.width,box.lh) else doc_free(child)
  in selected end end
fun select_document(f: !Font,r: !Rend,parent: !Doc,x: int,y: int,ox: int,width: int,scroll: int,lh: int,
  vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,extend: bool): bool = let
  val hit=node_covering(parent,y,UI_TOPBAR_HEIGHT,scroll,0,~1)
  val node=selection_node(cache,parent,hit,extend)
in if ilt(node,0) orelse not(is_kind(doc_node_kind(parent,node),KEmbed)) then false else let
    val depth=doc_node_depth(parent,node)
    val box: EmbedHitBox= @{x=iadd(editor_colx(f,r,ox,width),imul(depth,20)),
      y=isub(iadd(UI_TOPBAR_HEIGHT,doc_node_y(parent,node)),scroll),
      width=imax(1,isub(doc_visual_width(parent),imul(depth,20))),scroll=scroll,lh=lh}
    val (shown,relative,full,anchor)=resolve_embed_paths(parent,node,vault)
    val selected=select_path(f,r,parent,node,anchor,shown,box,x,y,vault,cache,scratch,extend)
    val ()=release_embed_paths(shown,relative,full,anchor)
  in selected end end
fun select_tab{n:nat} .<n>. (fuel: int(n),f: !Font,r: !Rend,tabs: !Tabs,index: int,x: int,y: int,ox: int,width: int,
  lh: int,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _,extend: bool): bool =
  if not(recursion_fuel_available(fuel)) then false else case+ tabs of
  | TNil() => false | TCons(doc,path,title,scroll,rest) =>
    if ieq(index,0) then select_document(f,r,doc,x,y,ox,width,scroll,lh,vault,cache,scratch,extend)
    else select_tab(fuel-1,f,r,rest,isub(index,1),x,y,ox,width,lh,vault,cache,scratch,extend)
implement tabs_embed_select(f,r,tabs,index,x,y,ox,width,lh,vault,cache,scratch,extend) =
  select_tab(airlock_nat(MAX_REC_FUEL),f,r,tabs,index,x,y,ox,width,
    if font_text_active(f) then font_document_line_height(f,lh) else lh,vault,cache,scratch,extend)
implement draw_embed_selection(f,r,cache,parent,node,child,colx,oy,scroll,lh,ph,scratch) =
  case+ selection_info(airlock_nat(MAX_REC_FUEL),cache) of | None() => () | Some(info) =>
    if info.parent <> doc_identity(parent) orelse ine(info.parentVersion,doc_ver(parent)) orelse ine(info.node,node)
      orelse info.child <> doc_identity(child) orelse ine(info.childVersion,doc_ver(child)) then ()
    else visual_draw_band(f,r,child,imin(info.anchor,info.caret),imax(info.anchor,info.caret),colx,oy,scroll,lh,ph,0,lh,col_sel(),scratch)
fun copy_projected(child: !Doc,info: EmbeddedSelection,destination: &Buf >> _): bool =
  if info.child <> doc_identity(child) orelse ine(info.childVersion,doc_ver(child)) then false else let
    val state=doc_visual_take(child)
    val copied=case+ state of | None_vt() => false | Some_vt(rows) => let
      val+ VisualRows(text,map,lines,data,n,key,plans)=rows
      val a=visual_rows_offset(rows,imin(info.anchor,info.caret))
      val b=visual_rows_offset(rows,imax(info.anchor,info.caret))
      val ()=buffer_clear(destination) val ()=buffer_append_range(destination,text,a,isub(b,a))
    in ilt(a,b) end
    val ()=doc_visual_put(child,state)
  in copied end
fun copy_document{n:nat} .<n>. (fuel: int(n),cache: !Cache,path: !Buf,info: EmbeddedSelection,destination: &Buf >> _): bool =
  if not(recursion_fuel_available(fuel)) then false else case+ cache of
  | CNil() => false | CSelection(selection,saved,rest) => copy_document(fuel-1,rest,path,info,destination)
  | CCons(saved,tex,w,h,rest) => copy_document(fuel-1,rest,path,info,destination)
  | CEmbed(saved,stamp,doc,w,h,rest) =>
    if buffer_equal_from(path,saved,0) then
      if embedded_source_equal(stamp,embedded_source_stamp(buf_cstr(path))) then copy_projected(doc,info,destination) else false
    else copy_document(fuel-1,rest,path,info,destination)
fun selection_path{n:nat} .<n>. (fuel: int(n),cache: !Cache,destination: &Buf >> _): Option(EmbeddedSelection) =
  if not(recursion_fuel_available(fuel)) then None() else case+ cache of
  | CNil() => None() | CSelection(info,path,rest) => let
      val ()=buffer_append_range(destination,path,0,buf_len(path))
    in Some(info) end
  | CCons(path,tex,w,h,rest) => selection_path(fuel-1,rest,destination)
  | CEmbed(path,stamp,doc,w,h,rest) => selection_path(fuel-1,rest,destination)
implement cache_copy_embed_selection(cache,destination) = let var path: Buf=buf_make(0)
  val selection=selection_path(airlock_nat(MAX_REC_FUEL),cache,path)
  val copied: bool=case+ selection of | None() => false
    | Some(info) => copy_document(airlock_nat(MAX_REC_FUEL),cache,path,info,destination)
  val ()=buf_free(path)
in copied end
implement cache_pin_path(cache,path) = let val selection=selection_path(airlock_nat(MAX_REC_FUEL),cache,path) in () end
