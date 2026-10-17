#include "data_text/script/script_data_internal.hats"
implement script_data_set(data,cp) = let val+ ScriptData(s,e)=data in script_set(e,s,cp) end
implement script_data_at(data,set,index) = let val+ ScriptData(s,e)=data in script_set_at(e,set,index) end
implement script_data_contains(data,set,code) = let val+ ScriptData(s,e)=data in script_set_contains(e,set,code) end
implement script_data_capacity(data) = let val+ ScriptData(s,e)=data val+ ScriptExtensions(b,count,total)=e
in imax(1,total) end
