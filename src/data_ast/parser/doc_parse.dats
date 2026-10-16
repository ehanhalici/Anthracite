#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/parser/doc_parse.sats"


(* Private implementation groups share this owner and its linear representation. *)
#include "data_ast/parser/private/doc_parse/node_append.hats"
#include "data_ast/parser/private/doc_parse/find_one.hats"
#include "data_ast/parser/private/doc_parse/gather.hats"
