staload "mem.sats"

datavtype TextFileResult = TextFile of Buf | TextFileError of int
fun text_file_read(path: string): TextFileResult
fun text_skip_space(b: !Buf, p: int, endpos: int): int
fun text_line_end(b: !Buf, p: int, endpos: int): int
fun text_find_byte(b: !Buf, p: int, endpos: int, value: int): int
fun text_hex(b: !Buf, p: &int >> _, endpos: int): int
fun text_token_is(b: !Buf, start: int, endpos: int, token: string): bool
