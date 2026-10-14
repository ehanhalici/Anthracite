#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_engine.sats"
staload "data_text/normalization_expand.sats"
staload "data_text/normalization_errors.sats"
staload "data_text/normalization_data.sats"
extern fun decompose_mismatch(): int = "mac#anth_die_int"

fun decompose {n:nat} .<n>. (
  n: int(n), data: !NormalizationData, text: !ScalarText, scope: DecompositionScope,
  values: !Buf, starts: !Buf, ends: !Buf, stack: !Buf, i: int, output: int
): int = if n = 0 then output else let
  val cp = scalar_value(text,i)
  val span = @{start=scalar_start(text,i),finish=scalar_end(text,i)}
  val next = normalization_expand_scalar(data,scope,cp,span,values,starts,ends,stack,output)
in decompose(n-1,data,text,scope,values,starts,ends,stack,iadd(i,1),next) end

fun expand_text(data: !NormalizationData, text: !ScalarText,start: int,finish: int, scope: DecompositionScope, total: int): NormalizationExpansion = let
  val values = buf_make(imul(total,4))
  val starts = buf_make(imul(total,4))
  val ends = buf_make(imul(total,4))
  val h = normalization_header(data)
  val stack = buf_make(imul(iadd(h.expansion,1),4))
  val actual = decompose(airlock_span(start,finish),data,text,scope,values,starts,ends,stack,start,0)
  val () = buf_free(stack)
  val () = if ine(actual,total) then let val stop = decompose_mismatch() in () end else ()
in ExpandedText(NormalText(values,starts,ends,total,scalar_errors(text))) end

implement normalization_decompose(data,text,scope) = normalization_decompose_range(data,text,0,scalar_count(text),scope)
implement normalization_decompose_range(data,text,start,finish,scope) =
  if ilt(start,0) orelse ilt(finish,start) orelse igt(finish,scalar_count(text)) then ExpansionRejected(NormSource())
  else let val total=normalization_expanded_count_range(data,text,start,finish,scope)
  in if ilt(total,0) then ExpansionRejected(NormLength()) else expand_text(data,text,start,finish,scope,total) end
