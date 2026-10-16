fun skip_ws_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), q: !Buf, p: int, n: int): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(p, n) andalso ile(buf_get(q, p), CHAR_SPACE) then
      skip_ws_with_fuel(recfuel - 1, q, iadd(p, 1), n)
    else p
  ) else p
