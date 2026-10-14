#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_text/script_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_shape_types.sats"
staload "data_font/native_shape_script.sats"
datatype ScriptShaper = ScriptCommonShaper | ScriptArabicShaper | ScriptUnavailableShaper
typedef ScriptMapping = @{shaper=ScriptShaper,tag=OtTag}
(* Common horizontal shaping covers Latin/Greek/Cyrillic/Hebrew and the
   common/inherited/unknown pseudo-scripts. Arabic keeps its joining profile.
   Remaining complex scripts keep the explicit unsupported request. *)
fun mapping_of(code: int): ScriptMapping = case+ code of
  | 1281455214 => @{shaper=ScriptCommonShaper(),tag= @{code=1818326126}}
  | 1198679403 => @{shaper=ScriptCommonShaper(),tag= @{code=1735550315}}
  | 1132032620 => @{shaper=ScriptCommonShaper(),tag= @{code=1668903532}}
  | 1214603890 => @{shaper=ScriptCommonShaper(),tag= @{code=1735550315}}
  | 1098015074 => @{shaper=ScriptArabicShaper(),tag= @{code=1634885986}}
  | 1517910393 => @{shaper=ScriptCommonShaper(),tag= @{code=1145457748}}
  | 1516858984 => @{shaper=ScriptCommonShaper(),tag= @{code=1145457748}}
  | 1517976186 => @{shaper=ScriptCommonShaper(),tag= @{code=1145457748}}
  | _ => @{shaper=ScriptUnavailableShaper(),tag= @{code=1145457748}}
implement native_shape_script_request(script,language,direction) = let val mapping=mapping_of(script.code)
in case+ mapping.shaper of | ScriptUnavailableShaper() => NativeScriptRequestUnsupported(script)
  | ScriptCommonShaper() => NativeScriptRequestAccepted(@{profile=ShapeCommonHorizontal(),script=mapping.tag,language=language,direction=direction})
  | ScriptArabicShaper() => NativeScriptRequestAccepted(@{profile=ShapeArabicHorizontal(),script=mapping.tag,language=language,direction=direction}) end

