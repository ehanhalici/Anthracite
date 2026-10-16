#ifndef ANTHRACITE_JPEG_COLOR_HATS
#define ANTHRACITE_JPEG_COLOR_HATS

datatype JpegColorSpace =
  | JpegGray of () | JpegRGB of () | JpegYCbCr of ()
  | JpegCMYK of () | JpegYCCK of ()

fun jpeg_has_rgb_ids(meta: !Buf): bool =
  ieq(comp_get(meta, 0, COMP_ID), char2int0('R')) andalso
  ieq(comp_get(meta, 1, COMP_ID), char2int0('G')) andalso
  ieq(comp_get(meta, 2, COMP_ID), char2int0('B'))

fun jpeg_color_space(meta: !Buf): JpegColorSpace = let
  val count = buf_get32(meta, META_NCOMP)
  val adobe = buf_get32(meta, META_APP14)
  val jfif = buf_get32(meta, META_JFIF)
in
  if ieq(count, 1) then JpegGray()
  else if ieq(count, JPG_MAX_COMPONENTS) then
    (if ieq(adobe, JPG_ADOBE_CMYK_OR_RGB) then JpegCMYK()
     else if ieq(adobe, JPG_ADOBE_YCCK) then JpegYCCK() else JpegYCbCr())
  else if jpeg_has_rgb_ids(meta) orelse (ieq(adobe, JPG_ADOBE_CMYK_OR_RGB) andalso ieq(jfif, 0)) then JpegRGB()
  else JpegYCbCr()
end

fun jpeg_write_rgb(out: !Buf, offset: int, red: int, green: int, blue: int): void = let
  val () = buf_set(out, offset, red)
  val () = buf_set(out, iadd(offset, 1), green)
  val () = buf_set(out, iadd(offset, 2), blue)
  val () = buf_set(out, iadd(offset, 3), 255)
in () end

fun jpeg_ycck_pixel(out: !Buf, offset: int, y: int, cb: int, cr: int, black: int): void = let
  val () = color_ycbcr_one(out, offset, y, cb, cr)
  val red = blinn_8x8(isub(255, buf_get(out, offset)), black)
  val green = blinn_8x8(isub(255, buf_get(out, iadd(offset, 1))), black)
  val blue = blinn_8x8(isub(255, buf_get(out, iadd(offset, 2))), black)
in
  jpeg_write_rgb(out, offset, red, green, blue)
end

fun jpeg_color_pixel(out: !Buf, offset: int, p0: int, p1: int, p2: int, p3: int, color: JpegColorSpace): void =
  case+ color of
  | JpegGray() => jpeg_write_rgb(out, offset, p0, p0, p0)
  | JpegRGB() => jpeg_write_rgb(out, offset, p0, p1, p2)
  | JpegYCbCr() => color_ycbcr_one(out, offset, p0, p1, p2)
  | JpegCMYK() => jpeg_write_rgb(out, offset, blinn_8x8(p0, p3), blinn_8x8(p1, p3), blinn_8x8(p2, p3))
  | JpegYCCK() => jpeg_ycck_pixel(out, offset, p0, p1, p2, p3)

extern fun jpeg_color_fuel_exhausted(): void = "mac#anth_die_void"

fun jpeg_render_color_row {fuel:nat} .<fuel>. (
  fuel: int(fuel), out: !Buf, offset: int,
  plane0: !Buf, plane1: !Buf, plane2: !Buf, plane3: !Buf,
  width: int, color: JpegColorSpace, column: int
): void =
  if fuel > 0 then (
    if ilt(column, width) then let
      val p0 = buf_get(plane0, column) and p1 = buf_get(plane1, column)
      val p2 = buf_get(plane2, column) and p3 = buf_get(plane3, column)
      val pixel_offset = iadd(offset, imul(column, JPG_COLOR_CHANNELS))
      val () = jpeg_color_pixel(out, pixel_offset, p0, p1, p2, p3, color)
    in
      jpeg_render_color_row(fuel - 1, out, offset, plane0, plane1, plane2, plane3, width, color, iadd(column, 1))
    end else ()
  ) else jpeg_color_fuel_exhausted()

#endif
