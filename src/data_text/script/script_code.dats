#include "data_text/script/script_internal.hats"
implement script_code_valid(code) = property_serialized_value_valid(ScriptProperty(),code)
implement script_code_implicit(code) =
  ieq(code.code,SCRIPT_COMMON) orelse ieq(code.code,SCRIPT_INHERITED) orelse ieq(code.code,SCRIPT_UNKNOWN)
