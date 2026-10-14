staload "data_text/script_types.sats"
staload "data_text/unicode_property.sats"
datatype ScriptDataStatus = ScriptDataReady | ScriptDataInvalid | ScriptDataCapacity
datatype ScriptFailure = ScriptIo | ScriptHeader | ScriptRanges | ScriptCapacity
typedef ScriptError = @{reason=ScriptFailure,detail=int}
datavtype ScriptData = ScriptData of (PropertyMap(7),ScriptExtensions)
datavtype ScriptDataRead = ScriptDataAccepted of ScriptData | ScriptDataRejected of ScriptError
