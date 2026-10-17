#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/line_break/line_tokens.sats"

implement line_missing() = @{kind=LMissing(),cp= ~1,
  facts= @{east=false,initial=false,final=false,potential=false},zwj=false,source= ~1}

implement line_tokens_make(capacity) = let
  val n = airlock_below(capacity,MAX_REC_FUEL)
  val bytes = imul(n,4)
in LineTokens(buf_make(bytes),buf_make(bytes),buf_make(bytes),
    buf_make(bytes),buf_make(n),0) end

implement line_tokens_put(tokens,index,t) = let
  val+ LineTokens(kinds,points,facts,starts,joins,n) = tokens
  val at = imul(index,4)
  val () = buf_set32(kinds,index,line_class_code(t.kind))
  val () = buf_set32(points,index,t.cp)
  val () = buf_set32(starts,index,t.source)
  val () = buf_set(joins,index,if t.zwj then 1 else 0)
  val () = buf_set(facts,at,if t.facts.east then 1 else 0)
  val () = buf_set(facts,iadd(at,1),if t.facts.initial then 1 else 0)
  val () = buf_set(facts,iadd(at,2),if t.facts.final then 1 else 0)
in buf_set(facts,iadd(at,3),if t.facts.potential then 1 else 0) end

implement line_tokens_mark(tokens,index,zwj) = let
  val+ LineTokens(kinds,points,facts,starts,joins,n) = tokens
in buf_set(joins,index,if zwj then 1 else 0) end

implement line_tokens_get(tokens,index) = let
  val+ LineTokens(kinds,points,facts,starts,joins,n) = tokens
  val at = imul(index,4)
in if ilt(index,0) orelse ige(index,n) then line_missing() else
  @{kind=line_class_of(buf_get32(kinds,index)),cp=buf_get32(points,index),
    facts= @{east=ine(buf_get(facts,at),0),initial=ine(buf_get(facts,iadd(at,1)),0),
      final=ine(buf_get(facts,iadd(at,2)),0),potential=ine(buf_get(facts,iadd(at,3)),0)},
    zwj=ine(buf_get(joins,index),0),source=buf_get32(starts,index)} end

implement line_tokens_count(tokens) = let val+ LineTokens(a,b,c,d,e,n) = tokens in n end
implement line_tokens_finish(tokens,count) = let val+ ~LineTokens(a,b,c,d,e,n) = tokens in
  LineTokens(a,b,c,d,e,count) end
implement line_tokens_dispose(tokens) = let val+ ~LineTokens(a,b,c,d,e,n) = tokens in
  buf_free(a); buf_free(b); buf_free(c); buf_free(d); buf_free(e) end
