staload "data_font/font.sats"
staload "data_font/font_glyph_id.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/font_run.sats"
staload "core_render/render.sats"
typedef FontRunPen = @{x=int,y=int}
typedef FontRunQuad = @{x=double,y=double,w=double,h=double}
typedef FontRunRasterResult = @{status=FontRunStatus,drawn=int}
fun font_run_binding_check(f: !Font,p: !GlyphPositioned(1),binding: FontRunBinding): FontRunStatus
fun font_run_initial(direction: GlyphPositionDirection,extent: FontRunExtent): FontRunPen
fun font_run_origin(direction: GlyphPositionDirection,pen: FontRunPen,position: GlyphPosition): FontRunPen
fun font_run_next(direction: GlyphPositionDirection,pen: FontRunPen,position: GlyphPosition): FontRunPen
fun font_run_quad(origin: FontRunPen,position: GlyphPosition,scale: GlyphScale,g: gmet,x: double,baseline: double): FontRunQuad
fun font_run_raster(f: !Font,r: !Rend,face: FontGlyphFace,glyph: int,scale: GlyphScale,origin: FontRunPen,
  position: GlyphPosition,x: double,baseline: double,color: uint): FontRunRasterResult
fun font_run_walk(f: !Font,r: !Rend,p: !GlyphPositioned(1),binding: FontRunBinding,x: double,baseline: double,
  color: uint,extent: FontRunExtent): FontRunExtent
