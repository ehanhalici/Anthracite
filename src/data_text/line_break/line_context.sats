staload "data_text/line_break/line_types.sats"
fun line_state_initial(): LineState
fun line_state_advance(state: LineState,token: LineToken,index: int): LineState
fun line_context_make(tokens: !LineTokens,index: int,state: LineState): LineContext
