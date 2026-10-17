#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef DOC_OPEN_GAP_INITIAL_BYTES = 256
macdef DOC_OPEN_HIDDEN_INITIAL_BYTES = 64
macdef DOC_TAKE_REGIONS_BUFFER_INITIAL_BYTES = 0
macdef DOC_TAKE_HIDDEN_BUFFER_INITIAL_BYTES = 0
macdef TAKE_GAP_BUFFER_INITIAL_BYTES = 1
macdef TAKE_LAYOUT_BUFFER_INITIAL_BYTES = 1
macdef DOC_SAVE_BUFFER_INITIAL_BYTES = 16
macdef DOC_SAVE_VFS_VBUF_INITIAL_BYTES = 512
macdef DOC_SAVE_PHYSICAL_VBUF_INITIAL_BYTES = 512
macdef DOC_LOAD_VBUF_INITIAL_BYTES = 512
macdef REPLACE_TASK_MARK_BUFFER_INITIAL_BYTES = 2


staload "mem.sats"
staload "core_runtime/performance.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/selftest_fixture.sats"
staload "os/diag.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/document/doc_anchor.sats"
staload "data_ast/layout/layout.sats"
staload "data_ast/layout/layout_internal.sats"
staload "data_ast/layout/doc_visual.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_ast/parser/doc_parse.sats"
staload "data_ast/syntax/ast.sats"
staload "data_ast/selftest/ast_test.sats"
staload "data_ast/parser/block/blk_parse.sats"
staload "data_ast/folding/fold_region.sats"

#define AST_NODE_WORDS 16

#define DOC_FIELD_LO 0
#define DOC_FIELD_HI 1
#define DOC_FIELD_LEN 2
#define DOC_FIELD_CARET 3
#define DOC_FIELD_ANCHOR 4
#define DOC_FIELD_NLINES 5
#define DOC_FIELD_NNODES 6
#define DOC_FIELD_SPAN 7

#define DOC_OP_NONE 0
#define DOC_OP_TYPING 1
#define DOC_OP_BATCH 2

datavtype Hist =
  | HNil of ()
  | HCons of (Buf, int, Hist)


(* Private implementation groups share this owner and its linear representation. *)
#include "data_ast/document/private/doc/hist_free.hats"
#include "data_ast/document/private/doc/fold_has.hats"
#include "data_ast/document/private/doc/folds_apply_edit.hats"
#include "data_ast/document/private/doc/gap_room.hats"
#include "data_ast/document/private/doc/count_edit.hats"
#include "data_ast/document/private/doc/heading_kind.hats"
#include "data_ast/document/private/doc/node_append.hats"
#include "data_ast/document/private/doc/find_line_owner_node.hats"
#include "data_ast/document/private/doc/line_heading_pad.hats"
#include "data_ast/document/private/doc/doc_insert_reparse.hats"
#include "data_ast/document/private/doc/doc_down_target.hats"
#include "data_ast/document/private/doc/page_down_select.hats"
#include "data_ast/document/private/doc/doc_load_checked.hats"
#include "data_ast/document/private/doc/selftest_fm_check.hats"
#include "data_ast/document/private/doc/span_covered.hats"
#include "data_ast/document/private/doc/doc_selftest.hats"
