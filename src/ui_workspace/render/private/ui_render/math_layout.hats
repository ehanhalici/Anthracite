(* TeX benzeri matematik yerleşimi: kaynak baytlarından doğrudan ölçer ve çizer.
   Tek geçişli ölçüm/çizim: Toggle `paint` kapalıysa yalnızca kutu ölçülerini verir.
   Kutu: w genişlik, a taban çizgisinin üstü, d altı. y ekseni aşağı büyür. *)

macdef MATH_BACKSLASH = 92
macdef MATH_CARET = 94
macdef MATH_UNDERSCORE = 95
macdef MATH_LBRACKET = 91
macdef MATH_RBRACKET = 93
macdef MATH_DOT = 46
macdef MATH_MAX_LEVEL = 6
macdef MATH_ATOM_BUFFER_BYTES = 64
macdef MATH_RAW_BUFFER_BYTES = 256
macdef MATH_NAME_BUFFER_BYTES = 32
macdef MATH_BLOCK_VERTICAL_PADDING_PIXELS = 10

typedef MBox = @{w=int, a=int, d=int}
typedef MItem = @{e=int, w=int, a=int, d=int, k=int}
typedef MCtx = @{sn=int, sd=int, x=int, y=int, lh=int, asc=int, disp=int, lvl=int}
typedef MScr = @{us=int, ue=int, ds=int, de=int, nx=int}
typedef MPlace = @{bx=int, ux=int, uy=int, vx=int, vy=int, w=int, a=int, d=int}

fun mbox_make(w: int, a: int, d: int): MBox = @{w=w, a=a, d=d}

fun mitem_of(e: int, bx: MBox, k: int): MItem = @{e=e, w=bx.w, a=bx.a, d=bx.d, k=k}

fun mitem_zero(e: int): MItem = @{e=e, w=0, a=0, d=0, k=0}

fun mpx(c: MCtx, v: int): int = idiv(imul(v, c.sn), c.sd)

fun mctx_at(c: MCtx, x: int, y: int): MCtx =
  @{sn=c.sn, sd=c.sd, x=x, y=y, lh=c.lh, asc=c.asc, disp=c.disp, lvl=c.lvl}

fun mctx_sub(c: MCtx, sn: int, sd: int, x: int, y: int): MCtx = let
  val n = imul(c.sn, sn)
  val m = imul(c.sd, sd)
  val small = ilt(imul(n, 2), m)
in
  @{sn=(if small then 1 else n), sd=(if small then 2 else m), x=x, y=y,
    lh=c.lh, asc=c.asc, disp=c.disp, lvl=iadd(c.lvl, 1)}
end

(* ---- Atomlar ---- *)

fun matom_buf(f: !Font, r: !Rend, txt: !Buf, n: int, c: MCtx, paint: Toggle): MBox = let
  val w = idiv(imul(font_width_buf(f, r, txt, n), c.sn), c.sd)
  val a = mpx(c, c.asc)
  val dd = mpx(c, isub(c.lh, c.asc))
  val () = if is_on(paint) then seen_int(font_draw_scaled_buf(f, r, c.x, isub(c.y, a), txt, n, col_math(), c.sn, c.sd)) else ()
in
  mbox_make(w, a, dd)
end

fun matom_str(f: !Font, r: !Rend, s: string, c: MCtx, paint: Toggle): MBox = let
  var tb = buf_make(MATH_ATOM_BUFFER_BYTES)
  val () = buffer_append_string(tb, s)
  val n = buf_len(tb)
  val box = matom_buf(f, r, tb, n, c, paint)
  val () = buf_free(tb)
in
  box
end

fun math_is_binary_op(b: int): bool =
  ieq(b, 43) orelse ieq(b, 45) orelse ieq(b, 61) orelse ieq(b, 60) orelse ieq(b, 62)

fun matom_doc(f: !Font, r: !Rend, d: !Doc, p: int, e: int, c: MCtx, paint: Toggle): MBox = let
  var tb = buf_make(MATH_ATOM_BUFFER_BYTES)
  val n = doc_slice_buf(d, p, e, tb, 31)
  val () = buf_set_len(tb, n)
  val pad = if ieq(isub(e, p), 1) andalso math_is_binary_op(doc_byte(d, p)) then mpx(c, imax(2, idiv(c.lh, 6))) else 0
  val box = matom_buf(f, r, tb, n, mctx_at(c, iadd(c.x, pad), c.y), paint)
  val () = buf_free(tb)
in
  mbox_make(iadd(box.w, imul(pad, 2)), box.a, box.d)
end

fun mraw_doc(f: !Font, r: !Rend, d: !Doc, a: int, b: int, c: MCtx, paint: Toggle): MBox = let
  var tb = buf_make(MATH_RAW_BUFFER_BYTES)
  val n = doc_slice_buf(d, a, b, tb, 255)
  val () = buf_set_len(tb, n)
  val box = matom_buf(f, r, tb, n, c, paint)
  val () = buf_free(tb)
in
  box
end

(* ---- Kaynak tarama yardımcıları ---- *)

fun mtoken_end(d: !Doc, p: int, b: int): int =
  if ige(p, b) then p
  else if ieq(doc_byte(d, p), MATH_BACKSLASH) then let
    val ce = scan_alpha_end(d, iadd(p, 1), b)
  in
    if igt(ce, iadd(p, 1)) then ce else imin(b, doc_advance_cps(d, iadd(p, 1), b, 1))
  end
  else doc_advance_cps(d, p, b, 1)

(* (içerik başı, içerik sonu, sonraki konum) *)
fun moperand(d: !Doc, p: int, b: int): @(int, int, int) = let
  val q = math_skip_sp(d, p, b)
in
  if ige(q, b) then @(q, q, q)
  else if ieq(doc_byte(d, q), CHAR_LBRACE) then let
    val close = find_brace_close(d, iadd(q, 1), b)
  in
    @(iadd(q, 1), close, (if ilt(close, b) then iadd(close, 1) else close))
  end
  else let
    val e = mtoken_end(d, q, b)
  in
    @(q, e, e)
  end
end

fun math_is_over_at(d: !Doc, p: int, b: int): bool =
  ieq(doc_byte(d, p), MATH_BACKSLASH) andalso ieq(scan_alpha_end(d, iadd(p, 1), b), iadd(p, 5))
    andalso ieq(doc_byte(d, iadd(p, 1)), 111) andalso ieq(doc_byte(d, iadd(p, 2)), 118)
    andalso ieq(doc_byte(d, iadd(p, 3)), 101) andalso ieq(doc_byte(d, iadd(p, 4)), 114)

fun find_over_with_fuel {n:nat} .<n>. (fuel: int(n), d: !Doc, p: int, b: int, depth: int): int =
  if recursion_fuel_available(fuel) then (
    if ige(p, b) then ~1
    else let
      val ch = doc_byte(d, p)
    in
      if ieq(ch, CHAR_LBRACE) then find_over_with_fuel(fuel - 1, d, iadd(p, 1), b, iadd(depth, 1))
      else if ieq(ch, 125) then find_over_with_fuel(fuel - 1, d, iadd(p, 1), b, isub(depth, 1))
      else if ieq(depth, 0) andalso math_is_over_at(d, p, b) then p
      else find_over_with_fuel(fuel - 1, d, iadd(p, 1), b, depth)
    end
  ) else ~1

fun find_over(d: !Doc, a: int, b: int): int =
  find_over_with_fuel(airlock_nat(MAX_REC_FUEL), d, a, b, 0)

(* ---- Çizgiler ---- *)

fun mline_rows {n:nat} .<n>. (
  left: int(n), r: !Rend, x0: int, y0: int, dx: int, dy: int, i: int, th: int, col: uint
): void =
  if left = 0 then () else let
    val xx = iadd(x0, idiv(imul(dx, i), imax(1, dy)))
    val () = rend_rect(r, xx, iadd(y0, i), th, 1, col)
  in
    mline_rows(left - 1, r, x0, y0, dx, dy, iadd(i, 1), th, col)
  end

fun mstroke(r: !Rend, x0: int, y0: int, x1: int, y1: int, th: int): void = let
  val up = ilt(y1, y0)
  val ya = if up then y1 else y0
  val xa = if up then x1 else x0
  val yb = if up then y0 else y1
  val xb = if up then x0 else x1
  val dy = imax(1, isub(yb, ya))
in
  mline_rows(airlock_nat(dy), r, xa, ya, isub(xb, xa), dy, 0, th, col_math())
end

fun find_bracket_close_with_fuel {n:nat} .<n>. (fuel: int(n), d: !Doc, p: int, b: int): int =
  if recursion_fuel_available(fuel) then (
    if ige(p, b) then b
    else if ieq(doc_byte(d, p), MATH_RBRACKET) then p
    else find_bracket_close_with_fuel(fuel - 1, d, iadd(p, 1), b)
  ) else b

fun find_bracket_close(d: !Doc, p: int, b: int): int =
  find_bracket_close_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, b)

(* ---- Üst/alt simge tarama ve yerleştirme ---- *)

fun mscr_empty(q: int): MScr = @{us=(~1), ue=(~1), ds=(~1), de=(~1), nx=q}

fun mscr_take(d: !Doc, b: int, sc: MScr): MScr = let
  val q = math_skip_sp(d, sc.nx, b)
in
  if ige(q, b) then sc
  else let
    val ch = doc_byte(d, q)
  in
    if ieq(ch, MATH_CARET) andalso ilt(sc.us, 0) then let
      val @(s, e, nx) = moperand(d, iadd(q, 1), b)
    in
      @{us=s, ue=e, ds=sc.ds, de=sc.de, nx=nx}
    end
    else if ieq(ch, MATH_UNDERSCORE) andalso ilt(sc.ds, 0) then let
      val @(s, e, nx) = moperand(d, iadd(q, 1), b)
    in
      @{us=sc.us, ue=sc.ue, ds=s, de=e, nx=nx}
    end
    else sc
  end
end

fun mscr_scan(d: !Doc, b: int, q: int): MScr =
  mscr_take(d, b, mscr_take(d, b, mscr_empty(q)))

fun mscr_place(c: MCtx, bi: MItem, sc: MScr, sup: MBox, sub: MBox): MPlace = let
  val lh = mpx(c, c.lh)
  val gap = iadd(idiv(lh, 10), 1)
  val has_u = ige(sc.us, 0)
  val has_v = ige(sc.ds, 0)
in
  if ieq(bi.k, 1) andalso ieq(c.disp, 1) then let
    val w = imax(bi.w, imax(sup.w, sub.w))
    val uy = isub(isub(c.y, bi.a), iadd(gap, sup.d))
    val vy = iadd(iadd(c.y, bi.d), iadd(gap, sub.a))
    val a = if has_u then iadd(iadd(bi.a, gap), iadd(sup.a, sup.d)) else bi.a
    val dd = if has_v then iadd(iadd(bi.d, gap), iadd(sub.a, sub.d)) else bi.d
  in
    @{bx=iadd(c.x, idiv(isub(w, bi.w), 2)), ux=iadd(c.x, idiv(isub(w, sup.w), 2)), uy=uy,
      vx=iadd(c.x, idiv(isub(w, sub.w), 2)), vy=vy, w=w, a=a, d=dd}
  end else let
    val rise = imax(idiv(imul(lh, 2), 5), isub(bi.a, idiv(imul(lh, 3), 10)))
    val drop = imax(idiv(lh, 4), bi.d)
    val sx = iadd(c.x, bi.w)
    val a = if has_u then imax(bi.a, iadd(rise, sup.a)) else bi.a
    val dd = if has_v then imax(bi.d, iadd(drop, sub.d)) else bi.d
  in
    @{bx=c.x, ux=sx, uy=isub(c.y, rise), vx=sx, vy=iadd(c.y, drop),
      w=iadd(iadd(bi.w, imax(sup.w, sub.w)), 1), a=a, d=dd}
  end
end

(* ---- Eşzamanlı özyinelemeli yerleşim ---- *)

fun mcmd_code(cb: !Buf): int = let
  val s = buffer_c_string(cb)
in
  if ieq(c_strcmp(s, "frac"), 0) orelse ieq(c_strcmp(s, "dfrac"), 0) orelse ieq(c_strcmp(s, "tfrac"), 0) then 1
  else if ieq(c_strcmp(s, "sqrt"), 0) then 2
  else if ieq(c_strcmp(s, "bar"), 0) orelse ieq(c_strcmp(s, "overline"), 0) then 3
  else if ieq(c_strcmp(s, "hat"), 0) then 4
  else if ieq(c_strcmp(s, "vec"), 0) then 5
  else if ieq(c_strcmp(s, "tilde"), 0) then 6
  else if ieq(c_strcmp(s, "left"), 0) orelse ieq(c_strcmp(s, "right"), 0) then 7
  else if ieq(c_strcmp(s, "text"), 0) orelse ieq(c_strcmp(s, "mathrm"), 0) orelse ieq(c_strcmp(s, "mathbf"), 0)
    orelse ieq(c_strcmp(s, "mathit"), 0) orelse ieq(c_strcmp(s, "operatorname"), 0)
    orelse ieq(c_strcmp(s, "mathbb"), 0) orelse ieq(c_strcmp(s, "mathcal"), 0) then 8
  else if ieq(c_strcmp(s, "sum"), 0) orelse ieq(c_strcmp(s, "prod"), 0) orelse ieq(c_strcmp(s, "lim"), 0) then 9
  else if ieq(c_strcmp(s, "int"), 0) orelse ieq(c_strcmp(s, "oint"), 0) then 10
  else if ieq(c_strcmp(s, "over"), 0) then 11
  else 0
end

(* Gömülü mono yazı tiplerinde büyük Yunan Sigma/Pi yok; n-ary karşılıklarına düşülür. *)
fun math_font_safe(sym: string): string =
  if ieq(c_strcmp(sym, "Σ"), 0) then "∑"
  else if ieq(c_strcmp(sym, "Π"), 0) then "∏"
  else sym

fun msymbol(f: !Font, r: !Rend, d: !Doc, p: int, b: int, c: MCtx, paint: Toggle): MItem =
  if ige(iadd(p, 1), b) then mitem_zero(b)
  else let
    val ch = doc_byte(d, iadd(p, 1))
    val e = imin(b, doc_advance_cps(d, iadd(p, 1), b, 1))
  in
    if ieq(ch, 44) then mitem_of(e, mbox_make(mpx(c, idiv(c.lh, 6)), 0, 0), 0)
    else if ieq(ch, 59) orelse ieq(ch, 58) then mitem_of(e, mbox_make(mpx(c, idiv(c.lh, 4)), 0, 0), 0)
    else if ieq(ch, 32) then mitem_of(e, mbox_make(mpx(c, idiv(c.lh, 3)), 0, 0), 0)
    else if ieq(ch, 33) orelse ieq(ch, MATH_BACKSLASH) then mitem_zero(e)
    else mitem_of(e, matom_doc(f, r, d, iadd(p, 1), e, c, paint), 0)
  end

fun mrule(r: !Rend, x: int, y: int, w: int, h: int): void =
  if igt(w, 0) then rend_rect(r, x, y, w, h, col_math()) else ()

fun mrow {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, a: int, b: int, c: MCtx, paint: Toggle
): MBox =
  if recursion_fuel_available(fuel) then (
    if igt(c.lvl, MATH_MAX_LEVEL) then mraw_doc(f, r, d, a, b, c, paint)
    else let
      val ov = find_over(d, a, b)
    in
      if ige(ov, 0) then mfrac(fuel - 1, f, r, d, a, ov, iadd(ov, 5), b, c, paint)
      else mseq(fuel - 1, f, r, d, a, b, c, paint, 0, 0, 0)
    end
  ) else mbox_make(0, 0, 0)

and mseq {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, p: int, b: int, c: MCtx, paint: Toggle, w: int, a: int, dd: int
): MBox =
  if recursion_fuel_available(fuel) then (
    let
      val q = math_skip_sp(d, p, b)
    in
      if ige(q, b) then mbox_make(w, a, dd)
      else let
        val it = mitem(fuel - 1, f, r, d, q, b, mctx_at(c, iadd(c.x, w), c.y), paint)
        val ne = imax(it.e, iadd(q, 1))
      in
        mseq(fuel - 1, f, r, d, ne, b, c, paint, iadd(w, it.w), imax(a, it.a), imax(dd, it.d))
      end
    end
  ) else mbox_make(w, a, dd)

and mfrac {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, ns: int, ne: int, ds: int, de: int, c: MCtx, paint: Toggle
): MBox =
  if recursion_fuel_available(fuel) then let
    val cn = if ieq(c.disp, 1) then mctx_sub(c, 1, 1, 0, 0) else mctx_sub(c, 7, 10, 0, 0)
    val nb = mrow(fuel - 1, f, r, d, ns, ne, cn, Off)
    val db = mrow(fuel - 1, f, r, d, ds, de, cn, Off)
    val t = imax(1, idiv(mpx(c, c.lh), 14))
    val gap = iadd(mpx(c, idiv(c.lh, 10)), 1)
    val axis = mpx(c, idiv(imul(c.lh, 3), 10))
    val fw = iadd(imax(nb.w, db.w), imul(mpx(c, 3), 2))
    val rule_y = isub(c.y, iadd(axis, idiv(t, 2)))
    val ny = isub(isub(rule_y, gap), nb.d)
    val dy = iadd(iadd(iadd(rule_y, t), gap), db.a)
    val () = if is_on(paint) then let
        val () = mrule(r, c.x, rule_y, fw, t)
        val _n = mrow(fuel - 1, f, r, d, ns, ne, mctx_at(cn, iadd(c.x, idiv(isub(fw, nb.w), 2)), ny), On)
        val _d = mrow(fuel - 1, f, r, d, ds, de, mctx_at(cn, iadd(c.x, idiv(isub(fw, db.w), 2)), dy), On)
      in
      end else ()
    val up = isub(c.y, ny)
    val dn = isub(iadd(dy, db.d), c.y)
  in
    mbox_make(fw, iadd(up, nb.a), imax(0, dn))
  end else mbox_make(0, 0, 0)

and msqrt {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, s: int, e: int, c: MCtx, paint: Toggle
): MBox =
  if recursion_fuel_available(fuel) then let
    val cb = mctx_sub(c, 1, 1, 0, 0)
    val body = mrow(fuel - 1, f, r, d, s, e, cb, Off)
    val t = imax(1, idiv(mpx(c, c.lh), 14))
    val gap = iadd(t, mpx(c, 2))
    val h = iadd(iadd(body.a, body.d), iadd(gap, t))
    val rw = imax(mpx(c, idiv(c.lh, 2)), idiv(h, 3))
    val ytop = isub(c.y, iadd(iadd(body.a, gap), t))
    val ybot = iadd(c.y, body.d)
    val ymid = iadd(ytop, idiv(imul(isub(ybot, ytop), 55), 100))
    val xk = iadd(c.x, idiv(imul(rw, 3), 10))
    val () = if is_on(paint) then let
        val () = mstroke(r, c.x, ymid, xk, ybot, t)
        val () = mstroke(r, xk, ybot, iadd(c.x, rw), ytop, iadd(t, 1))
        val () = mrule(r, iadd(c.x, rw), ytop, iadd(body.w, 2), t)
        val _b = mrow(fuel - 1, f, r, d, s, e, mctx_at(cb, iadd(iadd(c.x, rw), 1), c.y), On)
      in
      end else ()
  in
    mbox_make(iadd(iadd(rw, body.w), 2), iadd(iadd(body.a, gap), t), body.d)
  end else mbox_make(0, 0, 0)

and maccent {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, code: int, s: int, e: int, c: MCtx, paint: Toggle
): MBox =
  if recursion_fuel_available(fuel) then let
    val cb = mctx_sub(c, 1, 1, c.x, c.y)
    val body = mrow(fuel - 1, f, r, d, s, e, cb, paint)
    val t = imax(1, idiv(mpx(c, c.lh), 14))
    val ytop = isub(c.y, iadd(body.a, mpx(c, 2)))
    val () = if is_on(paint) then (
      if ieq(code, 3) then mrule(r, c.x, ytop, body.w, t)
      else let
        val s_acc = if ieq(code, 4) then "^" else if ieq(code, 5) then "→" else "~"
        val ca = mctx_sub(c, 7, 10, c.x, iadd(isub(c.y, body.a), mpx(c, idiv(imul(c.asc, 6), 10))))
        val aw = matom_str(f, r, s_acc, ca, Off)
        val _a = matom_str(f, r, s_acc, mctx_at(ca, iadd(c.x, idiv(isub(body.w, aw.w), 2)), ca.y), On)
      in
      end
    ) else ()
  in
    mbox_make(body.w, iadd(body.a, iadd(t, mpx(c, 3))), body.d)
  end else mbox_make(0, 0, 0)

and mnamed {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, ns: int, ce: int, b: int, c: MCtx, paint: Toggle
): MItem =
  if recursion_fuel_available(fuel) then let
    var cb = buf_make(MATH_NAME_BUFFER_BYTES)
    val clen = doc_slice_buf(d, ns, ce, cb, 31)
    val () = buf_set_len(cb, clen)
    val code = mcmd_code(cb)
    val sym = math_cmd_lookup(buffer_c_string(cb))
    val res = mnamed_code(fuel - 1, f, r, d, code, sym, buffer_c_string(cb), ce, b, c, paint)
    val () = buf_free(cb)
  in
    res
  end else mitem_zero(ce)

and mnamed_code {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, code: int, sym: string, name: string, ce: int, b: int, c: MCtx, paint: Toggle
): MItem =
  if recursion_fuel_available(fuel) then (
    if ieq(code, 1) then mcmd_frac(fuel - 1, f, r, d, ce, b, c, paint)
    else if ieq(code, 2) then mcmd_sqrt(fuel - 1, f, r, d, ce, b, c, paint)
    else if ige(code, 3) andalso ile(code, 6) then mcmd_accent(fuel - 1, f, r, d, code, ce, b, c, paint)
    else if ieq(code, 7) then mcmd_delim(fuel - 1, f, r, d, ce, b, c, paint)
    else if ieq(code, 8) then mcmd_group(fuel - 1, f, r, d, ce, b, c, paint)
    else if ieq(code, 11) then mitem_zero(ce)
    else if ige(code, 9) then let
      val cs = if ieq(c.disp, 1) then mctx_sub(c, 5, 4, c.x, c.y) else c
      val bx = if ieq(code, 9) andalso ieq(c_strcmp(name, "lim"), 0) then matom_str(f, r, name, c, paint)
        else matom_str(f, r, sym, cs, paint)
    in
      mitem_of(ce, bx, (if ieq(code, 9) then 1 else 2))
    end
    else if igt(c_strlen(sym), 0) then mitem_of(ce, matom_str(f, r, math_font_safe(sym), c, paint), 0)
    else mitem_of(ce, matom_str(f, r, name, c, paint), 0)
  ) else mitem_zero(ce)

and mcmd_frac {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, p: int, b: int, c: MCtx, paint: Toggle
): MItem =
  if recursion_fuel_available(fuel) then let
    val @(ns, ne, p1) = moperand(d, p, b)
    val @(ds, de, p2) = moperand(d, p1, b)
  in
    mitem_of(p2, mfrac(fuel - 1, f, r, d, ns, ne, ds, de, c, paint), 0)
  end else mitem_zero(p)

and mcmd_sqrt {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, p: int, b: int, c: MCtx, paint: Toggle
): MItem =
  if recursion_fuel_available(fuel) then let
    val q = math_skip_sp(d, p, b)
    val q2 = if ilt(q, b) andalso ieq(doc_byte(d, q), MATH_LBRACKET) then iadd(find_bracket_close(d, q, b), 1) else p
    val @(s, e, nx) = moperand(d, q2, b)
  in
    mitem_of(nx, msqrt(fuel - 1, f, r, d, s, e, c, paint), 0)
  end else mitem_zero(p)

and mcmd_accent {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, code: int, p: int, b: int, c: MCtx, paint: Toggle
): MItem =
  if recursion_fuel_available(fuel) then let
    val @(s, e, nx) = moperand(d, p, b)
  in
    mitem_of(nx, maccent(fuel - 1, f, r, d, code, s, e, c, paint), 0)
  end else mitem_zero(p)

and mcmd_group {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, p: int, b: int, c: MCtx, paint: Toggle
): MItem =
  if recursion_fuel_available(fuel) then let
    val @(s, e, nx) = moperand(d, p, b)
  in
    mitem_of(nx, mrow(fuel - 1, f, r, d, s, e, mctx_sub(c, 1, 1, c.x, c.y), paint), 0)
  end else mitem_zero(p)

and mcmd_delim {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, p: int, b: int, c: MCtx, paint: Toggle
): MItem =
  if recursion_fuel_available(fuel) then let
    val q = math_skip_sp(d, p, b)
  in
    if ige(q, b) then mitem_zero(b)
    else if ieq(doc_byte(d, q), MATH_DOT) then mitem_zero(iadd(q, 1))
    else mbase(fuel - 1, f, r, d, q, b, c, paint)
  end else mitem_zero(p)

and mbase {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, p: int, b: int, c: MCtx, paint: Toggle
): MItem =
  if recursion_fuel_available(fuel) then let
    val ch = doc_byte(d, p)
  in
    if ieq(ch, MATH_BACKSLASH) then mcmd(fuel - 1, f, r, d, p, b, c, paint)
    else if ieq(ch, CHAR_LBRACE) then mcmd_group(fuel - 1, f, r, d, p, b, c, paint)
    else if ieq(ch, MATH_CARET) orelse ieq(ch, MATH_UNDERSCORE) then mitem_zero(iadd(p, 1))
    else let
      val e = imin(b, doc_advance_cps(d, p, b, 1))
    in
      mitem_of(e, matom_doc(f, r, d, p, e, c, paint), 0)
    end
  end else mitem_zero(iadd(p, 1))

and mcmd {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, p: int, b: int, c: MCtx, paint: Toggle
): MItem =
  if recursion_fuel_available(fuel) then let
    val ns = iadd(p, 1)
    val ce = scan_alpha_end(d, ns, b)
  in
    if igt(ce, ns) then mnamed(fuel - 1, f, r, d, ns, ce, b, c, paint)
    else msymbol(f, r, d, p, b, c, paint)
  end else mitem_zero(iadd(p, 1))

and mitem {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, p: int, b: int, c: MCtx, paint: Toggle
): MItem =
  if recursion_fuel_available(fuel) then let
    val bi = mbase(fuel - 1, f, r, d, p, b, c, Off)
    val sc = mscr_scan(d, b, bi.e)
    val has = ige(sc.us, 0) orelse ige(sc.ds, 0)
  in
    if has then mitem_scripted(fuel - 1, f, r, d, p, b, c, paint, bi, sc)
    else if is_on(paint) then mbase(fuel - 1, f, r, d, p, b, c, On)
    else bi
  end else mitem_zero(iadd(p, 1))

and mitem_scripted {n:nat} .<n>. (
  fuel: int(n), f: !Font, r: !Rend, d: !Doc, p: int, b: int, c: MCtx, paint: Toggle, bi: MItem, sc: MScr
): MItem =
  if recursion_fuel_available(fuel) then let
    val cs = mctx_sub(c, 7, 10, 0, 0)
    val sup = if ige(sc.us, 0) then mrow(fuel - 1, f, r, d, sc.us, sc.ue, cs, Off) else mbox_make(0, 0, 0)
    val sub = if ige(sc.ds, 0) then mrow(fuel - 1, f, r, d, sc.ds, sc.de, cs, Off) else mbox_make(0, 0, 0)
    val pl = mscr_place(c, bi, sc, sup, sub)
    val () = if is_on(paint) then let
        val _b = mbase(fuel - 1, f, r, d, p, b, mctx_at(c, pl.bx, c.y), On)
        val _u = if ige(sc.us, 0) then mrow(fuel - 1, f, r, d, sc.us, sc.ue, mctx_at(cs, pl.ux, pl.uy), On) else mbox_make(0, 0, 0)
        val _v = if ige(sc.ds, 0) then mrow(fuel - 1, f, r, d, sc.ds, sc.de, mctx_at(cs, pl.vx, pl.vy), On) else mbox_make(0, 0, 0)
      in
      end else ()
  in
    @{e=sc.nx, w=pl.w, a=pl.a, d=pl.d, k=0}
  end else mitem_zero(iadd(p, 1))

(* ---- Girişler ---- *)

fun mctx_root(f: !Font, disp: int, x: int, y: int): MCtx =
  @{sn=1, sd=1, x=x, y=y, lh=font_line_h(f), asc=font_asc(f), disp=disp, lvl=0}

fun math_layout_measure(f: !Font, r: !Rend, d: !Doc, st: int, en: int, disp: int): MBox =
  mrow(airlock_nat(MAX_REC_FUEL), f, r, d, st, en, mctx_root(f, disp, 0, 0), Off)

fun math_layout_paint(f: !Font, r: !Rend, d: !Doc, st: int, en: int, disp: int, x: int, base: int): void = let
  val _bx = mrow(airlock_nat(MAX_REC_FUEL), f, r, d, st, en, mctx_root(f, disp, x, base), On)
in
end

fun mathb_slice_bounds(d: !Doc, i: int): @(int, int) = let
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val st = (if ilt(iadd(a, 2), b) andalso ieq(doc_byte(d, a), CHAR_DOLLAR) andalso ieq(doc_byte(d, iadd(a, 1)), CHAR_DOLLAR) then iadd(a, 2) else a)
  val en = (if igt(isub(b, 2), st) andalso ieq(doc_byte(d, isub(b, 1)), CHAR_DOLLAR) andalso ieq(doc_byte(d, isub(b, 2)), CHAR_DOLLAR) then isub(b, 2) else b)
in
  @(st, en)
end
