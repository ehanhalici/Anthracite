#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "airlock.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "ui_workspace/ui_common.sats"

implement touchb(b) = ()
implement bclear(b) = buf_set_len(b, 0)
implement bpush(b, v) = buf_push(b, v)

implement push_if(b, go, v) =
  if is_on(go) then buf_push(b, v) else touchb(b)

fun bappend_loop {rem:nat} .<rem>. (b: &Buf >> Buf, s: string, rem: int(rem), i: int): void =
  if rem > 0 then let
    val () = buf_push(b, c_str_byte(s, i))
  in
    bappend_loop(b, s, rem - 1, iadd(i, 1))
  end else touchb(b)

implement bappend(b, s, i, n) =
  if ige(i, n) then touchb(b)
  else bappend_loop(b, s, airlock_span(i, n), i)

implement bstr(b, s) = bappend(b, s, 0, c_strlen(s))

implement bstr_if(b, go, s) =
  if is_on(go) then bstr(b, s) else touchb(b)

fun bcat_loop {rem:nat} .<rem>. (dst: &Buf >> Buf, src: !Buf, rem: int(rem), i: int): void =
  if rem > 0 then let
    val () = buf_push(dst, buf_get(src, i))
  in
    bcat_loop(dst, src, rem - 1, iadd(i, 1))
  end else touchb(dst)

implement bcat(dst, src, i, n) =
  if ige(i, n) then touchb(dst)
  else bcat_loop(dst, src, airlock_span(i, n), i)

implement bcat_all(dst, src) = let
  val n = buf_len(src)
in
  bcat(dst, src, 0, n)
end

fun digits_sub {v:nat} .<v>. (b: &Buf >> Buf, v: int(v)): void =
  if v > 0 then let
    val () = digits_sub(b, v / 10)
  in
    bpush(b, iadd(CHAR_ZERO, imod(v, 10)))
  end else touchb(b)

implement b_app_int(b, n0) = let
  val n = if ilt(n0, 0) then let val () = bpush(b, CHAR_MINUS) in isub(0, n0) end else n0
in
  if ieq(n, 0) then bpush(b, CHAR_ZERO)
  else if ige(n, 0) then digits_sub(b, airlock_nat(n))
  else touchb(b)
end

implement bcat_if(dst, src, i, n, go) =
  if is_on(go) then bcat(dst, src, i, n) else touchb(dst)

fun beq_loop {rem:nat} .<rem>. (a: !Buf, b: !Buf, rem: int(rem), i: int): int =
  if rem > 0 then
    (if ine(buf_get(a, i), buf_get(b, i)) then 0 else beq_loop(a, b, rem - 1, iadd(i, 1)))
  else 1

implement beq(a, b, i) =
  if ine(buf_len(a), buf_len(b)) then 0
  else if ige(i, buf_len(a)) then 1
  else beq_loop(a, b, airlock_span(i, buf_len(a)), i)

implement bcopy(src) = let
  var d = buf_make(iadd(buf_len(src), 1))
  val n = buf_len(src)
  val () = bcat(d, src, 0, n)
in
  d
end

implement cstr(b) = let
  val n = buf_len(b)
  val () = buf_set(b, n, 0)
in
  buf_cstr(b)
end

fun ends_loop {rem:nat} .<rem>. (b: !Buf, s: string, n: int, m: int, rem: int(rem), i: int): bool =
  if rem > 0 then
    (if ine(buf_get(b, iadd(isub(n, m), i)), c_str_byte(s, i)) then false
     else ends_loop(b, s, n, m, rem - 1, iadd(i, 1)))
  else true

fun ends_at(b: !Buf, s: string, n: int, m: int, i: int): bool =
  if ige(i, m) then true
  else ends_loop(b, s, n, m, airlock_span(i, m), i)

implement ends(b, s) = let
  val n = buf_len(b)
  val m = c_strlen(s)
in
  if ilt(n, m) then false else ends_at(b, s, n, m, 0)
end

implement draw_s(f, r, x, y, s, c) =
  seen_int(font_draw(f, r, x, y, c_str_ptr(s), c_strlen(s), c))

implement join2(a, b) = let
  var d = buf_make(iadd(iadd(buf_len(a), buf_len(b)), 2))
  val na = buf_len(a)
  val slash = igt(na, 0) andalso ine(buf_get(a, isub(na, 1)), CHAR_SLASH)
  val () = bcat(d, a, 0, na)
  val () = push_if(d, toggle_of(slash), CHAR_SLASH)
  val () = bcat(d, b, 0, buf_len(b))
in
  d
end

fun last_slash_loop {rem:nat} .<rem>. (path: !Buf, rem: int(rem), i: int, a: int): int =
  if rem > 0 then
    last_slash_loop(path, rem - 1, iadd(i, 1), (if ieq(buf_get(path, i), CHAR_SLASH) then iadd(i, 1) else a))
  else a

implement last_slash(path, i, a) =
  if ige(i, buf_len(path)) then a
  else last_slash_loop(path, airlock_span(i, buf_len(path)), i, a)

implement base_name(path, dst) = let
  val a = last_slash(path, 0, 0)
  val () = bclear(dst)
in
  bcat(dst, path, a, buf_len(path))
end

fun slash_loop {rem:nat} .<rem>. (path: !Buf, rem: int(rem), i: int, a: int): int =
  if rem > 0 then
    slash_loop(path, rem - 1, iadd(i, 1), (if ieq(buf_get(path, i), CHAR_SLASH) then i else a))
  else a

fun slash_at(path: !Buf, i: int, a: int): int =
  if ige(i, buf_len(path)) then a
  else slash_loop(path, airlock_span(i, buf_len(path)), i, a)

implement dirname_of(path, dst) = let
  val sl = slash_at(path, 0, ~1)
  val () = bclear(dst)
in
  bcat_if(dst, path, 0, sl, toggle_of(ige(sl, 0)))
end

implement child_path(dir, name, dst) = let
  val () = bclear(dst)
  val () = bcat(dst, dir, 0, buf_len(dir))
  val nd = buf_len(dir)
  val need_slash = igt(nd, 0) andalso ine(buf_get(dir, isub(nd, 1)), CHAR_SLASH)
  val () = if need_slash then buf_push(dst, CHAR_SLASH) else ()
in
  bcat(dst, name, 0, buf_len(name))
end

implement row_path(text, meta, row, dst) = let
  val off = buf_get32(meta, iadd(imul(row, 4), 2))
  val n = buf_get32(meta, iadd(imul(row, 4), 3))
  val () = bclear(dst)
in
  bcat(dst, text, off, iadd(off, n))
end

fun has_dot_loop {rem:nat} .<rem>. (b: !Buf, rem: int(rem), i: int): bool =
  if rem > 0 then
    (if ieq(buf_get(b, i), CHAR_DOT) then true else has_dot_loop(b, rem - 1, iadd(i, 1)))
  else false

implement has_dot_char(b, i) =
  if ige(i, buf_len(b)) then false
  else has_dot_loop(b, airlock_span(i, buf_len(b)), i)

implement uok(t) = anth_u2i(t)

fun has_esc_loop {rem:nat} .<rem>. (b: !Buf, rem: int(rem), i: int): bool =
  if rem > 0 then
    (if ieq(buf_get(b, i), CHAR_ESC) then true else has_esc_loop(b, rem - 1, iadd(i, 1)))
  else false

fun has_esc_byte(b: !Buf, n: int, i: int): bool =
  if ige(i, n) then false
  else has_esc_loop(b, airlock_span(i, n), i)

fun compact_loop {rem:nat} .<rem>. (b: !Buf, n: int, rem: int(rem), r: int, w: int): int =
  if rem > 0 then let
    val byte = buf_get(b, r)
    val keep = (ige(byte, CHAR_SPACE) andalso ine(byte, CHAR_DEL)) orelse ieq(byte, CHAR_TAB) orelse ieq(byte, CHAR_LF)
  in
    if keep then let
      val () = buf_set(b, w, byte)
    in
      compact_loop(b, n, rem - 1, iadd(r, 1), iadd(w, 1))
    end else compact_loop(b, n, rem - 1, iadd(r, 1), w)
  end
  else w

fun compact_bytes(b: !Buf, n: int, r: int, w: int): int =
  if ige(r, n) then w
  else compact_loop(b, n, airlock_span(r, n), r, w)

implement filter_text(b, n) =
  if has_esc_byte(b, n, 0) then 0
  else compact_bytes(b, n, 0, 0)

implement scan_skip(name) =
  ieq(buf_len(name), 0) orelse ieq(buf_get(name, 0), CHAR_DOT)

implement meta_dir(meta, row) =
  dir_mark_of(buf_get32(meta, iadd(imul(row, 4), 1)))

implement path_is_dir(path) = ieq(fs_isdir(path), 1)

implement child_kind(child, skip, isdir) =
  if is_on(skip) then DirNo
  else if is_dir_mark(isdir, DirYes) then DirYes
  else if is_dir_mark(isdir, DirNo) then DirNo
  else dir_mark_of(fs_isdir(cstr(child)))

implement is_side_none(x) = case+ x of
  | SideNone() => true
  | SideFiles() => false
  | SideSearch() => false
  | SideConfig() => false

implement is_side_files(x) = case+ x of
  | SideFiles() => true
  | SideNone() => false
  | SideSearch() => false
  | SideConfig() => false

implement is_side_search(x) = case+ x of
  | SideSearch() => true
  | SideNone() => false
  | SideFiles() => false
  | SideConfig() => false

implement is_side_config(x) = case+ x of
  | SideConfig() => true
  | SideNone() => false
  | SideFiles() => false
  | SideSearch() => false

implement is_menu_none(x) = case+ x of
  | MenuNone() => true
  | MenuText() => false
  | MenuImage() => false
  | MenuFileTree() => false

implement is_menu_text(x) = case+ x of
  | MenuText() => true
  | MenuNone() => false
  | MenuImage() => false
  | MenuFileTree() => false

implement is_menu_image(x) = case+ x of
  | MenuImage() => true
  | MenuNone() => false
  | MenuText() => false
  | MenuFileTree() => false

implement is_menu_filetree(x) = case+ x of
  | MenuFileTree() => true
  | MenuNone() => false
  | MenuText() => false
  | MenuImage() => false

implement is_prompt_none(x) = case+ x of
  | PromptNone() => true
  | PromptNewFile() => false
  | PromptNewFolder() => false
  | PromptRename() => false

implement is_prompt_newfile(x) = case+ x of
  | PromptNewFile() => true
  | PromptNone() => false
  | PromptNewFolder() => false
  | PromptRename() => false

implement is_prompt_newfolder(x) = case+ x of
  | PromptNewFolder() => true
  | PromptNone() => false
  | PromptNewFile() => false
  | PromptRename() => false

implement is_prompt_rename(x) = case+ x of
  | PromptRename() => true
  | PromptNone() => false
  | PromptNewFile() => false
  | PromptNewFolder() => false

implement is_view_edit(x) = case+ x of
  | ViewEdit() => true
  | ViewRead() => false

implement is_view_read(x) = case+ x of
  | ViewRead() => true
  | ViewEdit() => false

implement is_edit_none(x) = case+ x of
  | EditNone() => true
  | EditChanged() => false
  | EditSubmit() => false
  | EditCancel() => false

implement is_edit_changed(x) = case+ x of
  | EditChanged() => true
  | EditNone() => false
  | EditSubmit() => false
  | EditCancel() => false

implement is_edit_submit(x) = case+ x of
  | EditSubmit() => true
  | EditNone() => false
  | EditChanged() => false
  | EditCancel() => false

implement is_edit_cancel(x) = case+ x of
  | EditCancel() => true
  | EditNone() => false
  | EditChanged() => false
  | EditSubmit() => false

implement is_drag_none(x) = case+ x of
  | DragNone() => true
  | DragTab() => false
  | DragFile() => false

implement is_drag_tab(x) = case+ x of
  | DragTab() => true
  | DragNone() => false
  | DragFile() => false

implement is_drag_file(x) = case+ x of
  | DragFile() => true
  | DragNone() => false
  | DragTab() => false

implement view_mode_code(v) = case+ v of
  | ViewEdit() => 0
  | ViewRead() => 1

implement view_mode_of_code(n) = if ieq(n, 1) then ViewRead else ViewEdit
