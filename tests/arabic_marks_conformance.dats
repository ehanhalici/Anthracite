#include "arabic_marks_test.hats"
fun modifier(data: !NormalizationData): int = case+ property_load(c_argv(2),ModifierMarkProperty()) of
  | ~PropertyRejected(e) => 1 | ~PropertyLoaded(mcm) => let
    val cases=marks_test_cases(data,mcm) and stress=marks_test_stress(data,mcm)
    val properties=marks_test_properties(mcm)
    val ()=println!("event=arabic_marks_properties points=1114112 errors=",properties)
    val ()=println!("event=arabic_marks cases_errors=",cases," stress_errors=",stress)
    val ()=property_dispose(mcm)
  in cases+stress+properties end
fun data(): int = case+ normalization_load(c_argv(1)) of | ~NormalizationRejected(e) => 1
  | ~NormalizationLoaded(n) => let val errors=modifier(n) val ()=normalization_dispose(n) in errors end
fun owned(before: int): int = if ieq(before,mem_live()) then 0 else 1
fun cases(): int = if ieq(c_argc(),3) then data() else 1
implement main0() = let val before=mem_live()
  val errors=cases()
  val owned=owned(before)
  val ()=println!("event=arabic_marks_ownership buf_errors=",owned)
in if igt(iadd(errors,owned),0) then exit(1) else () end
