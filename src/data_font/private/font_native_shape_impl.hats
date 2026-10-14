(* Record borrowing stays in Font's owner; all shaping lives elsewhere. *)
implement font_shape_native_item(f,assets,a,contexts,item,face,font,language,masks,scale) = case+ face of
  | GlyphPrimaryFace() => (case+ f of | @FONT(s) => let
    val result=font_native_primary_shape(s.native_primary,s.file,s.info,assets,a,contexts,item,
      @{face=face,font=font,generation=s.native_generation},language,masks,scale)
    prval ()=fold@(f)
  in result end)
  | GlyphFallbackFace() => (case+ f of | @FONT(s) => let
    val result=font_native_fallback_shape(s.native_fallback,s.fb_file,s.fb_info,assets,a,contexts,item,
      @{face=face,font=font,generation=s.native_fb_generation},language,masks,scale)
    prval ()=fold@(f)
  in result end)
