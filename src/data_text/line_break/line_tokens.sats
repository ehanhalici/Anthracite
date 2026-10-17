staload "data_text/line_break/line_types.sats"
fun line_tokens_make(capacity: int): LineTokens
fun line_tokens_put(tokens: !LineTokens,index: int,token: LineToken): void
fun line_tokens_mark(tokens: !LineTokens,index: int,zwj: bool): void
fun line_tokens_get(tokens: !LineTokens,index: int): LineToken
fun line_tokens_count(tokens: !LineTokens): int
fun line_tokens_finish(tokens: LineTokens,count: int): LineTokens
fun line_tokens_dispose(tokens: LineTokens): void
fun line_missing(): LineToken
