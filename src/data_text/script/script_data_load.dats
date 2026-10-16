#include "data_text/script/script_data_internal.hats"
fun error_of(e: PropertyError): ScriptError = case+ e of
  | PropertyIo(code) => @{reason=ScriptIo(),detail=code}
  | PropertyHeader() => @{reason=ScriptHeader(),detail=0} | PropertyRanges() => @{reason=ScriptRanges(),detail=0}
fun reject(s: PropertyMap(7),e: ScriptExtensions,reason: ScriptFailure): ScriptDataRead = let
  val ()=property_dispose(s) and ()=script_extensions_dispose(e)
in ScriptDataRejected(@{reason=reason,detail=0}) end
implement script_data_make(s,e) = case+ script_data_check(s,e) of
  | ScriptDataReady() => ScriptDataAccepted(ScriptData(s,e))
  | ScriptDataInvalid() => reject(s,e,ScriptRanges()) | ScriptDataCapacity() => reject(s,e,ScriptCapacity())
fun extensions(s: PropertyMap(7),path: string): ScriptDataRead =
  case+ script_extensions_load(path) of | ~ScriptExtensionsAccepted(e) => script_data_make(s,e)
  | ~ScriptExtensionsRejected(e) => let val ()=property_dispose(s) in ScriptDataRejected(error_of(e)) end
implement script_data_load(scripts,path) = case+ property_load(scripts,ScriptProperty()) of
  | ~PropertyRejected(e) => ScriptDataRejected(error_of(e)) | ~PropertyLoaded(s) => extensions(s,path)
implement script_data_dispose(data) = let val+ ~ScriptData(s,e)=data
in property_dispose(s); script_extensions_dispose(e) end
