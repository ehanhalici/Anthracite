staload "data_font/native/text/native_text_coverage.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_font/native/text/native_text_items_types.sats"
(* Ownership-only adapter; Unicode/cmap traversal belongs to coverage.dats. *)
fun covered_file(b: !Buf,info: Option(SfntInfo),assets: !NativeTextAssets,
  a: !NativeTextAnalysis,item: NativeTextItem): bool = case+ info of
  | None() => false | Some(info) => let
    val+ NativeTextAssets(aux,words,lines,east)=assets
    val+ NativeTextAux(base,scripts,bidi,brackets,mirrors)=aux
    val+ NativeTextBase(data,norm,mcm)=base
    val+ NativeShapeData(db,category,ignorable,joining)=data
    val+ NativeTextAnalysis(text,doc,items,breaks,graphemes,source_length)=a
  in native_text_range_covered(b,info,ignorable,text,item.start,item.finish) end
fun covered_fallback(b: &Option_vt(Buf) >> _,info: Option(SfntInfo),assets: !NativeTextAssets,
  a: !NativeTextAnalysis,item: NativeTextItem): bool = case+ b of
  | @None_vt() => let prval ()=fold@(b) in false end
  | @Some_vt(file) => let val result=covered_file(file,info,assets,a,item)
    prval ()=fold@(b) in result end
implement font_native_item_covered(f,assets,a,item,face) = case+ f of | @FONT(s) => let
  val result=case+ face of
    | GlyphPrimaryFace() => covered_file(s.file,s.info,assets,a,item)
    | GlyphFallbackFace() => covered_fallback(s.fb_file,s.fb_info,assets,a,item)
  prval ()=fold@(f)
in result end
