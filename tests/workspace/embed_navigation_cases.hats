fun nested_link_x(f: !Font,r: !Rend,tabs: !Tabs): int = case+ tabs of
  | TNil() => 0 | TCons(d,p,t,s,rest) => let
      val box_width=doc_visual_width(d)
      val text_width=imax(1,isub(box_width,iadd(editor_colx(f,r,0,box_width),16)))
    in editor_colx(f,r,selection_x(f,r,tabs),text_width) end
fun navigation_kind_matches(kind: EmbedNavigationKind,external: bool): bool = case+ kind of
  | EmbedNavigationNone() => false | EmbedNavigationFile() => not(external) | EmbedNavigationExternal() => external
fun nested_link_check(f: !Font,r: !Rend,tabs: !Tabs,root: !Buf,cache: &Cache >> _,scratch: &Buf >> _,
  expected: !Buf,anchor_text: string,external: bool): bool = let
  val ()=selection_parent_draw(f,r,tabs,root,cache,scratch)
  val x=iadd(nested_link_x(f,r,tabs),1) val y=iadd(selection_top(tabs,0),1)
  val selected=tabs_embed_select(f,r,tabs,0,x,y,0,640,font_line_h(f),root,cache,scratch,false)
  var path: Buf=buf_make(0) var anchor: Buf=buf_make(0)
  val kind=cache_embed_navigation(cache,root,path,anchor)
  val length=c_strlen(anchor_text)
  val matched=buffer_equal_from(path,expected,0) andalso ieq(buf_len(anchor),length) andalso equal(airlock_nat(length),anchor,anchor_text,0)
  val extended=tabs_embed_select(f,r,tabs,0,iadd(x,12),y,0,640,font_line_h(f),root,cache,scratch,true)
  val dragged=case+ cache_embed_navigation(cache,root,path,anchor) of | EmbedNavigationNone() => true | _ => false
  val ()=buf_free(path) val ()=buf_free(anchor) val ()=cache_clear_embed_selection(cache)
in selected andalso navigation_kind_matches(kind,external) andalso matched andalso extended andalso dragged end
fun nested_link_fixture(f: !Font,r: !Rend,root: !Buf): int = let
  val outer=write_note(root,"nav-outer.md","![[nav-inner]]\n")
  val inner=write_note(root,"nav-inner.md","[[nav-destination#^target|deep]]\n")
  val destination=write_note(root,"nav-destination.md","destination ^target\n")
  val source=bytes("![[nav-outer]]\n") val d=doc_open() val length=buf_len(source)
  val ()=doc_insert_buf(d,source,length) val ()=buf_free(source)
  val tabs=TCons(d,buf_make(0),buf_make(0),0,TNil()) var cache: Cache=CNil() var scratch: Buf=buf_make(256)
  val deepest=nested_link_check(f,r,tabs,root,cache,scratch,destination,"^target",false)
  val replaced=write_note(root,"nav-inner.md","plain\n") val ()=buf_free(replaced)
  val nested_box=nested_link_check(f,r,tabs,root,cache,scratch,inner,"",false)
  val replaced=write_note(root,"nav-inner.md","[[#^target|deep]]\n\nvalue ^target\n") val ()=buf_free(replaced)
  val same_file=nested_link_check(f,r,tabs,root,cache,scratch,inner,"^target",false)
  val replaced=write_note(root,"nav-inner.md","[deep](https://example.org)\n") val ()=buf_free(replaced)
  val url=bytes("https://example.org") val external=nested_link_check(f,r,tabs,root,cache,scratch,url,"",true) val ()=buf_free(url)
  val ()=tabs_free(tabs) val ()=cache_free(cache) val ()=buf_free(scratch)
  val a=fs_unlink(buf_cstr(outer)) val b=fs_unlink(buf_cstr(inner)) val c=fs_unlink(buf_cstr(destination))
  val ()=buf_free(outer) val ()=buf_free(inner) val ()=buf_free(destination)
  val ()=println!("event=embed_navigation deepest=",deepest," nested_box=",nested_box," same_file=",same_file," external=",external)
in if deepest andalso nested_box andalso same_file andalso external andalso ieq(a,0) andalso ieq(b,0) andalso ieq(c,0) then 0 else 1 end
