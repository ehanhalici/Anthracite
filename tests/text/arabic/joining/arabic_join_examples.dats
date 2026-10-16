#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "text/arabic/joining/arabic_join_contracts.sats"
fun example(map: !PropertyMap(3),plan: !ArabicMaskPlan,source: string,expected: string): int =
  arabic_test_sequence(map,plan,source,expected,@{before=BoundaryNone(),after=BoundaryNone()})
implement arabic_test_examples(map,plan) =
  example(map,plan,"","")+example(map,plan,"ب","0008")+example(map,plan,"بت","0001 0004")+
  example(map,plan,"بتب","0001 0002 0004")+example(map,plan,"بَت","0001 0000 0004")+
  example(map,plan,"ب‍ت","0001 0002 0004")+example(map,plan,"ب‌ت","0008 0000 0008")+
  example(map,plan,"بـت","0001 0002 0004")+example(map,plan,"اب","0008 0008")+
  example(map,plan,"با","0001 0004")+example(map,plan,"ابا","0008 0001 0004")+
  example(map,plan,"ىب","0001 0004")+example(map,plan,"َّ","0000 0000")+
  example(map,plan,"ıبَتİ","0000 0001 0000 0004 0000")+
  example(map,plan,"i̇","0000 0000")+example(map,plan,"ışık Türkçe","0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000")+
  example(map,plan,"𐻙ب","0001 0004")+example(map,plan,"ب𐻙","0008 0008")
implement arabic_test_boundaries(map,plan) =
  arabic_test_sequence(map,plan,"ب","0002",@{before=BoundaryDual(),after=BoundaryDual()})+
  arabic_test_sequence(map,plan,"ب","0004",@{before=BoundaryDual(),after=BoundaryNone()})+
  arabic_test_sequence(map,plan,"ب","0001",@{before=BoundaryNone(),after=BoundaryDual()})+
  arabic_test_sequence(map,plan,"ب","0001",@{before=BoundaryRight(),after=BoundaryRight()})+
  arabic_test_sequence(map,plan,"َبَ","0000 0002 0000",@{before=BoundaryLeft(),after=BoundaryCausing()})+
  arabic_test_sequence(map,plan,"ب","0004",@{before=BoundaryCausing(),after=BoundaryLeft()})+
  arabic_test_sequence(map,plan,"َّ","0000 0000",@{before=BoundaryDual(),after=BoundaryDual()})
