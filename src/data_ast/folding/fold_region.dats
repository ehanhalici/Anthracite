#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "airlock.sats"
staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/folding/fold_region.sats"

(* Markdown & parsing constants *)
macdef CHAR_CR = 13
macdef TAB_WIDTH_SPACES = 4
macdef MAX_HEADING_LEVEL = 6
macdef INITIAL_BUF_BYTES = 16
macdef INITIAL_STACK_BYTES = 256


(* Private implementation groups share this owner and its linear representation. *)
#include "data_ast/folding/private/fold_region/fold_region_count.hats"
#include "data_ast/folding/private/fold_region/stack_top_line.hats"
#include "data_ast/folding/private/fold_region/regions_sort_by_owner.hats"
