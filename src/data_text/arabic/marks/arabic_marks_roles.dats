#include "data_text/arabic/marks/arabic_marks_internal.hats"
fun mark_prefix(previous: ArabicMarkState,ccc: int): ArabicMarkPrefix =
  if ine(previous.ccc,ccc) then MarkPrefixOpen() else previous.gate
fun modifier_of(ccc: int): ArabicMarkRole = case+ ccc of
  | 220 => MarkModifierBelow() | 230 => MarkModifierAbove() | _ => MarkOther()
fun role(state: ArabicMarkPrefix,ccc: int,modifier: bool): ArabicMarkRole =
  if ieq(ccc,33) then MarkShadda() else case+ state of
    | MarkPrefixClosed() => MarkOther()
    | MarkPrefixOpen() => if modifier then modifier_of(ccc) else MarkOther()
fun retained(role: ArabicMarkRole): ArabicMarkPrefix = case+ role of
  | MarkModifierBelow() => MarkPrefixOpen() | MarkModifierAbove() => MarkPrefixOpen()
  | MarkShadda() => MarkPrefixClosed() | MarkOther() => MarkPrefixClosed()
implement arabic_mark_step(state,ccc,modifier) = let val selected=role(mark_prefix(state,ccc),ccc,modifier)
in @{state= @{ccc=ccc,gate=retained(selected)},role=selected} end
implement arabic_mark_role_code(role) = case+ role of | MarkModifierBelow() => 0
  | MarkModifierAbove() => 1 | MarkShadda() => 2 | MarkOther() => 3
implement arabic_mark_role_of(code) = case+ code of | 0 => MarkModifierBelow()
  | 1 => MarkModifierAbove() | 2 => MarkShadda() | _ => MarkOther()
