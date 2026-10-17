#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "data_ast/document/doc.sats"
staload "ui_workspace/embed/embedded_doc.sats"
staload "os/fs.sats"
staload "mem.sats"
macdef EMBED_SOURCE_PATH_BYTES = 512
implement embedded_source_stamp(path) = let
  val buffer=buf_make(EMBED_SOURCE_PATH_BYTES)
  val ()=fs_vfs_buf(path,buffer,isub(EMBED_SOURCE_PATH_BYTES,1))
  val shadow=fs_file_stamp(buf_cstr(buffer))
  val active=shadow.exists andalso shadow.length > 0L
  val effective=if active then shadow else fs_file_stamp(path)
  val ()=buf_free(buffer)
in @{file=effective,shadow=active} end
implement embedded_source_equal(a,b) = a.shadow = b.shadow andalso fs_file_stamp_equal(a.file,b.file)

implement embedded_doc_load(d, path, level) = let
  val () = doc_set_embed_level(d, level)
  val loaded = doc_load(d, path)
in
  loaded
end
