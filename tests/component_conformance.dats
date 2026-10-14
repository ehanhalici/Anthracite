#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_component.sats"
staload "font_fixture.sats"

fun component_bytes(flags: int, a: int, c: int): Buf = let
  val b = buf_make(16)
  val () = fixture_put16(b,0,flags)
  val () = fixture_put16(b,2,1)
  val () = fixture_put16(b,4,a)
  val () = fixture_put16(b,6,c)
  val () = buf_set_len(b,16)
in b end

fun read_component(b: !Buf, size: int): ComponentRead =
  glyph_component_read(b,@{offset=0,length=size},0,3)

fun unsigned_points(): int = let
  val b = component_bytes(1,40000,60000)
  val ok = case+ read_component(b,8) of
    | InvalidComponent() => false
    | ParsedComponent(c) => (case+ c.placement of
      | ComponentXY(x,y,mode) => false | ComponentPoints(a,p) => ieq(a,40000) andalso ieq(p,60000))
  val () = buf_free(b)
in if ok then 0 else 1 end

fun unsigned_bytes(): int = let
  val b = component_bytes(0,0,0)
  val () = buf_set(b,4,200)
  val () = buf_set(b,5,250)
  val ok = case+ read_component(b,6) of
    | InvalidComponent() => false
    | ParsedComponent(c) => (case+ c.placement of
      | ComponentXY(x,y,mode) => false | ComponentPoints(a,p) => ieq(a,200) andalso ieq(p,250))
  val () = buf_free(b)
in if ok then 0 else 1 end

fun signed_bytes(): int = let
  val b = component_bytes(2,0,0)
  val () = buf_set(b,4,200)
  val () = buf_set(b,5,250)
  val ok = case+ read_component(b,6) of
    | InvalidComponent() => false
    | ParsedComponent(c) => (case+ c.placement of
      | ComponentPoints(a,p) => false | ComponentXY(x,y,mode) => ieq(x,~56) andalso ieq(y,~6))
  val () = buf_free(b)
in if ok then 0 else 1 end

fun transformed_offset(flags: int, dx: double, dy: double): int = let
  val b = component_bytes(flags,100,200)
  val () = fixture_put16(b,8,8192)
  val ok = case+ read_component(b,10) of
    | InvalidComponent() => false
    | ParsedComponent(c) => let
        val parent = @{matrix= @{xx=0.0,xy= ~1.0,yx=1.0,yy=0.0},dx=10.0,dy=20.0}
        val placed = glyph_component_transform(parent,c)
      in placed.dx = dx andalso placed.dy = dy end
  val () = buf_free(b)
in if ok then 0 else 1 end

fun off_diagonal(): int = let
  val b = component_bytes(131,0,0)
  val () = fixture_put16(b,8,8192)
  val () = fixture_put16(b,10,8192)
  val () = fixture_put16(b,12,61440)
  val () = fixture_put16(b,14,24576)
  val ok = case+ read_component(b,16) of
    | InvalidComponent() => false
    | ParsedComponent(c) => let val @(x,y) = glyph_matrix_point(c.matrix,2.0,4.0)
      in x = 0.0 andalso y = 7.0 end
  val () = buf_free(b)
in if ok then 0 else 1 end

fun invalid_component(flags: int, size: int): int = let
  val b = component_bytes(flags,0,0)
  val ok = case+ read_component(b,size) of | InvalidComponent() => true | ParsedComponent(c) => false
  val () = buf_free(b)
in if ok then 0 else 1 end

fun run(): int = let
  val points = unsigned_points() + unsigned_bytes() + signed_bytes()
  val transforms = transformed_offset(2059,~90.0,70.0) + transformed_offset(4107,~190.0,120.0)
    + transformed_offset(11,~190.0,120.0) + off_diagonal()
  val invalid = invalid_component(75,16) + invalid_component(131,15) + invalid_component(3,7)
  val () = println!("event=component_conformance point_errors=",points,
    " transform_errors=",transforms," invalid_errors=",invalid)
in points + transforms + invalid end

implement main0() = if igt(run(),0) then exit(1) else ()
