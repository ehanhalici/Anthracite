staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"

datatype ComponentOffset = ScaledOffset | UnscaledOffset
typedef ComponentPlacement = @{points=bool,first=int,second=int,mode=ComponentOffset}

typedef GlyphMatrix = @{xx=double, xy=double, yx=double, yy=double}
typedef GlyphTransform = @{matrix=GlyphMatrix, dx=double, dy=double}
typedef GlyphComponent = @{
  glyph=int, placement=ComponentPlacement, matrix=GlyphMatrix, next=int,
  more=bool, use_metrics=bool, round_grid=bool, instructions=bool
}
datavtype ComponentRead = ParsedComponent of GlyphComponent | InvalidComponent

fun glyph_component_read(b: !Buf, glyph: SfntSpan, offset: int, glyphs: int): ComponentRead
fun glyph_identity(): GlyphTransform
fun glyph_matrix_point(matrix: GlyphMatrix, x: double, y: double): @(double, double)
fun glyph_component_transform(parent: GlyphTransform, child: GlyphComponent): GlyphTransform
