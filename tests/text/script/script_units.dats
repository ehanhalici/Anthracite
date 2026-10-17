#include "text/script/script_test.hats"
fun check(s: !PropertyMap(7),e: !ScriptExtensions,cp: int,code: int,count: int): int = let
  val set=script_set(e,s,cp)
in if ieq(set.script.code,code) andalso ieq(set.count,count) then 0 else 1 end
implement script_test_units(s,e,d) = let
  val errors=check(s,e,65,1281455214,1)+check(s,e,1576,1098015074,1)
    +check(s,e,769,SCRIPT_INHERITED,8)+check(s,e,1548,SCRIPT_COMMON,7)
    +check(s,e,8205,SCRIPT_INHERITED,1)+check(s,e,UNICODE_MAX_SCALAR,SCRIPT_UNKNOWN,1)
  val comma=script_set(e,s,1548) and accent=script_set(e,s,769)
  val members=script_set_contains(e,comma,@{code=1098015074})
    andalso not(script_set_contains(e,comma,@{code=1281455214}))
    andalso script_set_contains(e,accent,@{code=1281455214})
  val controls=ieq(property_value(d,8204),1) andalso ieq(property_value(d,8205),1)
    andalso ieq(property_value(d,1564),1) andalso ieq(property_value(d,65039),1)
    andalso ieq(property_value(d,65),0) andalso ieq(property_value(d,1576),0)
    andalso ieq(property_value(d,769),0) andalso ieq(property_value(d,1536),0)
in iadd(errors,if members andalso controls then 0 else 1) end
