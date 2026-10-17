fun mark_hidden_lines_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), hidden: !Buf, line: int, finish: int
): void =
  if recursion_fuel_available(recfuel) then (
    if line >= finish then ()
    else let
      val () = buf_set(hidden, line, 1)
    in
      mark_hidden_lines_with_fuel(recfuel - 1, hidden, iadd(line, 1), finish)
    end
  ) else ()
