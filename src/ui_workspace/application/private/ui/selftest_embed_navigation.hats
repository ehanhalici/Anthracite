fun selftest_embed_navigation(root: string): int = let
  var vault=buf_make(c_strlen(root)) val ()=buffer_append_string(vault,root)
  val path=selftest_fixture_path(root,"embed-navigation.md")
  var child=buf_make(64) val ()=buffer_append_string(child,"literal Word\n\n# Word\nbody ^abc\n")
  val length=buf_len(child) val written=fs_write_buf(buf_cstr(path),child,length) val ()=buf_free(child)
  var source=buf_make(64) val ()=buffer_append_string(source,"![[embed-navigation#^abc]]\n")
  val document=doc_open() val length=buf_len(source) val ()=doc_insert_buf(document,source,length)
  val ()=doc_set_caret_move(document,0) val ()=buf_free(source)
  val tabs=TCons(document,buf_make(0),buf_make(0),0,TNil()) var target: int= ~1
  val opened=app_wiki_open(tabs,0,vault,target)
  val first=ieq(target,1) andalso ieq(tabs_len(opened),2) andalso ieq(tabs_caret(opened,1),c_strlen("literal Word\n\n# Word\n"))
  val reused=app_wiki_open(opened,0,vault,target)
  val same=ieq(target,1) andalso ieq(tabs_len(reused),2)
  val ()=tabs_free(reused) val removed=fs_unlink(buf_cstr(path))
  val ()=buf_free(vault) val ()=buf_free(path)
in if first andalso same andalso ieq(written,1) andalso ieq(removed,0) then 1 else 0 end
