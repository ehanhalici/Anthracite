staload "mem.sats"
fun text_field(source: !Buf, start: int, finish: int, index: int): int
fun text_decimal(source: !Buf, position: &int >> _, finish: int): int
fun text_token_end(source: !Buf, start: int, finish: int): int
