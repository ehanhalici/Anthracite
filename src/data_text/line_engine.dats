#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_types.sats"
staload "data_text/line_engine.sats"
staload "data_text/line_source.sats"
staload "data_text/line_tokens.sats"
staload "data_text/line_break_map.sats"
staload "data_text/line_context.sats"
staload "data_text/line_rules.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_property.sats"
staload "data_text/unicode_db.sats"

extern fun line_engine_exhausted(): void = "mac#anth_die_void"

fun boundaries {fuel:nat} .<fuel>. (fuel: int(fuel),tokens: !LineTokens,
  result: !LineBreakMap,index: int,n: int,state: LineState): void =
  if ige(index,n) then () else if fuel = 0 then line_engine_exhausted() else let
    val context = line_context_make(tokens,index,state)
    val () = line_breaks_put(result,context.right.source,line_finalize(line_decide(context)))
    val next = line_state_advance(state,context.right,index)
  in boundaries(fuel-1,tokens,result,iadd(index,1),n,next) end

fun run(tokens: !LineTokens,result: !LineBreakMap): void = let
  val n = line_tokens_count(tokens)
  val first = line_tokens_get(tokens,0)
  val state = line_state_advance(line_state_initial(),first,0)
in if igt(n,0) then boundaries(airlock_nat(n),tokens,result,1,n,state) else () end

implement line_boundaries(map,width,category,emoji,text) = let
  val tokens = line_tokens_build(map,width,category,emoji,text)
  val n = scalar_count(text)
  val result = line_breaks_make(n)
  val () = run(tokens,result)
  val () = line_breaks_put(result,n,BreakMandatory())
  val () = line_tokens_dispose(tokens)
in result end
