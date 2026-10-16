#include "data_font/text/font_text_internal.hats"
staload "data_font/native/shape/native_shape_types.sats"
staload "data_font/native/ownership/font_source_grapheme.sats"
staload "data_text/grapheme/source_grapheme.sats"
fun query{active:bool}(state: !option_vt(FontTextSession,active),b: !Buf,n: int,at: int): Option_vt(SourceBoundaries) =
  case+ state of | None_vt() => None_vt() | Some_vt(session) => let
    val+ FontTextSession(assets,cache,p,f,m)=session
    val+ NativeTextAssets(aux,words,lines,east)=assets
    val+ NativeTextAux(base,scripts,bidi,brackets,mirrors)=aux
    val+ NativeTextBase(shape,normalization,modifiers)=base
    val+ NativeShapeData(db,category,ignorable,joining)=shape
  in Some_vt(source_grapheme_query(db,b,n,at)) end
implement font_source_grapheme_query(f,b,n,at) = let
  val state=font_text_take(f) val result=query(state,b,n,at)
  val ()=font_text_put(f,state)
in result end
