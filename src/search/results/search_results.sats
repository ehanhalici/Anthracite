staload "mem.sats"
staload "search/literal/literal_search.sats"
staload "ui_workspace/tabs/ui_tab.sats"
macdef SEARCH_RESULT_WORDS = 4
macdef SEARCH_RESULT_MATCH = 0
macdef SEARCH_RESULT_TEXT = 1
macdef SEARCH_RESULT_LENGTH = 2
macdef SEARCH_RESULT_MATCH_LENGTH = 3
macdef SEARCH_RESULT_FILE_HEADER = ~1
macdef SEARCH_RESULT_LIMIT = 200
macdef SEARCH_JUMP_WORDS = 3
macdef SEARCH_JUMP_FILE = 0
macdef SEARCH_JUMP_LINE = 1
macdef SEARCH_JUMP_COLUMN = 2
typedef SearchAppendResult = @{matches=int,truncated=bool}
fun search_append_matches(source: !Buf,path: !Buf,pattern: !LiteralPattern,file: int,
  text: &Buf >> _,metadata: &Buf >> _,jumps: &Buf >> _,rows: &int >> _): SearchAppendResult
fun search_append_file(path: !Buf,tabs: !Tabs,pattern: !LiteralPattern,file: int,
  text: &Buf >> _,metadata: &Buf >> _,jumps: &Buf >> _,rows: &int >> _): SearchAppendResult
fun search_visible_count(metadata: !Buf,collapsed: !Buf): int
fun search_source_row(metadata: !Buf,collapsed: !Buf,visible: int): int
fun search_toggle_group(metadata: !Buf,collapsed: &Buf >> _,row: int): bool
fun search_row_is_header(metadata: !Buf,row: int): bool
fun search_next_result(metadata: !Buf,current: int,direction: int): int
