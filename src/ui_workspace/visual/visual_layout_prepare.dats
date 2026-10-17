#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/doc_visual.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_ast/layout/layout_internal.sats"
staload "data_font/resources/font.sats"
staload "core_render/render.sats"
staload "data_font/text/font_text.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/native/ownership/private/font_native_owner.sats"
staload "data_font/resources/private/font_storage.sats"
staload "data_font/resources/font_document_metrics.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/visual/visual_layout.sats"
fun key(f: !Font,d: !Doc,width: int,mode: ViewMode): VisualKey = let
  val p=font_native_current(f,GlyphPrimaryFace()) val a=font_native_current(f,GlyphFallbackFace())
  val metrics=font_document_metrics(f)
in @{version=doc_layout_version(d),width=imax(1,width),px=font_get_px(f),height=font_document_line_height(f,font_line_h(f)),ascent=metrics.ascent,primary=p.font,fallback=a.font,
  primaryGeneration=p.generation,fallbackGeneration=a.generation,
  projection=if is_view_read(mode) then VisualRendered() else VisualSource()} end
fun fresh(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode): void = let
  var rows=visual_projection_make(d,key(f,d,width,mode)) val ()=visual_wrap_fill(f,r,d,rows)
  val+ ~VisualRows(t,m,l,data,n,old)=rows
  val ()=doc_visual_put(d,Some_vt(VisualRows(t,m,l,data,n,key(f,d,width,mode))))
in doc_layout_cache_store(d,~1,0,0,~1,doc_get_wrap(d)) end
implement visual_layout_prepare(f,r,d,width,mode) =
  if not(font_text_active(f)) then () else let val state=doc_visual_take(d)
    val hit=case+ state of | None_vt() => false | Some_vt(rows) => visual_rows_matches(rows,key(f,d,width,mode))
    val ()=doc_visual_put(d,state)
  in if hit then () else fresh(f,r,d,width,mode) end
