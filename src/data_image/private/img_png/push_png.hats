fun push_png_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: &Buf >> _, i: int): void =
  if recfuel > 0 then (
    if ige(i, 69) then ()
    else let
      val () = buf_push(b, png_byte(i))
    in
      push_png_with_fuel(recfuel - 1, b, iadd(i, 1))
    end
  ) else push_png_fuel_exhausted(b, i)

fun push_png(b: &Buf >> _, i: int): void = push_png_with_fuel(airlock_nat(MAX_REC_FUEL), b, i)

implement make_png() = let
  var pb = buf_make(80)
  val () = push_png(pb, 0)
in
  pb
end
