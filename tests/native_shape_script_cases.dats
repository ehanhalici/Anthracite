#include "native_shape_test.hats"
staload "data_text/script_types.sats"
staload "data_font/native_shape_script.sats"
fun profile(r: OtShapeProfile): int = case+ r of | ShapeCommonHorizontal() => 0 | ShapeArabicHorizontal() => 1
fun known(code: int,tag: int,expected: int): int =
  case+ native_shape_script_request(@{code=code},ShapeDefaultLanguage(),ShapeRTL()) of
    | ~NativeScriptRequestUnsupported(c) => 1
    | ~NativeScriptRequestAccepted(r) => let
      val rtl: bool=case+ r.direction of | ShapeRTL() => true | ShapeLTR() => false
    in if ieq(r.script.code,tag) andalso ieq(profile(r.profile),expected) andalso rtl then 0 else 1 end
fun unsupported(): int = case+ native_shape_script_request(@{code=1113943655},ShapeDefaultLanguage(),ShapeLTR()) of
  | ~NativeScriptRequestUnsupported(c) => 0 | ~NativeScriptRequestAccepted(r) => 1
implement native_test_script_cases() = known(1281455214,1818326126,0)+known(1198679403,1735550315,0)
  +known(1132032620,1668903532,0)+known(1098015074,1634885986,1)
  +known(1517910393,1145457748,0)+known(1516858984,1145457748,0)+known(1517976186,1145457748,0)+unsupported()

