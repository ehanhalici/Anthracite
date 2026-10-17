#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"

fun has(flags: int, mask: int): bool = ieq(imod(idiv(flags,mask),2),1)
fun number(v: int): double = g0int2float_int_double(v)
fun f214(b: !Buf, p: int): double = number(sfnt_signed16(b,p)) / 16384.0

fun matrix_size(flags: int): int =
  if has(flags,8) then 2 else if has(flags,64) then 4 else if has(flags,128) then 8 else 0

fun matrix_flags_valid(flags: int): bool = let
  val count = iadd(iadd(if has(flags,8) then 1 else 0,if has(flags,64) then 1 else 0),
    if has(flags,128) then 1 else 0)
in ile(count,1) end

fun matrix_read(b: !Buf, p: int, flags: int): GlyphMatrix =
  if has(flags,8) then let val s = f214(b,p) in @{xx=s,xy=0.0,yx=0.0,yy=s} end
  else if has(flags,64) then @{xx=f214(b,p),xy=0.0,yx=0.0,yy=f214(b,iadd(p,2))}
  else if has(flags,128) then
    @{xx=f214(b,p),xy=f214(b,iadd(p,4)),yx=f214(b,iadd(p,2)),yy=f214(b,iadd(p,6))}
  else @{xx=1.0,xy=0.0,yx=0.0,yy=1.0}

fun component_arg(b: !Buf, p: int, flags: int): int = let
  val value = if has(flags,1) then sfnt_be16(b,p) else buf_get(b,p)
  val modulus = if has(flags,1) then WORD16_MODULUS else 256
in if has(flags,2) andalso ige(value,idiv(modulus,2)) then isub(value,modulus) else value end

fun offset_mode_of(flags: int): ComponentOffset =
  if has(flags,2048) andalso not(has(flags,4096)) then ScaledOffset() else UnscaledOffset()

fun placement_of(flags: int, arg1: int, arg2: int): ComponentPlacement =
  if has(flags,2) then ComponentXY(arg1,arg2,offset_mode_of(flags))
  else ComponentPoints(arg1,arg2)

fun component_record(b: !Buf, span: SfntSpan, offset: int, flags: int): GlyphComponent = let
  val at = iadd(span.offset,offset)
  val step = if has(flags,1) then 2 else 1
  val q = iadd(at,iadd(4,imul(step,2)))
  val a = component_arg(b,iadd(at,4),flags)
  val c = component_arg(b,iadd(at,iadd(4,step)),flags)
in @{glyph=sfnt_be16(b,iadd(at,2)),placement=placement_of(flags,a,c),matrix=matrix_read(b,q,flags),
  next=iadd(offset,iadd(4,iadd(imul(step,2),matrix_size(flags)))),more=has(flags,32),
  use_metrics=has(flags,512),round_grid=has(flags,4),instructions=has(flags,256)} end

implement glyph_component_read(b,span,p,glyphs) =
  if not(sfnt_contains(span,p,4)) then InvalidComponent() else let
    val at = iadd(span.offset,p)
    val flags = sfnt_be16(b,at)
    val bytes = iadd(4,iadd(if has(flags,1) then 4 else 2,matrix_size(flags)))
  in if not(matrix_flags_valid(flags)) orelse not(sfnt_contains(span,p,bytes))
      orelse ige(sfnt_be16(b,iadd(at,2)),glyphs) then InvalidComponent()
    else ParsedComponent(component_record(b,span,p,flags)) end

implement glyph_identity() = @{matrix= @{xx=1.0,xy=0.0,yx=0.0,yy=1.0},dx=0.0,dy=0.0}
implement glyph_matrix_point(m,x,y) = @(m.xx*x + m.xy*y,m.yx*x + m.yy*y)

fun matrix_product(a: GlyphMatrix, b: GlyphMatrix): GlyphMatrix =
  @{xx=a.xx*b.xx + a.xy*b.yx,xy=a.xx*b.xy + a.xy*b.yy,
    yx=a.yx*b.xx + a.yy*b.yx,yy=a.yx*b.xy + a.yy*b.yy}

fun component_offset(child: GlyphComponent): @(double,double) = case+ child.placement of
  | ComponentPoints(parent,point) => @(0.0,0.0)
  | ComponentXY(x,y,mode) => (case+ mode of
    | UnscaledOffset() => @(number(x),number(y))
    | ScaledOffset() => glyph_matrix_point(child.matrix,number(x),number(y)))

implement glyph_component_transform(parent,child) = let
  val @(x,y) = component_offset(child)
  val @(dx,dy) = glyph_matrix_point(parent.matrix,x,y)
in @{matrix=matrix_product(parent.matrix,child.matrix),dx=parent.dx+dx,dy=parent.dy+dy} end
