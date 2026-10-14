#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/gl.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_component.sats"
staload "data_text/text_source.sats"



(* Composing TrueType component outlines. *)
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_outline_simple.sats"
staload "data_font/private/font_outline_compound.sats"

extern fun outline_exhausted(): void = "mac#anth_die_void"

fun outline_span(f: !Font, gid: int): SfntSpan = let
  val start = loca_at(f,gid)
  val finish = loca_at(f,iadd(gid,1))
in @{offset=iadd(f_get_glyf_off(f),start),length=isub(finish,start)} end

fun translate_points {n:nat} .<n>. (
  n: int(n), f: !Font, i: int, dx: int, dy: int
): void =
  if n = 0 then () else let
    val () = pt_set(f,i,iadd(pt_x(f,i),dx),iadd(pt_y(f,i),dy),pt_on(f,i))
  in translate_points(n-1,f,iadd(i,1),dx,dy) end

fun align_component(f: !Font, placement: ComponentPlacement, parent: int, child: int): void =
  case+ placement of
  | ComponentXY(x,y,mode) => ()
  | ComponentPoints(a,b) => let
      val finish = f_get_npts(f)
      val pa = iadd(parent,a)
      val pb = iadd(child,b)
    in if ilt(pa,parent) orelse ige(pa,child) orelse ilt(pb,child) orelse ige(pb,finish)
      then outline_exhausted()
      else translate_points(airlock_nat(isub(finish,child)),f,child,
        isub(pt_x(f,pa),pt_x(f,pb)),isub(pt_y(f,pa),pt_y(f,pb))) end

extern fun load_glyph_exh(f: !Font, gid: int, xf: GlyphTransform, depth: int): void = "mac#anth_die_void"

fun load_glyph {fuel:nat} .<fuel>. (
  fuel: int(fuel), f: !Font, gid: int, xf: GlyphTransform, depth: int
): void =
  if fuel = 0 then load_glyph_exh(f,gid,xf,depth)
  else if depth > 8 orelse ilt(gid,0) orelse ige(gid,f_get_nglyph(f)) then ()
  else let
    val span = outline_span(f,gid)
    val contours = file_i16(f,span.offset)
  in if ieq(span.length,0) then ()
    else if ilt(span.length,10) then outline_exhausted()
    else if igt(contours,0) then decode_simple(f,iadd(span.offset,10),contours,
      xf.dx,xf.dy,xf.matrix.xx,xf.matrix.yy,xf.matrix.xy,xf.matrix.yx)
    else if ilt(contours,0) then comp_loop(fuel-1,f,span,10,xf,depth,f_get_npts(f))
    else () end

and comp_loop {fuel:nat} .<fuel>. (
  fuel: int(fuel), f: !Font, span: SfntSpan, p: int,
  xf: GlyphTransform, depth: int, parent: int
): void =
  if fuel = 0 then outline_exhausted() else case+ component_at(f,span,p) of
  | InvalidComponent() => outline_exhausted()
  | ParsedComponent(child) => let
      val () = comp_place(fuel-1,f,child,xf,depth,parent)
    in if child.more then comp_loop(fuel-1,f,span,child.next,xf,depth,parent) else () end

and comp_place {fuel:nat} .<fuel>. (
  fuel: int(fuel), f: !Font, child: GlyphComponent, parent_xf: GlyphTransform,
  depth: int, parent: int
): void =
  if fuel = 0 then outline_exhausted() else let
    val base = f_get_npts(f)
    val xf = glyph_component_transform(parent_xf,child)
    val () = load_glyph(fuel-1,f,child.glyph,xf,iadd(depth,1))
  in align_component(f,child.placement,parent,base) end

implement load_ttf_outline(f, gid) = let
  val () = f_set_npts(f, 0)
  val () = f_set_nends(f, 0)
  val () = f_set_nedges(f, 0)
  val () = load_glyph(airlock_nat(MAX_REC_FUEL),f,gid,glyph_identity(),0)
in
end
