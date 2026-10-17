#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "data_ast/document/doc.sats"

fun inl_parse(d: !Doc, blk_idx: int, st: int, en: int): void

fun inl_parse_depth(
  d: !Doc, parent: int, st: int, en: int, depth: int, last_sib: &int >> _
): void
