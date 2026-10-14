#include "data_font/font_native_slot_internal.hats"
implement font_native_primary_shape(slot,b,info,assets,a,contexts,item,token,language,masks,scale) = case+ info of
  | None() => FontNativeNoFace() | Some(info) => font_native_slot_shape(slot,b,info,assets,a,contexts,item,token,language,masks,scale)
implement font_native_fallback_shape(slot,b,info,assets,a,contexts,item,token,language,masks,scale) = case+ info of
  | None() => FontNativeNoFace() | Some(info) => (case+ b of
    | @None_vt() => let prval ()=fold@(b) in FontNativeNoFace() end
    | @Some_vt(file) => let
      val result=font_native_slot_shape(slot,file,info,assets,a,contexts,item,token,language,masks,scale)
      prval ()=fold@(b)
    in result end)
