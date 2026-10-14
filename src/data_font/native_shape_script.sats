staload "data_text/script_types.sats"
staload "data_font/ot_shape_types.sats"
(* A prepared script request is a cold, per-run owner, not a per-glyph object.
   Unsupported complex scripts do not silently become the common shaper. *)
datavtype NativeScriptRequestRead = NativeScriptRequestAccepted of OtShapeRequest
  | NativeScriptRequestUnsupported of ScriptCode
fun native_shape_script_request(script: ScriptCode,language: OtShapeLanguage,direction: OtShapeDirection): NativeScriptRequestRead

