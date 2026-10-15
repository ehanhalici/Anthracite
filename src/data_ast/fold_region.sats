#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"
staload "data_ast/doc.sats"

macdef FR_PLAIN = 0
macdef FR_HEADING = 1
macdef FR_DELIMITED = 2

macdef BYTES_PER_WORD = 4
macdef FR_OWNER = 0
macdef FR_END = 1
macdef FR_OFFSET = 2
macdef FR_KIND = 3
macdef FR_ENTRY_WORDS = 4
macdef FR_ENTRY_BYTES = 16

fun fold_region_build(d: !Doc, regions: &Buf >> _): int
fun fold_region_count(regions: !Buf): int
fun fold_region_owner(regions: !Buf, idx: int): int
fun fold_region_end(regions: !Buf, idx: int): int
fun fold_region_offset(regions: !Buf, idx: int): int
fun fold_region_kind(regions: !Buf, idx: int): int
fun fold_region_of_line(regions: !Buf, line: int): int
fun fold_region_find_by_offset(regions: !Buf, off: int): int

fun fold_regions_compute_hidden(d: !Doc, regions: !Buf, hidden: &Buf >> _): void
fun fold_region_line_hidden(hidden: !Buf, line: int): int
