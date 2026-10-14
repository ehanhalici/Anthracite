#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_hangul.sats"
staload "data_text/normalization_expand.sats"
staload "data_text/normalization_data.sats"
extern fun expand_exhausted(): int = "mac#anth_die_int"

implement normalization_expansion_action(kind,scope,hangul_count) =
  if igt(hangul_count,0) then ExpandHangul() else case+ kind of
  | NoMapping() => EmitScalar()
  | CanonicalMapping() => ExpandMapping()
  | CompatibilityMapping() => (case+ scope of
      | CanonicalScope() => EmitScalar() | CompatibilityScope() => ExpandMapping())

fun emit(cp: int, span: SourceSpan, values: !Buf, starts: !Buf, ends: !Buf, output: int): int = let
  val () = buf_set32(values,output,cp)
  val () = buf_set32(starts,output,span.start)
  val () = buf_set32(ends,output,span.finish)
in iadd(output,1) end

fun push_mapping {n:nat} .<n>. (
  n: int(n), data: !NormalizationData, stack: !Buf, at: int, pending: int
): void = if n = 0 then () else let
  val () = buf_set32(stack,pending,normalization_mapping(data,at))
in push_mapping(n-1,data,stack,isub(at,1),iadd(pending,1)) end

fun push_hangul(stack: !Buf, parts: HangulParts, pending: int): int = let
  val third = ieq(parts.count,3)
  val () = if third then buf_set32(stack,pending,parts.third) else ()
  val at = iadd(pending,if third then 1 else 0)
  val () = buf_set32(stack,at,parts.second)
  val () = buf_set32(stack,iadd(at,1),parts.first)
in iadd(pending,parts.count) end

fun expand_one(
  data: !NormalizationData, scope: DecompositionScope, span: SourceSpan,
  values: !Buf, starts: !Buf, ends: !Buf, stack: !Buf, state: ExpansionState
): ExpansionState = let
  val pending = isub(state.pending,1)
  val cp = buf_get32(stack,pending)
  val parts = normalization_hangul_parts(cp)
  val row = normalization_info(data,cp)
in case+ normalization_expansion_action(row.kind,scope,parts.count) of
  | EmitScalar() => @{pending=pending,output=emit(cp,span,values,starts,ends,state.output)}
  | ExpandHangul() => @{pending=push_hangul(stack,parts,pending),output=state.output}
  | ExpandMapping() => let
      val last = isub(iadd(row.offset,row.count),1)
      val () = push_mapping(airlock_nat(row.count),data,stack,last,pending)
    in @{pending=iadd(pending,row.count),output=state.output} end end

fun expand {n:nat} .<n>. (
  n: int(n), data: !NormalizationData, scope: DecompositionScope, span: SourceSpan,
  values: !Buf, starts: !Buf, ends: !Buf, stack: !Buf, state: ExpansionState
): int = if ieq(state.pending,0) then state.output else if n = 0 then expand_exhausted() else let
  val next = expand_one(data,scope,span,values,starts,ends,stack,state)
in expand(n-1,data,scope,span,values,starts,ends,stack,next) end

implement normalization_expand_scalar(data,scope,cp,span,values,starts,ends,stack,output) = let
  val h = normalization_header(data)
  val fuel = iadd(imul(h.depth,h.expansion),1)
  val () = buf_set32(stack,0,cp)
in expand(airlock_nat(fuel),data,scope,span,values,starts,ends,stack,@{pending=1,output=output}) end
