#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "data_ast/doc.sats"
staload "ui_workspace/embedded_doc.sats"

implement embedded_doc_load(d, path, level) = let
  val () = doc_set_embed_level(d, level)
  val loaded = doc_load(d, path)
in
  loaded
end
