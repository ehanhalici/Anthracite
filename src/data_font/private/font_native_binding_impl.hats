(* Included only by Font's singular representation owner. No second assume. *)
fun native_registry(slot: !Option_vt(NativeShapeCache)): int = case+ slot of
  | None_vt() => ~1 | Some_vt(cache) => let val+ NativeShapeCache(m,sub,pos,key)=cache in key.font end
implement font_native_current(f,face) = case+ f of | @FONT(s) => let
  val token: FontNativeToken=case+ face of
    | GlyphPrimaryFace() => @{face=face,font=native_registry(s.native_primary),generation=s.native_generation}
    | GlyphFallbackFace() => @{face=face,font=native_registry(s.native_fallback),generation=s.native_fb_generation}
  prval ()=fold@(f)
in token end
