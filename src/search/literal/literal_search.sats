staload "mem.sats"
macdef SEARCH_CASE_MAGIC = 0x53434D50
macdef SEARCH_CASE_VERSION = 1
macdef SEARCH_CASE_HEADER_WORDS = 3
macdef SEARCH_CASE_ENTRY_WORDS = 2
macdef SEARCH_CASE_HEADER_MAGIC = 0
macdef SEARCH_CASE_HEADER_VERSION = 1
macdef SEARCH_CASE_HEADER_COUNT = 2
macdef SEARCH_CASE_LOOKUP_BITS = 32
macdef SEARCH_CASE_LIMIT_BYTES = 1048576
macdef SEARCH_CASE_FIELD_SCALAR = 0
macdef SEARCH_CASE_FIELD_REPRESENTATIVE = 1
macdef LITERAL_RANGE_WORDS = 2
macdef LITERAL_RANGE_START = 0
macdef LITERAL_RANGE_FINISH = 1
macdef LITERAL_SOURCE_LIMIT_BYTES = 16777216
macdef LITERAL_QUERY_LIMIT_BYTES = 4096
macdef LITERAL_MATCH_LIMIT = 4096
datavtype LiteralPattern = LiteralPattern of (Buf,Buf,Buf)
fun literal_pattern_open(query: !Buf,case_map_path: string): Option_vt(LiteralPattern)
fun literal_pattern_free(pattern: LiteralPattern): void
fun literal_pattern_release(pattern: Option_vt(LiteralPattern)): void
(* Clears ranges. Returns match count, or -1 for an unsupported source span.
   Ranges are original UTF8 bytes; overlapping matches are retained. *)
fun literal_collect(pattern: !LiteralPattern,source: !Buf,ranges: &Buf >> _,limit: int): int
fun literal_case_lookup(table: !Buf,scalar: int): int
