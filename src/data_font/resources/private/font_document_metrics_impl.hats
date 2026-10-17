fun document_scaled(value: int,px: int,units: int): int =
  idiv(iadd(imul(imax(0,value),px),isub(units,1)),units)
fun document_face(info: SfntMetadata,px: int): FontDocumentMetrics =
  if not(info.present) then @{ascent=0,descent=0,height=0}
  else let val face=info.info val a=document_scaled(face.ascender,px,face.units)
    val d=document_scaled(isub(0,face.descender),px,face.units)
    val gap=document_scaled(face.line_gap,px,face.units)
  in @{ascent=a,descent=d,height=iadd(iadd(a,d),gap)} end
fun document_base(p: FontDocumentMetrics,asc: int,height: int): FontDocumentMetrics =
  if igt(p.height,0) then p else @{ascent=asc,descent=imax(0,isub(height,asc)),height=height}
implement font_document_metrics(f) = case+ f of | @FONT(s) => let
  val p=document_face(s.info,s.px) val a=document_face(s.fb_info,s.px)
  val base=document_base(p,s.asc_px,s.line_h)
  val ascent=imax(base.ascent,a.ascent) val descent=imax(base.descent,a.descent)
  val height=imax(iadd(ascent,descent),imax(base.height,a.height))
  prval ()=fold@(f)
in @{ascent=ascent,descent=descent,height=height} end
