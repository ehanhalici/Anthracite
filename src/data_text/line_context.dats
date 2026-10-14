#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_types.sats"
staload "data_text/line_context.sats"
staload "data_text/line_tokens.sats"
staload "data_text/line_predicates.sats"
staload "data_text/line_groups.sats"

implement line_state_initial() = @{anchor= ~1,numeric=false,beforeNumeric=false,regional=0}

implement line_state_advance(s,t,index) =
  @{anchor=if line_is_sp(t.kind) then s.anchor else index,
    numeric=line_is_nu(t.kind) orelse (line_is_number_sep(t.kind) andalso s.numeric),
    beforeNumeric=s.numeric,
    regional=if line_is_ri(t.kind) then iadd(s.regional,1) else 0}

implement line_context_make(tokens,index,state) =
  @{left=line_tokens_get(tokens,isub(index,1)),right=line_tokens_get(tokens,index),
    before=line_tokens_get(tokens,isub(index,2)),
    next=line_tokens_get(tokens,iadd(index,1)),next2=line_tokens_get(tokens,iadd(index,2)),
    anchor=line_tokens_get(tokens,state.anchor),
    beforeAnchor=line_tokens_get(tokens,isub(state.anchor,1)),state=state}
