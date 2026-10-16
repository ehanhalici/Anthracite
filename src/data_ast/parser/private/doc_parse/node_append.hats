fun node_append(d: !Doc, kind: NodeKind, st: int, en: int, depth: int, aux: int): void =
  doc_push_node(d, kind, st, en, depth, aux)

extern fun at_end_fuel_exhausted(d: !Doc, i: int, re: int): int = "mac#anth_die_int"

fun at_end_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int): int =
  if recfuel > 0 then (
    if ige(i, re) then re
    else if ieq(doc_byte(d, i), CHAR_LF) then i
    else at_end_with_fuel(recfuel - 1, d, iadd(i, 1), re)
  ) else at_end_fuel_exhausted(d, i, re)

fun at_end(d: !Doc, i: int, re: int): int = at_end_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, re)

extern fun skip_sp_fuel_exhausted(d: !Doc, i: int, re: int): int = "mac#anth_die_int"

fun skip_sp_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int): int =
  if recfuel > 0 then (
    if ige(i, re) then i
    else if ieq(doc_byte(d, i), CHAR_SPACE) orelse ieq(doc_byte(d, i), CHAR_TAB) then skip_sp_with_fuel(recfuel - 1, d, iadd(i, 1), re)
    else i
  ) else skip_sp_fuel_exhausted(d, i, re)

fun skip_sp(d: !Doc, i: int, re: int): int = skip_sp_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, re)

extern fun starts_go_fuel_exhausted(d: !Doc, i: int, re: int, s: string, k: int, n: int): int = "mac#anth_die_int"

fun starts_go_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, s: string, k: int, n: int): int =
  if recfuel > 0 then (
    if ige(k, n) then 1
    else if ige(iadd(i, k), re) then 0
    else if ine(doc_byte(d, iadd(i, k)), c_str_byte(s, k)) then 0
    else starts_go_with_fuel(recfuel - 1, d, i, re, s, iadd(k, 1), n)
  ) else starts_go_fuel_exhausted(d, i, re, s, k, n)

fun starts_go(d: !Doc, i: int, re: int, s: string, k: int, n: int): int = starts_go_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, re, s, k, n)

fun starts_at(d: !Doc, i: int, re: int, s: string): bool =
  ieq(starts_go(d, i, re, s, 0, c_strlen(s)), 1)

fun blank_line(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  ige(j, re) orelse ieq(doc_byte(d, j), CHAR_LF)
end

extern fun count_hash_fuel_exhausted(d: !Doc, i: int, re: int, n: int): int = "mac#anth_die_int"

fun count_hash_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, n: int): int =
  if recfuel > 0 then (
    if n >= 6 orelse ige(i, re) orelse ine(doc_byte(d, i), CHAR_HASH) then n
    else count_hash_with_fuel(recfuel - 1, d, iadd(i, 1), re, iadd(n, 1))
  ) else count_hash_fuel_exhausted(d, i, re, n)

fun count_hash(d: !Doc, i: int, re: int, n: int): int = count_hash_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, re, n)

fun is_heading(d: !Doc, i: int, re: int): bool = let
  val sp = skip_sp(d, i, re)
  val hashes = count_hash(d, sp, re, 0)
in
  igt(hashes, 0) andalso ilt(iadd(sp, hashes), re) andalso ieq(doc_byte(d, iadd(sp, hashes)), CHAR_SPACE)
end

fun forward(d: !Doc, i: int, re: int, en: int): int =
  if igt(en, i) then en
  else let
    val e = at_end(d, i, re)
  in
    if ilt(e, re) then iadd(e, 1) else re
  end

extern fun hr_go_fuel_exhausted(d: !Doc, re: int, c: int, k: int, n: int): int = "mac#anth_die_int"

fun hr_go_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, re: int, c: int, k: int, n: int): int =
  if recfuel > 0 then (
    if ige(k, re) orelse ieq(doc_byte(d, k), CHAR_LF) then (if igt(n, 2) then 1 else 0)
    else if ieq(doc_byte(d, k), c) orelse ieq(doc_byte(d, k), CHAR_SPACE) then hr_go_with_fuel(recfuel - 1, d, re, c, iadd(k, 1), (if ieq(doc_byte(d, k), c) then iadd(n, 1) else n))
    else 0
  ) else hr_go_fuel_exhausted(d, re, c, k, n)

fun hr_go(d: !Doc, re: int, c: int, k: int, n: int): bool = ieq(hr_go_with_fuel(airlock_nat(MAX_REC_FUEL), d, re, c, k, n), 1)

fun is_hr(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
  val c = if ilt(j, re) then doc_byte(d, j) else 0
in
  if ieq(c, CHAR_MINUS) orelse ieq(c, CHAR_STAR) orelse ieq(c, CHAR_UNDERSCORE) then hr_go(d, re, c, j, 0) else false
end

fun is_fence(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  if isub(j, i) > 3 then false else starts_at(d, j, re, "```")
end

fun is_task(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
  val c = if ilt(j, re) then doc_byte(d, j) else 0
  val k = skip_sp(d, iadd(j, 1), re)
in
  (ieq(c, CHAR_MINUS) orelse ieq(c, CHAR_STAR) orelse ieq(c, CHAR_PLUS)) andalso ilt(iadd(k, 2), re) andalso ieq(doc_byte(d, k), CHAR_LBRACKET) andalso ieq(doc_byte(d, iadd(k, 2)), CHAR_RBRACKET)
end

fun task_aux(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
  val k = skip_sp(d, iadd(j, 1), re)
  val c = doc_byte(d, iadd(k, 1))
in
  task_aux_code(task_mark_of(c))
end

fun is_ul(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
  val c = if ilt(j, re) then doc_byte(d, j) else 0
  val n = if ilt(iadd(j, 1), re) then doc_byte(d, iadd(j, 1)) else 0
in
  if is_task(d, i, re) then false
  else (ieq(c, CHAR_MINUS) orelse ieq(c, CHAR_STAR) orelse ieq(c, CHAR_PLUS)) andalso (ieq(n, CHAR_SPACE) orelse ieq(n, CHAR_TAB))
end

extern fun ol_digs_fuel_exhausted(d: !Doc, re: int, k: int): int = "mac#anth_die_int"

fun ol_digs_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, re: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, re) then 0
    else if ige(doc_byte(d, k), CHAR_ZERO) andalso ile(doc_byte(d, k), CHAR_NINE) then ol_digs_with_fuel(recfuel - 1, d, re, iadd(k, 1))
    else if ieq(doc_byte(d, k), CHAR_DOT) andalso ilt(iadd(k, 1), re) andalso ieq(doc_byte(d, iadd(k, 1)), CHAR_SPACE) then 1
    else 0
  ) else ol_digs_fuel_exhausted(d, re, k)

fun ol_digs(d: !Doc, re: int, k: int): bool = ieq(ol_digs_with_fuel(airlock_nat(MAX_REC_FUEL), d, re, k), 1)

fun is_ol(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  ilt(j, re) andalso ige(doc_byte(d, j), CHAR_ZERO) andalso ile(doc_byte(d, j), CHAR_NINE) andalso ol_digs(d, re, j)
end

fun is_quote(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  if isub(j, i) > 3 then false else ilt(j, re) andalso ieq(doc_byte(d, j), CHAR_GT)
end

extern fun table_bar_fuel_exhausted(d: !Doc, e: int, k: int): int = "mac#anth_die_int"

fun table_bar_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, e: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, e) then 0
    else if ieq(doc_byte(d, k), CHAR_PIPE) then 1
    else table_bar_with_fuel(recfuel - 1, d, e, iadd(k, 1))
  ) else table_bar_fuel_exhausted(d, e, k)

fun table_bar(d: !Doc, e: int, k: int): int = table_bar_with_fuel(airlock_nat(MAX_REC_FUEL), d, e, k)

fun is_table(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  ilt(j, re) andalso ieq(doc_byte(d, j), CHAR_PIPE)
end

extern fun fndef_colon_fuel_exhausted(d: !Doc, e: int, k: int): int = "mac#anth_die_int"

fun fndef_colon_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, e: int, k: int): int =
  if recfuel > 0 then (
    if ige(iadd(k, 1), e) then 0
    else if ieq(doc_byte(d, k), CHAR_RBRACKET) andalso ieq(doc_byte(d, iadd(k, 1)), CHAR_COLON) then 1
    else fndef_colon_with_fuel(recfuel - 1, d, e, iadd(k, 1))
  ) else fndef_colon_fuel_exhausted(d, e, k)

fun fndef_colon(d: !Doc, e: int, k: int): bool = ieq(fndef_colon_with_fuel(airlock_nat(MAX_REC_FUEL), d, e, k), 1)

fun is_fndef(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  starts_at(d, j, re, "[^") andalso fndef_colon(d, at_end(d, j, re), j)
end

fun ext_tail(d: !Doc, a: int, b: int, s: string): bool = let
  val n = c_strlen(s)
  val p = isub(b, n)
in
  if ilt(p, a) then false else starts_at(d, p, b, s)
end

fun ext_image(d: !Doc, a: int, b: int): bool =
  ext_tail(d, a, b, ".png") orelse ext_tail(d, a, b, ".jpg") orelse ext_tail(d, a, b, ".jpeg") orelse ext_tail(d, a, b, ".bmp")

extern fun find_close_fuel_exhausted(d: !Doc, i: int, re: int, a: int, b: int): int = "mac#anth_die_int"

fun find_close_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, a: int, b: int): int =
  if recfuel > 0 then (
    if iadd(i, 1) >= re then ~1
    else if ieq(doc_byte(d, i), CHAR_LF) then ~1
    else if ieq(doc_byte(d, i), a) andalso ieq(doc_byte(d, iadd(i, 1)), b) then i
    else find_close_with_fuel(recfuel - 1, d, iadd(i, 1), re, a, b)
  ) else find_close_fuel_exhausted(d, i, re, a, b)

fun find_close(d: !Doc, i: int, re: int, a: int, b: int): int = find_close_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, re, a, b)

