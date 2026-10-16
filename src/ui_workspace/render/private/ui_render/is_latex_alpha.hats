fun is_latex_alpha(b: int): bool =
  (ige(b, 65) andalso ile(b, 90)) orelse (ige(b, 97) andalso ile(b, 122))

fun is_math_space(b: int): bool = ieq(b, 32) orelse ieq(b, 9)

fun math_sym_greek_lo1(cmd: string): string =
  if ieq(c_strcmp(cmd, "alpha"), 0) then "α"
  else if ieq(c_strcmp(cmd, "beta"), 0) then "β"
  else if ieq(c_strcmp(cmd, "gamma"), 0) then "γ"
  else if ieq(c_strcmp(cmd, "delta"), 0) then "δ"
  else if ieq(c_strcmp(cmd, "epsilon"), 0) then "ε"
  else if ieq(c_strcmp(cmd, "zeta"), 0) then "ζ"
  else if ieq(c_strcmp(cmd, "eta"), 0) then "η"
  else if ieq(c_strcmp(cmd, "theta"), 0) then "θ"
  else if ieq(c_strcmp(cmd, "iota"), 0) then "ι"
  else if ieq(c_strcmp(cmd, "kappa"), 0) then "κ"
  else if ieq(c_strcmp(cmd, "lambda"), 0) then "λ"
  else if ieq(c_strcmp(cmd, "mu"), 0) then "μ"
  else ""

fun math_sym_greek_lo2(cmd: string): string =
  if ieq(c_strcmp(cmd, "nu"), 0) then "ν"
  else if ieq(c_strcmp(cmd, "xi"), 0) then "ξ"
  else if ieq(c_strcmp(cmd, "pi"), 0) then "π"
  else if ieq(c_strcmp(cmd, "rho"), 0) then "ρ"
  else if ieq(c_strcmp(cmd, "sigma"), 0) then "σ"
  else if ieq(c_strcmp(cmd, "tau"), 0) then "τ"
  else if ieq(c_strcmp(cmd, "upsilon"), 0) then "υ"
  else if ieq(c_strcmp(cmd, "phi"), 0) then "φ"
  else if ieq(c_strcmp(cmd, "chi"), 0) then "χ"
  else if ieq(c_strcmp(cmd, "psi"), 0) then "ψ"
  else if ieq(c_strcmp(cmd, "omega"), 0) then "ω"
  else ""

fun math_sym_greek_up(cmd: string): string =
  if ieq(c_strcmp(cmd, "Gamma"), 0) then "Γ"
  else if ieq(c_strcmp(cmd, "Delta"), 0) then "Δ"
  else if ieq(c_strcmp(cmd, "Theta"), 0) then "Θ"
  else if ieq(c_strcmp(cmd, "Lambda"), 0) then "Λ"
  else if ieq(c_strcmp(cmd, "Xi"), 0) then "Ξ"
  else if ieq(c_strcmp(cmd, "Pi"), 0) then "Π"
  else if ieq(c_strcmp(cmd, "Sigma"), 0) then "Σ"
  else if ieq(c_strcmp(cmd, "Phi"), 0) then "Φ"
  else if ieq(c_strcmp(cmd, "Psi"), 0) then "Ψ"
  else if ieq(c_strcmp(cmd, "Omega"), 0) then "Ω"
  else ""

fun math_sym_ops(cmd: string): string =
  if ieq(c_strcmp(cmd, "sum"), 0) then "∑"
  else if ieq(c_strcmp(cmd, "prod"), 0) then "∏"
  else if ieq(c_strcmp(cmd, "int"), 0) then "∫"
  else if ieq(c_strcmp(cmd, "sqrt"), 0) then "√"
  else if ieq(c_strcmp(cmd, "infty"), 0) then "∞"
  else if ieq(c_strcmp(cmd, "pm"), 0) then "±"
  else if ieq(c_strcmp(cmd, "mp"), 0) then "∓"
  else if ieq(c_strcmp(cmd, "times"), 0) then "×"
  else if ieq(c_strcmp(cmd, "div"), 0) then "÷"
  else if ieq(c_strcmp(cmd, "cdot"), 0) then "·"
  else if ieq(c_strcmp(cmd, "approx"), 0) then "≈"
  else if ieq(c_strcmp(cmd, "neq"), 0) orelse ieq(c_strcmp(cmd, "ne"), 0) then "≠"
  else if ieq(c_strcmp(cmd, "leq"), 0) orelse ieq(c_strcmp(cmd, "le"), 0) then "≤"
  else if ieq(c_strcmp(cmd, "geq"), 0) orelse ieq(c_strcmp(cmd, "ge"), 0) then "≥"
  else if ieq(c_strcmp(cmd, "over"), 0) then " / "
  else if ieq(c_strcmp(cmd, "bar"), 0) then "¯"
  else ""

fun math_sym_rel(cmd: string): string =
  if ieq(c_strcmp(cmd, "to"), 0) orelse ieq(c_strcmp(cmd, "rightarrow"), 0) then "→"
  else if ieq(c_strcmp(cmd, "leftarrow"), 0) then "←"
  else if ieq(c_strcmp(cmd, "Rightarrow"), 0) then "⇒"
  else if ieq(c_strcmp(cmd, "Leftarrow"), 0) then "⇐"
  else if ieq(c_strcmp(cmd, "iff"), 0) orelse ieq(c_strcmp(cmd, "Leftrightarrow"), 0) then "⇔"
  else if ieq(c_strcmp(cmd, "in"), 0) then "∈"
  else if ieq(c_strcmp(cmd, "notin"), 0) then "∉"
  else if ieq(c_strcmp(cmd, "partial"), 0) then "∂"
  else if ieq(c_strcmp(cmd, "nabla"), 0) then "∇"
  else if ieq(c_strcmp(cmd, "forall"), 0) then "∀"
  else if ieq(c_strcmp(cmd, "exists"), 0) then "∃"
  else if ieq(c_strcmp(cmd, "quad"), 0) then "  "
  else if ieq(c_strcmp(cmd, "qquad"), 0) then "    "
  else ""

fun math_cmd_lookup(cmd: string): string = let
  val s1 = math_sym_greek_lo1(cmd)
in
  if igt(c_strlen(s1), 0) then s1
  else let
    val s2 = math_sym_greek_lo2(cmd)
  in
    if igt(c_strlen(s2), 0) then s2
    else let
      val s3 = math_sym_greek_up(cmd)
    in
      if igt(c_strlen(s3), 0) then s3
      else let
        val s4 = math_sym_ops(cmd)
      in
        if igt(c_strlen(s4), 0) then s4 else math_sym_rel(cmd)
      end
    end
  end
end

fun math_char_to_sup(c: int): string =
  if ieq(c, 48) then "⁰" else if ieq(c, 49) then "¹"
  else if ieq(c, 50) then "²" else if ieq(c, 51) then "³"
  else if ieq(c, 52) then "⁴" else if ieq(c, 53) then "⁵"
  else if ieq(c, 54) then "⁶" else if ieq(c, 55) then "⁷"
  else if ieq(c, 56) then "⁸" else if ieq(c, 57) then "⁹"
  else if ieq(c, 43) then "⁺" else if ieq(c, 45) then "⁻"
  else if ieq(c, 61) then "⁼" else if ieq(c, 40) then "⁽"
  else if ieq(c, 41) then "⁾" else if ieq(c, 110) then "ⁿ"
  else if ieq(c, 105) then "ⁱ" else if ieq(c, 120) then "ˣ"
  else ""

fun math_char_to_sub(c: int): string =
  if ieq(c, 48) then "₀" else if ieq(c, 49) then "₁"
  else if ieq(c, 50) then "₂" else if ieq(c, 51) then "₃"
  else if ieq(c, 52) then "₄" else if ieq(c, 53) then "₅"
  else if ieq(c, 54) then "₆" else if ieq(c, 55) then "₇"
  else if ieq(c, 56) then "₈" else if ieq(c, 57) then "₉"
  else if ieq(c, 43) then "₊" else if ieq(c, 45) then "₋"
  else if ieq(c, 61) then "₌" else if ieq(c, 105) then "ᵢ"
  else if ieq(c, 106) then "ⱼ" else if ieq(c, 107) then "ₖ"
  else if ieq(c, 110) then "ₙ" else if ieq(c, 109) then "ₘ"
  else ""

fun scan_alpha_end_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then p
    else if is_latex_alpha(doc_byte(d, p)) then scan_alpha_end_with_fuel(recfuel - 1, d, iadd(p, 1), en)
    else p
  ) else p

fun scan_alpha_end(d: !Doc, p: int, en: int): int =
  scan_alpha_end_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, en)

fun math_skip_sp_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then p
    else if is_math_space(doc_byte(d, p)) then math_skip_sp_with_fuel(recfuel - 1, d, iadd(p, 1), en)
    else p
  ) else p

fun math_skip_sp(d: !Doc, p: int, en: int): int =
  math_skip_sp_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, en)

fun find_brace_close_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, depth: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then en
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, 123) then find_brace_close_with_fuel(recfuel - 1, d, iadd(p, 1), en, iadd(depth, 1))
      else if ieq(b, 125) then (
        if ile(depth, 1) then p
        else find_brace_close_with_fuel(recfuel - 1, d, iadd(p, 1), en, isub(depth, 1))
      ) else find_brace_close_with_fuel(recfuel - 1, d, iadd(p, 1), en, depth)
    end
  ) else en

fun find_brace_close(d: !Doc, p: int, en: int): int =
  find_brace_close_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, en, 1)

fun convert_sup_run_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, out: &Buf >> _
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then ()
    else let
      val b = doc_byte(d, p)
      val s = math_char_to_sup(b)
      val () = if igt(c_strlen(s), 0) then buffer_append_string(out, s) else (buffer_append_string(out, "^"); buf_push(out, b))
    in
      convert_sup_run_with_fuel(recfuel - 1, d, iadd(p, 1), en, out)
    end
  ) else ()

fun convert_sup(d: !Doc, p: int, en: int, out: &Buf >> _): int =
  if ige(p, en) then p
  else if ieq(doc_byte(d, p), CHAR_LBRACE) then let
    val close = find_brace_close(d, iadd(p, 1), en)
    val () = convert_sup_run_with_fuel(airlock_nat(MAX_REC_FUEL), d, iadd(p, 1), close, out)
  in
    if ilt(close, en) then iadd(close, 1) else close
  end else let
    val b = doc_byte(d, p)
    val s = math_char_to_sup(b)
    val () = if igt(c_strlen(s), 0) then buffer_append_string(out, s) else (buffer_append_string(out, "^"); buf_push(out, b))
  in
    iadd(p, 1)
  end

fun convert_sub_run_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, out: &Buf >> _
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then ()
    else let
      val b = doc_byte(d, p)
      val s = math_char_to_sub(b)
      val () = if igt(c_strlen(s), 0) then buffer_append_string(out, s) else (buffer_append_string(out, "_"); buf_push(out, b))
    in
      convert_sub_run_with_fuel(recfuel - 1, d, iadd(p, 1), en, out)
    end
  ) else ()
