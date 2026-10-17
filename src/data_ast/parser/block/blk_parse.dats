#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef AST_PARSE_ALL_RES_INITIAL_BYTES = 4
macdef AST_REPARSE_DO_RESYNC_INITIAL_BYTES = 64


staload "mem.sats"
staload "core_runtime/performance.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "data_ast/syntax/ast.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/parser/block/blk_parse.sats"
staload "data_ast/parser/inline/inl_parse.sats"


(* Private implementation groups share this owner and its linear representation. *)
#include "data_ast/parser/block/private/blk_parse/line_end.hats"
#include "data_ast/parser/block/private/blk_parse/parse_fenced_code.hats"
#include "data_ast/parser/block/private/blk_parse/parse_table_row.hats"
#include "data_ast/parser/block/private/blk_parse/bsearch_resync.hats"
#include "data_ast/parser/block/private/blk_parse/find_last_top.hats"
