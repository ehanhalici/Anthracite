#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/line_break/line_source.sats"
staload "data_text/line_break/line_tokens.sats"
staload "data_text/line_break/line_groups.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/unicode_db.sats"

typedef BuildState = @{count=int,previous=LineClass}
extern fun line_build_exhausted(): int = "mac#anth_die_int"

fun normalized_token(t: LineToken): LineToken =
  if line_is_combining(t.kind) then line_unbound_mark(t) else t

fun append(tokens: !LineTokens,t: LineToken,state: BuildState): BuildState = let
  val token = normalized_token(t)
  val () = line_tokens_put(tokens,state.count,token)
in @{count=iadd(state.count,1),previous=token.kind} end

fun consume(tokens: !LineTokens,t: LineToken,state: BuildState): BuildState =
  if line_is_combining(t.kind) andalso line_accepts_marks(state.previous) then let
    val () = line_tokens_mark(tokens,isub(state.count,1),t.zwj)
  in state end else append(tokens,t,state)

fun build {fuel:nat} .<fuel>. (fuel: int(fuel),map: !PropertyMap(4),
  width: !PropertyMap(5),category: !PropertyMap(6),emoji: !UnicodeDb,
  text: !ScalarText,tokens: !LineTokens,i: int,n: int,state: BuildState): int =
  if ige(i,n) then state.count else if fuel = 0 then line_build_exhausted() else let
    val token = line_source_token(map,width,category,emoji,scalar_value(text,i),i)
    val next = consume(tokens,token,state)
  in build(fuel-1,map,width,category,emoji,text,tokens,iadd(i,1),n,next) end

implement line_tokens_build(map,width,category,emoji,text) = let
  val n = scalar_count(text)
  val tokens = line_tokens_make(n)
  val count = build(airlock_nat(iadd(n,1)),map,width,category,emoji,text,tokens,0,n,
    @{count=0,previous=LMissing()})
in line_tokens_finish(tokens,count) end
