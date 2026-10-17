fun prepare_embed_hit_view(f: !Font,r: !Rend,child: !Doc,path: !Buf,anchor: !Buf,scope: EmbedScope,
  box: EmbedHitBox,vault: !Buf,cache: &Cache >> _): int = let
  val target=embedded_target(child,scope,anchor)
  val ()=doc_set_view_range(child,target.start,target.finish)
  val restored: bool=if font_text_active(f) then cache_view_restore(f,child,cache,path,embed_text_width(f,r,box.width)) else false
in if restored then doc_layout_cache_height(child)
  else prepare_embedded_view(f,child,cache,r,vault,path,box.lh,embed_text_width(f,r,box.width),scope,anchor) end
fun inline_link_node{n:nat} .<n>. (left: int(n),doc: !Doc,offset: int,index: int,best: int): int =
  if left = 0 then best else let
    val kind=doc_node_kind(doc,index)
    val inside=ile(doc_node_start(doc,index),offset) andalso ilt(offset,doc_node_end(doc,index))
    val link=is_kind(kind,KWiki) orelse is_kind(kind,KLink)
    val smaller=ilt(best,0) orelse ile(isub(doc_node_end(doc,index),doc_node_start(doc,index)),isub(doc_node_end(doc,best),doc_node_start(doc,best)))
    val next=if inside andalso link andalso smaller then index else best
  in inline_link_node(left-1,doc,offset,iadd(index,1),next) end
fun link_hit_none(): EmbedLinkHit = @{child=the_null_ptr,version=0,node= ~1,
  source= @{file= @{exists=false,seconds=0L,nanoseconds=0,length=0L,device=0ULL,inode=0ULL},shadow=false}}
fun link_hit_record(doc: !Doc,path: !Buf,node: int): EmbedLinkHit =
  if ilt(node,0) then link_hit_none() else @{child=doc_identity(doc),version=doc_parse_generation(doc),node=node,source=embedded_source_stamp(buf_cstr(path))}
fun prefer_nested_link(hit: EmbedLinkHit,doc: !Doc,path: !Buf,node: int): EmbedLinkHit =
  if ige(hit.node,0) then hit else link_hit_record(doc,path,node)
fun embed_link_hit{n:nat} .<n,1>. (fuel: int(n),f: !Font,r: !Rend,doc: !Doc,path: !Buf,target: AnchorTarget,
  box: EmbedHitBox,x: int,y: int,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _): EmbedLinkHit =
  if not(recursion_fuel_available(fuel)) then link_hit_none() else if not(target.found) then link_hit_none() else let
    val scroll=doc_line_y(doc,doc_line_of(doc,target.start))
    val height=embedded_target_height(doc,target,box.lh)
    val inside=ige(x,box.x) andalso ilt(x,iadd(box.x,box.width)) andalso ige(y,box.y) andalso ilt(y,iadd(box.y,height))
    val node=if inside then node_covering(doc,y,box.y,scroll,0,~1) else ~1
  in if not(inside) then link_hit_none() else if ige(node,0) andalso is_kind(doc_node_kind(doc,node),KEmbed) then
      embed_link_descend(fuel,f,r,doc,path,node,box,x,y,scroll,vault,cache,scratch)
    else let
      val offset=visual_click_source(f,doc,x,y,editor_colx(f,r,box.x,box.width),box.y,scroll,box.lh,scratch)
    in link_hit_record(doc,path,inline_link_node(airlock_nat(doc_nnodes(doc)),doc,offset,0,~1)) end end
and embed_link_descend{n:pos} .<n,0>. (fuel: int(n),f: !Font,r: !Rend,parent: !Doc,parent_path: !Buf,node: int,
  box: EmbedHitBox,x: int,y: int,scroll: int,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _): EmbedLinkHit = let
  val (path,relative,full,anchor)=resolve_embed_paths(parent,node,vault)
  val stamp=embedded_source_stamp(buf_cstr(path)) val level=iadd(doc_embed_level(parent),1)
  var nested: EmbedLinkHit=link_hit_none()
  val ()=if not(stamp.file.exists) orelse igt(level,MAX_EMBED_DEPTH) then () else let
    val (child,loaded)=obtain_embed_doc(cache,path,buf_cstr(path),stamp,level)
    val ()=if loaded then nested := embed_link_child(fuel-1,f,r,parent,node,child,path,anchor,box,x,y,scroll,vault,cache,scratch) else ()
    val ()=if loaded then save_embed_cache(cache,path,stamp,child,box.width,box.lh) else doc_free(child)
  in () end
  val ()=release_embed_paths(path,relative,full,anchor)
in prefer_nested_link(nested,parent,parent_path,node) end
and embed_link_child{n:nat} .<n,2>. (fuel: int(n),f: !Font,r: !Rend,parent: !Doc,node: int,child: !Doc,path: !Buf,anchor: !Buf,
  box: EmbedHitBox,x: int,y: int,scroll: int,vault: !Buf,cache: &Cache >> _,scratch: &Buf >> _): EmbedLinkHit = let
  val depth=doc_node_depth(parent,node)
  val nested: EmbedHitBox= @{x=iadd(editor_colx(f,r,box.x,box.width),imul(depth,20)),
    y=isub(iadd(box.y,doc_node_y(parent,node)),scroll),width=imax(1,isub(doc_visual_width(parent),imul(depth,20))),scroll=scroll,lh=box.lh}
  val height=prepare_embed_hit_view(f,r,child,path,anchor,embed_scope(parent,node),nested,vault,cache)
  val target=embedded_target(child,embed_scope(parent,node),anchor)
in embed_link_hit(fuel,f,r,child,path,target,nested,x,y,vault,cache,scratch) end
fun link_prefix_bytes{n:nat} .<n>. (left: int(n),path: !Buf,token: string,index: int): bool =
  if left = 0 then true else ieq(buf_get(path,index),c_str_byte(token,index)) andalso link_prefix_bytes(left-1,path,token,iadd(index,1))
fun link_path_prefix(path: !Buf,token: string): bool = let val length=c_strlen(token)
in ige(buf_len(path),length) andalso link_prefix_bytes(airlock_nat(length),path,token,0) end
fun embed_external_path(path: !Buf): bool =
  link_path_prefix(path,"http://") orelse link_path_prefix(path,"https://")
  orelse link_path_prefix(path,"mailto:") orelse link_path_prefix(path,"ftp://")
fun embed_link_target(doc: !Doc,current: !Buf,node: int,vault: !Buf,path: &Buf >> _,anchor: &Buf >> _): EmbedNavigationKind = let
  var relative: Buf=buf_make(0) val ()=take_path(doc,node,relative)
  val ()=buffer_clear(path) val ()=buffer_clear(anchor) val ()=take_anchor(doc,node,anchor)
  val external=embed_external_path(relative)
  val length=buf_len(relative)
  val ()=if external then buffer_append_range(path,relative,0,length)
    else if ieq(length,0) then buffer_append_range(path,current,0,buf_len(current))
    else let var full: Buf=buf_make(0) val ()=resolve_path(vault,relative,full)
      val ()=with_md(full,path) in buf_free(full) end
  val ()=buf_free(relative)
in if external then EmbedNavigationExternal() else EmbedNavigationFile() end
fun embed_link_resolve{n:nat} .<n>. (fuel: int(n),cache: !Cache,hit: EmbedLinkHit,vault: !Buf,path: &Buf >> _,anchor: &Buf >> _): EmbedNavigationKind =
  if not(recursion_fuel_available(fuel)) then EmbedNavigationNone() else case+ cache of
  | CNil() => EmbedNavigationNone()
  | CWork(s,pins,rest) => embed_link_resolve(fuel-1,rest,hit,vault,path,anchor)
  | CSelection(s,p,rest) => embed_link_resolve(fuel-1,rest,hit,vault,path,anchor)
  | CCons(p,t,w,h,rest) => embed_link_resolve(fuel-1,rest,hit,vault,path,anchor)
  | CView(p,s,state,rest) => embed_link_resolve(fuel-1,rest,hit,vault,path,anchor)
  | CEmbed(p,s,d,w,h,rest) =>
    if doc_identity(d) <> hit.child then embed_link_resolve(fuel-1,rest,hit,vault,path,anchor)
    else if ine(doc_parse_generation(d),hit.version) orelse not(embedded_source_equal(s,hit.source))
      orelse not(embedded_source_equal(s,embedded_source_stamp(buf_cstr(p)))) then EmbedNavigationNone()
    else embed_link_target(d,p,hit.node,vault,path,anchor)
